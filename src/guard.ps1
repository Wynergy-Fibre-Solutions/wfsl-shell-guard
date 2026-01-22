# ============================================================
# WFSL PowerShell Profile
# Purpose:
# - Establish WFSL governance invariants at shell startup
# - Provide stable entrypoint to WFSL Shell Guard
# - Eliminate path and setup errors permanently
# ============================================================

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# WFSL ProofGate entry (single source of truth)
# ------------------------------------------------------------
$env:WFSL_PROOFGATE_ENTRY = "C:\Users\Paul Wynn\github\wfsl-proofgate-cli\dist\index.js"

# ------------------------------------------------------------
# WFSL Shell Guard entrypoint
# ------------------------------------------------------------
function wfsl {
  param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
  )

  $guard = "C:\Users\Paul Wynn\github\wfsl-shell-guard\src\guard.ps1"

  if (-not (Test-Path $guard)) {
    Write-Error "WFSL Shell Guard not found at $guard"
    return
  }

  pwsh -File $guard @Args
}

# ------------------------------------------------------------
# Optional quality-of-life aliases (safe)
# ------------------------------------------------------------
Set-Alias wfsl-git wfsl
Set-Alias wfsl-clean wfsl

# ------------------------------------------------------------
# Startup confirmation (quiet, non-noisy)
# ------------------------------------------------------------
# Uncomment if you want a visible confirmation each session
# Write-Host "WFSL shell governance active"
