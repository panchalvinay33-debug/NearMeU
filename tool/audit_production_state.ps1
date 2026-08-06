$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
    Write-Host "PRODUCTION AUDIT FAILED: $Message" -ForegroundColor Red
    exit 1
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$manifestPath = Join-Path $repoRoot 'config\official_base_manifest.json'
if (-not (Test-Path $manifestPath)) { Fail 'Missing official base manifest.' }
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
Set-Location $repoRoot

$project = [string]$manifest.identity.firebaseProjectId
if ($project -ne 'nearmeu-e82c7') { Fail "Unexpected Firebase project '$project'." }

$expected = @(node -e "const x=require('./functions/bootstrap.js'); console.log(Object.keys(x).filter((k)=>x[k]&&x[k].__endpoint).sort().join('\n'))") | Where-Object { $_ -and $_.Trim() }
if ($LASTEXITCODE -ne 0 -or $expected.Count -eq 0) { Fail 'Unable to enumerate accepted deployable Cloud Function exports from functions/bootstrap.js.' }
$expected = @($expected | ForEach-Object { $_.Trim() } | Sort-Object -Unique)

Write-Host "Auditing Firebase project $project ..." -ForegroundColor Cyan
$raw = firebase functions:list --project $project --json 2>$null
if ($LASTEXITCODE -ne 0 -or -not $raw) { Fail 'firebase functions:list failed. Ensure Firebase CLI is installed and logged in.' }

try {
    $json = $raw | ConvertFrom-Json
} catch {
    Fail 'Unable to parse firebase functions:list JSON output.'
}

$items = @()
if ($json.result) { $items = @($json.result) }
elseif ($json.functions) { $items = @($json.functions) }
elseif ($json -is [System.Array]) { $items = @($json) }
else { $items = @($json) }

$actual = New-Object System.Collections.Generic.List[string]
foreach ($item in $items) {
    $candidate = $null
    if ($item.id) { $candidate = [string]$item.id }
    elseif ($item.name) { $candidate = [string]$item.name }
    elseif ($item.entryPoint) { $candidate = [string]$item.entryPoint }
    if ($candidate) {
        if ($candidate -match '/functions/([^/]+)$') { $candidate = $Matches[1] }
        elseif ($candidate -match '^projects/.+/locations/.+/functions/([^/]+)$') { $candidate = $Matches[1] }
        $actual.Add($candidate)
    }
}
$actual = @($actual | Sort-Object -Unique)

if ($actual.Count -eq 0) {
    Write-Host 'WARNING: Firebase CLI returned no parseable function IDs. Raw output shape may have changed.' -ForegroundColor Yellow
    Write-Host 'Expected deployable functions from accepted source:'
    $expected | ForEach-Object { Write-Host "  $_" }
    exit 2
}

$extras = @($actual | Where-Object { $_ -notin $expected })
$missing = @($expected | Where-Object { $_ -notin $actual })

Write-Host ''
Write-Host "Expected accepted deployable functions: $($expected.Count)"
Write-Host "Deployed functions found             : $($actual.Count)"

if ($extras.Count -gt 0) {
    Write-Host ''
    Write-Host 'UNEXPECTED DEPLOYED FUNCTIONS (production drift):' -ForegroundColor Red
    $extras | ForEach-Object { Write-Host "  + $_" -ForegroundColor Red }
}

if ($missing.Count -gt 0) {
    Write-Host ''
    Write-Host 'ACCEPTED DEPLOYABLE FUNCTIONS MISSING FROM PRODUCTION:' -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}

if ($extras.Count -eq 0 -and $missing.Count -eq 0) {
    Write-Host ''
    Write-Host 'NearMeU PRODUCTION FUNCTION AUDIT PASS' -ForegroundColor Green
    Write-Host 'Deployed Cloud Functions exactly match accepted deployable Firebase trigger exports.'
    exit 0
}

Write-Host ''
Write-Host 'Production does not exactly match accepted deployable source. Do not close/promote a batch until drift is resolved.' -ForegroundColor Red
exit 3
