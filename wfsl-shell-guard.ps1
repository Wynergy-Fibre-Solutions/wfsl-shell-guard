<# 
WFSL Shell Guard
Deterministic PowerShell execution guard.

Purpose:
- Reject prompt pollution, prose, errors, and mixed human input
- Allow only a single, valid PowerShell command
- Provide deterministic ALLOW / DENY verdicts
- Zero execution on ambiguity

This guard NEVER executes commands.
It only evaluates input.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

param(
    [Parameter(Mandatory)]
    [string]$InputText
)

function Emit-Verdict {
    param(
        [Parameter(Mandatory)][ValidateSet('ALLOW','DENY')]
        [string]$Decision,

        [Parameter(Mandatory)]
        [string]$Code
    )

    $hash = [System.BitConverter]::ToString(
        [System.Security.Cryptography.SHA256]::Create().ComputeHash(
            [System.Text.Encoding]::UTF8.GetBytes($InputText)
        )
    ).Replace('-', '').ToLowerInvariant()

    Write-Output "$Decision"
    Write-Output "code: $Code"
    Write-Output "sha256: $hash"

    if ($Decision -eq 'DENY') {
        exit 1
    }

    exit 0
}

# Normalise input
$raw = $InputText.Trim()

# Empty input
if ([string]::IsNullOrWhiteSpace($raw)) {
    Emit-Verdict -Decision DENY -Code 'EMPTY_INPUT'
}

# Block PowerShell prompt pollution
$promptPatterns = @(
    '^\s*PS\s+[A-Z]:\\',
    '^\s*>>',
    '^\s*\+',
    'At\s+line\s+\d+',
    'CategoryInfo',
    'FullyQualifiedErrorId'
)

foreach ($pattern in $promptPatterns) {
    if ($raw -match $pattern) {
        Emit-Verdict -Decision DENY -Code 'PROMPT_OR_ERROR_POLLUTION'
    }
}

# Block prose (sentences, explanations, URLs)
if ($raw -match '\.\s' -or $raw -match 'https?://' -or $raw -match '[a-zA-Z]{4,}\s+[a-zA-Z]{4,}') {
    Emit-Verdict -Decision DENY -Code 'PROSE_DETECTED'
}

# Block multi-line input
if ($raw -match "`n") {
    Emit-Verdict -Decision DENY -Code 'MULTILINE_INPUT'
}

# Block multiple commands chained
if ($raw -match '[;&|]{2,}|;') {
    Emit-Verdict -Decision DENY -Code 'COMMAND_CHAINING'
}

# Parse PowerShell AST
try {
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $raw,
        [ref]$tokens,
        [ref]$errors
    )

    if ($errors.Count -gt 0) {
        Emit-Verdict -Decision DENY -Code 'PARSE_ERROR'
    }
}
catch {
    Emit-Verdict -Decision DENY -Code 'AST_FAILURE'
}

# Only allow a single pipeline
$pipelines = $ast.FindAll(
    { param($n) $n -is [System.Management.Automation.Language.PipelineAst] },
    $true
)

if ($pipelines.Count -ne 1) {
    Emit-Verdict -Decision DENY -Code 'MULTIPLE_PIPELINES'
}

# Passed all checks
Emit-Verdict -Decision ALLOW -Code 'CLEAN_EXECUTABLE_INPUT'
