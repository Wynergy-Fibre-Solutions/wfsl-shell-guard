# verify.ps1
# WFSL Shell Guard verification script (local). PSG-focused: ensure JSON-only stdout and adapter compatibility.

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repo = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $repo

$adapter = Join-Path $HOME "github\wfsl-proofgate-cli\tools\wfsl-adapter.mjs"
$outDir  = Join-Path $HOME "github\wfsl-proofgate-cli\proofs"
$outFile = Join-Path $outDir "adapter-parallel-shell-guard.json"

if (-not (Test-Path $adapter)) {
  throw "Missing adapter: $adapter"
}

New-Item -ItemType Directory -Force $outDir | Out-Null

function Assert-JsonFile {
  param([Parameter(Mandatory=$true)][string] $Path)
  node -e "JSON.parse(require('fs').readFileSync(process.argv[1],'utf8')); console.log('JSON OK')" "$Path" | Out-Null
}

# Test 1: Allow path (non-human input)
$allowInput = "wfsl-shell-guard-execution"
pwsh -NoProfile -ExecutionPolicy Bypass -File ".\wfsl-shell-guard.ps1" -InputText $allowInput |
  node $adapter > $outFile

Assert-JsonFile -Path $outFile

# Test 2: Deny path (human language)
$denyInput = "this looks like a human sentence"
pwsh -NoProfile -ExecutionPolicy Bypass -File ".\wfsl-shell-guard.ps1" -InputText $denyInput |
  node $adapter > $outFile

Assert-JsonFile -Path $outFile

# Test 3: Strict empty input denial
pwsh -NoProfile -ExecutionPolicy Bypass -File ".\wfsl-shell-guard.ps1" -Strict |
  node $adapter > $outFile

Assert-JsonFile -Path $outFile

"PASS"
