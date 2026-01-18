<# 
WFSL Shell Guard
Deterministic PowerShell execution filter

- Rejects prose, prompt pollution, mixed human input
- Allows only a single valid PowerShell command
- Zero execution on ambiguity
- Deterministic ALLOW / DENY verdicts
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateNotNullOrEmpty()]
    [string]$InputText
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Emit-Verdict {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('ALLOW','DENY')]
        [string]$Verdict,

        [Parameter(Mandatory)]
        [string]$Code
    )

    $hash = [System.BitConverter]::ToString(
        (New-Object System.Security.Cryptography.SHA256Managed)
        .ComputeHash([System.Text.Encoding]::UTF8.GetBytes($InputText))
    ).Replace('-', '').ToLowerInvariant()

    Write-Output $Verdict
    Write-Output "code: $Code"
    Write-Output "sha256: $hash"

    if ($Verdict -eq 'DENY') {
        exit 1
    }

    exit 0
}

# ---- Normalisation ----------------------------------------------------------

$normalized = $InputText.Trim()

# ---- Hard rejection rules ---------------------------------------------------

if ($normalized -match '[\r\n]') {
    Emit-Verdict DENY 'MULTILINE_INPUT'
}

if ($normalized -match '[:;,]') {
    Emit-Verdict DENY 'PROSE_DETECTED'
}

if ($normalized -match '\b(is|this|that|why|because|guard|pasted)\b') {
    Emit-Verdict DENY 'HUMAN_LANGUAGE_DETECTED'
}

# ---- PowerShell parse validation --------------------------------------------

try {
    [System.Management.Automation.Language.Parser]::ParseInput(
        $normalized,
        [ref]$null,
        [ref]$null
    ) | Out-Null
}
catch {
    Emit-Verdict DENY 'INVALID_POWERSHELL_SYNTAX'
}

# ---- Success ----------------------------------------------------------------

Emit-Verdict ALLOW 'CLEAN_EXECUTABLE_INPUT'
