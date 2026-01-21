# wfsl-shell-guard.ps1
# WFSL PowerShell Guard Standard (WFSL-PSG-1.0) compliant: single JSON object on stdout, no human language on stdout.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Force UTF-8 stdout (no BOM). Adapters still normalise, but we prefer clean emission.
try {
  $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
  [Console]::OutputEncoding = $utf8NoBom
} catch {
  # If this fails, we still enforce single JSON object output below.
}

function Get-Sha256Hex {
  param(
    [Parameter(Mandatory = $true)]
    [string] $Text
  )
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($Text)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  try {
    $hash = $sha.ComputeHash($bytes)
    return ($hash | ForEach-Object { $_.ToString("x2") }) -join ""
  } finally {
    $sha.Dispose()
  }
}

function DeepSort {
  param([Parameter(Mandatory = $true)] $Value)

  if ($null -eq $Value) { return $null }

  if ($Value -is [System.Collections.IDictionary]) {
    $out = [ordered]@{}
    foreach ($k in ($Value.Keys | Sort-Object)) {
      $out[$k] = DeepSort -Value $Value[$k]
    }
    return $out
  }

  if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
    $arr = @()
    foreach ($item in $Value) { $arr += (DeepSort -Value $item) }
    return $arr
  }

  return $Value
}

function StableJson {
  param([Parameter(Mandatory = $true)] $Object)
  # ConvertTo-Json ordering is not guaranteed. We pre-sort dictionaries.
  $sorted = DeepSort -Value $Object
  return ($sorted | ConvertTo-Json -Depth 50 -Compress)
}

function Emit-JsonAndExit {
  param(
    [Parameter(Mandatory = $true)]
    [hashtable] $Evidence,
    [Parameter(Mandatory = $true)]
    [int] $ExitCode
  )

  # PSG: evidence must not be empty.
  if ($null -eq $Evidence -or $Evidence.Keys.Count -eq 0) {
    $Evidence = @{
      error = @{
        schema_version = "wfsl-error.v1"
        error_class    = "WFSL_SHELL_GUARD_FAILURE"
        message        = "Evidence object empty"
        timestamp_utc  = (Get-Date).ToUniversalTime().ToString("o")
      }
    }
    $ExitCode = 1
  }

  $json = StableJson -Object $Evidence
  # PSG: exactly one JSON object on stdout, nothing else.
  [Console]::Out.Write($json)
  exit $ExitCode
}

param(
  # Input text to evaluate. Guard logic may deny human language or non-structured payloads.
  [Parameter(Mandatory = $false)]
  [string] $InputText = "",

  # Optional: strict mode. When set, empty input is denied.
  [Parameter(Mandatory = $false)]
  [switch] $Strict
)

try {
  $now = (Get-Date).ToUniversalTime().ToString("o")

  # Deterministic input hash. Empty string is allowed unless -Strict.
  $input = $InputText
  if ($Strict -and ([string]::IsNullOrWhiteSpace($input))) {
    $payload = @{
      verdict = "DENY"
      code    = "EMPTY_INPUT"
      input_sha256 = "sha256:" + (Get-Sha256Hex -Text "")
    }

    $evidence = @{
      schema_version = "wfsl-shell-guard.v1"
      timestamp_utc  = $now
      timestamp_trust = "system-clock"
      producer = @{
        system    = "wfsl-shell-guard"
        component = "guard"
        language  = "powershell"
      }
      payload = $payload
    }

    Emit-JsonAndExit -Evidence $evidence -ExitCode 2
  }

  $inputSha = "sha256:" + (Get-Sha256Hex -Text $input)

  # Guard rule: detect "human language" heuristically.
  # Deterministic, low-risk heuristic: alphabetic words and spaces above a threshold.
  $isHumanLanguage = $false
  if (-not [string]::IsNullOrWhiteSpace($input)) {
    $letters = ([regex]::Matches($input, "[A-Za-z]").Count)
    $spaces  = ([regex]::Matches($input, "\s").Count)
    $len = $input.Length

    # Simple ratio rule: if letters are significant and spaces exist, treat as human-language-like.
    if ($len -ge 12 -and $letters -ge 6 -and $spaces -ge 1) { $isHumanLanguage = $true }
  }

  if ($isHumanLanguage) {
    $payload = @{
      verdict     = "DENY"
      code        = "HUMAN_LANGUAGE_DETECTED"
      input_sha256 = $inputSha
    }

    $evidence = @{
      schema_version = "wfsl-shell-guard.v1"
      timestamp_utc  = $now
      timestamp_trust = "system-clock"
      producer = @{
        system    = "wfsl-shell-guard"
        component = "guard"
        language  = "powershell"
      }
      payload = $payload
    }

    Emit-JsonAndExit -Evidence $evidence -ExitCode 2
  }

  # Default allow (structured or non-human input).
  $payload = @{
    verdict     = "ALLOW"
    code        = "OK"
    input_sha256 = $inputSha
  }

  $evidence = @{
    schema_version = "wfsl-shell-guard.v1"
    timestamp_utc  = $now
    timestamp_trust = "system-clock"
    producer = @{
      system    = "wfsl-shell-guard"
      component = "guard"
      language  = "powershell"
    }
    payload = $payload
  }

  Emit-JsonAndExit -Evidence $evidence -ExitCode 0

} catch {
  $err = $_
  $evidence = @{
    error = @{
      schema_version = "wfsl-error.v1"
      error_class    = "WFSL_SHELL_GUARD_FAILURE"
      message        = ($err.Exception.Message)
      timestamp_utc  = (Get-Date).ToUniversalTime().ToString("o")
    }
  }
  Emit-JsonAndExit -Evidence $evidence -ExitCode 1
}
