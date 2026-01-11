param(
    [string]$InputText
)

$blockedPatterns = @(
    '^PS\s',
    'CategoryInfo',
    'FullyQualifiedErrorId',
    'At line:\d+ char:\d+',
    '^\+',
    '^\>'
)

foreach ($pattern in $blockedPatterns) {
    if ($InputText -match $pattern) {
        Write-Host ""
        Write-Host "WFSL Shell Guard"
        Write-Host "--------------------------------"
        Write-Host "This appears to be console output, not a command."
        Write-Host "Do not paste PowerShell output back into the shell."
        Write-Host ""
        exit 1
    }
}

Invoke-Expression $InputText
