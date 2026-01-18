<# 
WFSL Shell Guard
Version: Hardened v1
Purpose:
- Deterministic execution safety
- Prompt contamination prevention
- CI-safe, non-interactive enforcement

No telemetry. No network access.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Fail {
    param([string]$Message)
    Write-Error "[WFSL-SHELL-GUARD] $Message"
    exit 1
}

# ---------------------------------------------------------------------------
# Guard 1: Raw command line inspection (authoritative)
# ---------------------------------------------------------------------------

$CommandLine = [Environment]::CommandLine

if ($CommandLine -match 'PS\s+[A-Z]:\\') {
    Fail "Prompt contamination detected. Remove 'PS C:\...' prefix."
}

if ($CommandLine -match '>\s*pwsh') {
    Fail "Detected pasted console prompt redirection."
}

# ---------------------------------------------------------------------------
# Guard 2: Invocation integrity
# ---------------------------------------------------------------------------

if (-not $MyInvocation.MyCommand.Path) {
    Fail "Script must be invoked via explicit file path."
}

$ResolvedPath = (Resolve-Path $MyInvocation.MyCommand.Path).Path

if (-not (Test-Path $ResolvedPath)) {
    Fail "Invocation path resolution failed."
}

# ---------------------------------------------------------------------------
# Guard 3: Interactive prompt paste detection
# ---------------------------------------------------------------------------

if ($Host.Name -eq 'ConsoleHost') {
    $last = Get-History -Count 1 -ErrorAction SilentlyContinue
    if ($last -and $last.CommandLine -match '^PS\s+[A-Z]:\\') {
        Fail "Interactive prompt paste detected."
    }
}

# ---------------------------------------------------------------------------
# Guard 4: Execution policy neutrality
# ---------------------------------------------------------------------------

$policy = Get-ExecutionPolicy -Scope Process
if ($policy -ne 'Bypass') {
    Write-Host "[WFSL-SHELL-GUARD] ExecutionPolicy=$policy (allowed)"
}

# ---------------------------------------------------------------------------
# PASS
# ---------------------------------------------------------------------------

Write-Host "[WFSL-SHELL-GUARD] Environment clean."
Write-Host "[WFSL-SHELL-GUARD] Execution permitted."

exit 0
