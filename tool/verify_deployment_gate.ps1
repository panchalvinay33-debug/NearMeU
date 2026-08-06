$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
    Write-Host "DEPLOYMENT BLOCKED: $Message" -ForegroundColor Red
    exit 1
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$manifestPath = Join-Path $repoRoot 'config\official_base_manifest.json'
$projectStatePath = Join-Path $repoRoot 'config\project_state_manifest.json'
$ecosystemPath = Join-Path $repoRoot 'docs\NEARMEEU_ECOSYSTEM_BOUNDARY.md'
if (-not (Test-Path $manifestPath)) { Fail 'Missing official base manifest.' }
if (-not (Test-Path $projectStatePath)) { Fail 'Missing project state manifest.' }
if (-not (Test-Path $ecosystemPath)) { Fail 'Missing NearMeU ecosystem boundary document.' }
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$state = Get-Content $projectStatePath -Raw | ConvertFrom-Json

Set-Location $repoRoot

$branch = (git branch --show-current).Trim()
if ($branch -ne 'main') { Fail "Production deploys require NearMeU main; current branch is '$branch'. Never deploy shared Firebase from NearMeU-Admin or a historical Admin branch." }

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

if (-not $state.ecosystem) { Fail 'Project state is missing ecosystem ownership metadata.' }
if ([string]$state.ecosystem.consumerRepository -ne 'panchalvinay33-debug/NearMeU') { Fail 'Consumer repository ownership metadata mismatch.' }
if ([string]$state.ecosystem.adminRepository -ne 'panchalvinay33-debug/NearMeU-Admin') { Fail 'Admin companion repository metadata mismatch.' }
if ([string]$state.ecosystem.sharedBackendOwnerRepository -ne 'panchalvinay33-debug/NearMeU') { Fail 'Shared backend owner must remain the NearMeU repository unless governance explicitly changes it.' }
if ([string]$state.ecosystem.sharedFirebaseProjectId -ne [string]$manifest.identity.firebaseProjectId) { Fail 'Shared Firebase project metadata mismatch.' }

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

$expectedExports = @(node -e "const x=require('./functions/bootstrap.js'); console.log(Object.keys(x).filter((k)=>x[k]&&x[k].__endpoint).sort().join('\n'))") | Where-Object { $_ -and $_.Trim() }
if ($LASTEXITCODE -ne 0 -or $expectedExports.Count -eq 0) { Fail 'Unable to load accepted deployable Cloud Function exports.' }

Write-Host ''
Write-Host 'NearMeU DEPLOYMENT GATE PASS' -ForegroundColor Green
Write-Host "Branch          : $branch"
Write-Host "Git SHA         : $localSha"
Write-Host "Version         : $($manifest.identity.versionName)+$($manifest.identity.versionCode)"
Write-Host "Firebase        : $($manifest.identity.firebaseProjectId)"
Write-Host "Consumer repo   : $($state.ecosystem.consumerRepository)"
Write-Host "Admin companion : $($state.ecosystem.adminRepository)"
Write-Host "Admin status    : $($state.ecosystem.adminDevelopmentStatus)"
Write-Host "Shared backend  : $($state.ecosystem.sharedBackendOwnerRepository)"
Write-Host "Functions       : $(@($expectedExports).Count) deployable accepted exports load successfully"
Write-Host ''
Write-Host 'Production deployment is permitted from this exact shared-backend source state only. Historical Admin branches are reference-only and must never be deployed directly. Any Admin-related backend change must be rebuilt from current accepted NearMeU main and separately tested against both app contracts.' -ForegroundColor Cyan
