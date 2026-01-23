# WFSL Shell Guard — ProofGate Repo Guard Converged
# ------------------------------------------------
# Purpose:
# - Deterministic, safe wrapper for git operations
# - Delegates ALL governance decisions to WFSL ProofGate Repo Guard
# - Blocks destructive operator error (git clean -fd, reset --hard)
# - Enforces lockfile, gitignore, and build artefact policy via Repo Guard
#
# Authoritative behaviour:
# - Shell Guard NEVER reimplements policy
# - ProofGate Repo Guard is the single source of truth
# - No partial execution, no side effects, no guesswork

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -----------------------
# Output helpers
# -----------------------
function Write-Info([string]$Message) { Write-Host $Message }
function Write-Warn([string]$Message) { Write-Warning $Message }
function Write-Fail([string]$Message, [int]$Code = 10) {
  Write-Error $Message
  exit $Code
}

# -----------------------
# Repo resolution
# -----------------------
function Resolve-GitRoot {
  try {
    $root = (& git rev-parse --show-toplevel 2>$null).Trim()
    if ($root) { return $root }
  } catch {}
  return $null
}

function Resolve-ManifestPath([string]$Manifest) {
  $gitRoot = Resolve-GitRoot
  if (-not $gitRoot) { return $null }

  if ($Manifest -and $Manifest.Trim().Length -gt 0) {
    if ([IO.Path]::IsPathRooted($Manifest)) { return $Manifest }
    return (Join-Path $gitRoot $Manifest)
  }

  $default = Join-Path $gitRoot "proofgate.manifest.json"
  if (Test-Path $default) { return $default }
  return $null
}

# -----------------------
# ProofGate resolution
# -----------------------
function Resolve-ProofGateEntry {
  param([Parameter(Mandatory=$true)][string]$GitRoot)

  # 1) Explicit environment override
  if ($env:WFSL_PROOFGATE_ENTRY -and (Test-Path $env:WFSL_PROOFGATE_ENTRY)) {
    return $env:WFSL_PROOFGATE_ENTRY
  }

  # 2) Local dependency
  $localDep = Join-Path $GitRoot "node_modules\wfsl-proofgate-cli\dist\index.js"
  if (Test-Path $localDep) { return $localDep }

  # 3) Sibling WFSL layout
  $parent = Split-Path -Parent $GitRoot
  if ($parent) {
    $sibling = Join-Path $parent "wfsl-proofgate-cli\dist\index.js"
    if (Test-Path $sibling) { return $sibling }
  }

  return $null
}

# -----------------------
# ProofGate invocation
# -----------------------
function Invoke-ProofGate {
  param(
    [Parameter(Mandatory=$true)][ValidateSet("status","verify")][string]$Action,
    [Parameter(Mandatory=$true)][string]$ManifestPath,
    [switch]$Strict,
    [switch]$Json
  )

  $gitRoot = Resolve-GitRoot
  if (-not $gitRoot) {
    Write-Fail "WFSL Shell Guard: not inside a git repository."
  }

  $entry = Resolve-ProofGateEntry -GitRoot $gitRoot
  if (-not $entry) {
    Write-Fail @"
WFSL Shell Guard: ProofGate entry not found.

Set:
  WFSL_PROOFGATE_ENTRY = absolute path to wfsl-proofgate-cli\dist\index.js

Example:
  `$env:WFSL_PROOFGATE_ENTRY = "C:\path\to\wfsl-proofgate-cli\dist\index.js"
"@
  }

  if (-not (Test-Path $ManifestPath)) {
    Write-Fail "WFSL Shell Guard: manifest not found at $ManifestPath" 40
  }

  $args = @($entry, $Action, "--manifest", $ManifestPath)
  if ($Strict) { $args += "--strict" }
  if ($Json)   { $args += "--json" }

  & node @args
  return $LASTEXITCODE
}

function Assert-RepoGuardStrict {
  param([Parameter(Mandatory=$true)][string]$ManifestPath)

  $code = Invoke-ProofGate -Action "status" -ManifestPath $ManifestPath -Strict -Json
  if ($code -ne 0) {
    Write-Fail "WFSL Shell Guard: Repo Guard verdict INVALID. Operation blocked." $code
  }
}

# -----------------------
# Safe clean (replacement for git clean -fd)
# -----------------------
function Invoke-WFSLSafeClean {
  param(
    [string]$Manifest = "",
    [switch]$Force,
    [switch]$DryRun
  )

  $gitRoot = Resolve-GitRoot
  if (-not $gitRoot) {
    Write-Fail "WFSL Shell Guard: not inside a git repository."
  }

  $manifestPath = Resolve-ManifestPath -Manifest $Manifest
  if ($manifestPath) {
    Assert-RepoGuardStrict -ManifestPath $manifestPath
  } else {
    Write-Warn "WFSL Shell Guard: no manifest found. Running in guarded mode without Repo Guard enforcement."
  }

  if (-not $DryRun -and -not $Force) {
    Write-Fail "WFSL Shell Guard: safe-clean requires -Force (or use -DryRun first)."
  }

  $args = @("clean")
  if ($DryRun) { $args += "-nd" } else { $args += "-fd" }

  # Always protect governance artefacts
  foreach ($e in @(".gitignore","proofgate.manifest.json","package.json","package-lock.json")) {
    $args += @("-e", $e)
  }

  Write-Info "WFSL Shell Guard: git $($args -join ' ')"
  & git @args
  exit $LASTEXITCODE
}

# -----------------------
# Guarded git proxy
# -----------------------
function Invoke-WFSLGit {
  param([Parameter(ValueFromRemainingArguments=$true)][string[]]$GitArgs)

  if (-not $GitArgs -or $GitArgs.Count -eq 0) {
    Write-Fail "WFSL Shell Guard: usage: wfsl-git <git args>"
  }

  $gitRoot = Resolve-GitRoot
  if (-not $gitRoot) {
    Write-Fail "WFSL Shell Guard: not inside a git repository."
  }

  $joined = ($GitArgs -join " ").Trim()

  # Hard block known dangerous patterns
  if ($joined -match '(^| )clean( |$)' -and $joined -match '(^| )-f' -and $joined -match '(^| )-d') {
    Write-Fail "WFSL Shell Guard: blocked 'git clean -fd'. Use: safe-clean -Force"
  }

  $manifestPath = Resolve-ManifestPath -Manifest ""
  if ($manifestPath) {
    if (
      ($joined -match '(^| )reset( |$)' -and $joined -match '--hard') -or
      ($joined -match '(^| )checkout( |$)' -and $joined -match '(^| )-f') -or
      ($joined -match '(^| )restore( |$)' -and $joined -match '--source') -or
      ($joined -match '(^| )clean( |$)')
    ) {
      Assert-RepoGuardStrict -ManifestPath $manifestPath
    }
  }

  & git @GitArgs
  exit $LASTEXITCODE
}

# -----------------------
# Help
# -----------------------
function Show-Help {
  Write-Info @"
WFSL Shell Guard — Repo Guard Converged

Commands:
  status        Run ProofGate Repo Guard status
  verify        Run ProofGate verify
  safe-clean    Safe replacement for 'git clean -fd'
  wfsl-git      Guarded git proxy
  help          Show this help

Environment:
  WFSL_PROOFGATE_ENTRY = path to wfsl-proofgate-cli\dist\index.js
"@
}

# -----------------------
# Router
# -----------------------
if ($args.Count -eq 0) { Show-Help; exit 0 }

$cmd  = ($args[0] ?? "").ToLowerInvariant()
$rest = @()
if ($args.Count -gt 1) { $rest = $args[1..($args.Count - 1)] }

switch ($cmd) {
  "help"      { Show-Help; exit 0 }
  "status"    {
    $m = Resolve-ManifestPath -Manifest ($rest | Select-Object -SkipWhile { $_ -ne "--manifest" } | Select-Object -Skip 1 -First 1)
    if (-not $m) { Write-Fail "WFSL Shell Guard: --manifest required or proofgate.manifest.json must exist." }
    exit (Invoke-ProofGate -Action "status" -ManifestPath $m -Json)
  }
  "verify"    {
    $m = Resolve-ManifestPath -Manifest ($rest | Select-Object -SkipWhile { $_ -ne "--manifest" } | Select-Object -Skip 1 -First 1)
    if (-not $m) { Write-Fail "WFSL Shell Guard: --manifest required or proofgate.manifest.json must exist." }
    exit (Invoke-ProofGate -Action "verify" -ManifestPath $m)
  }
  "safe-clean"{ Invoke-WFSLSafeClean @rest }
  "wfsl-git"  { Invoke-WFSLGit -GitArgs $rest }
  default     { Write-Fail "WFSL Shell Guard: unknown command '$cmd'. Use: help" }
}
