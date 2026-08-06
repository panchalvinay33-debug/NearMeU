$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
    Write-Host "DEPLOYMENT BLOCKED: $Message" -ForegroundColor Red
    exit 1
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$manifestPath = Join-Path $repoRoot 'config\official_base_manifest.json'
if (-not (Test-Path $manifestPath)) { Fail 'Missing official base manifest.' }
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

Set-Location $repoRoot

$branch = (git branch --show-current).Trim()
if ($branch -ne 'main') { Fail "Production deploys require main; current branch is '$branch'." }

$dirty = git status --porcelain
if ($dirty) {
    git status --short
    Fail 'Working tree is not clean.'
}

git fetch --prune origin
if ($LASTEXITCODE -ne 0) { Fail 'git fetch failed.' }

$localSha = (git rev-parse HEAD).Trim()
$remoteSha = (git rev-parse origin/main).Trim()
if ($localSha -ne $remoteSha) { Fail "Local main ($localSha) does not exactly match origin/main ($remoteSha)." }

$pubspec = Get-Content (Join-Path $repoRoot 'pubspec.yaml') -Raw
$expectedVersion = "version: $($manifest.identity.versionName)+$($manifest.identity.versionCode)"
if ($pubspec -notmatch [regex]::Escape($expectedVersion)) { Fail "pubspec version mismatch; expected $expectedVersion." }

if (-not (Test-Path (Join-Path $repoRoot 'functions\bootstrap.js'))) { Fail 'functions/bootstrap.js missing.' }
if (-not (Test-Path (Join-Path $repoRoot 'firestore.rules'))) { Fail 'firestore.rules missing.' }
if (-not (Test-Path (Join-Path $repoRoot 'firestore.indexes.json'))) { Fail 'firestore.indexes.json missing.' }
if (-not (Test-Path (Join-Path $repoRoot 'storage.rules'))) { Fail 'storage.rules missing.' }

$firebaseRcPath = Join-Path $repoRoot '.firebaserc'
if (-not (Test-Path $firebaseRcPath)) { Fail '.firebaserc missing.' }
$firebaseRc = Get-Content $firebaseRcPath -Raw
if ($firebaseRc -notmatch [regex]::Escape($manifest.identity.firebaseProjectId)) { Fail 'Firebase project mismatch.' }

$expectedExports = node -e "const x=require('./functions/bootstrap.js'); console.log(Object.keys(x).sort().join('\n'))"
if ($LASTEXITCODE -ne 0 -or -not $expectedExports) { Fail 'Unable to load accepted Cloud Functions exports.' }

Write-Host ''
Write-Host 'NearMeU DEPLOYMENT GATE PASS' -ForegroundColor Green
Write-Host "Branch     : $branch"
Write-Host "Git SHA    : $localSha"
Write-Host "Version    : $($manifest.identity.versionName)+$($manifest.identity.versionCode)"
Write-Host "Firebase   : $($manifest.identity.firebaseProjectId)"
Write-Host "Functions  : $(@($expectedExports).Count) accepted exports load successfully"
Write-Host ''
Write-Host 'Production deployment is permitted from this exact source state, subject to the batch-specific owner approval and required CI/physical gates.' -ForegroundColor Cyan
