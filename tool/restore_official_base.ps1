param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}

$expectedRoot = 'F:\NearMeU'
$manifestPath = Join-Path $PSScriptRoot '..\config\official_base_manifest.json'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path

if ($repoRoot -ne $expectedRoot) {
    Write-Host "WARNING: canonical NearMeU workspace is $expectedRoot; current repo is $repoRoot" -ForegroundColor Yellow
}

if (-not (Test-Path $manifestPath)) {
    Fail "Missing config/official_base_manifest.json"
}

$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
if ($manifest.identity.repository -ne 'panchalvinay33-debug/NearMeU') { Fail 'Repository identity mismatch in official base manifest.' }
if ($manifest.identity.firebaseProjectId -ne 'nearmeu-e82c7') { Fail 'Firebase project identity mismatch in official base manifest.' }
if ($manifest.identity.androidApplicationId -ne 'com.nearmeu.nearmeu') { Fail 'Android application ID mismatch in official base manifest.' }

Set-Location $repoRoot

$dirty = git status --porcelain
if ($LASTEXITCODE -ne 0) { Fail 'git status failed.' }
if ($dirty -and -not $Force) {
    Write-Host 'Local changes detected. Recovery stopped to protect uncommitted work.' -ForegroundColor Yellow
    Write-Host 'Review/backup changes first, or intentionally rerun with -Force.' -ForegroundColor Yellow
    git status --short
    exit 2
}

$targetSha = [string]$manifest.recovery.currentOfficialSourceSha
if ([string]::IsNullOrWhiteSpace($targetSha)) { Fail 'Official source SHA is empty.' }

Write-Host "Recovering NearMeU to official source SHA: $targetSha" -ForegroundColor Cyan

git fetch --prune origin
if ($LASTEXITCODE -ne 0) { Fail 'git fetch failed.' }

# Verify the accepted commit exists before changing the working tree.
git cat-file -e "$targetSha^{commit}" 2>$null
if ($LASTEXITCODE -ne 0) { Fail "Official accepted SHA $targetSha is not available after fetch." }

if ($Force -and $dirty) {
    git reset --hard
    if ($LASTEXITCODE -ne 0) { Fail 'Unable to discard tracked local changes.' }
    git clean -fd
    if ($LASTEXITCODE -ne 0) { Fail 'Unable to remove untracked local files.' }
}

git switch main
if ($LASTEXITCODE -ne 0) { Fail 'Unable to switch to main.' }

git reset --hard $targetSha
if ($LASTEXITCODE -ne 0) { Fail 'Unable to reset to official source SHA.' }

$currentSha = (git rev-parse HEAD).Trim()
if ($currentSha -ne $targetSha) { Fail "Recovery SHA mismatch. Expected $targetSha, got $currentSha" }

$pubspec = Get-Content (Join-Path $repoRoot 'pubspec.yaml') -Raw
$expectedVersion = "version: $($manifest.identity.versionName)+$($manifest.identity.versionCode)"
if ($pubspec -notmatch [regex]::Escape($expectedVersion)) {
    Fail "pubspec version does not match manifest ($expectedVersion)."
}

$firebaseRc = Join-Path $repoRoot '.firebaserc'
if (Test-Path $firebaseRc) {
    $firebaseText = Get-Content $firebaseRc -Raw
    if ($firebaseText -notmatch [regex]::Escape($manifest.identity.firebaseProjectId)) {
        Fail 'Firebase project in .firebaserc does not match official manifest.'
    }
}

Write-Host ''
Write-Host 'NearMeU OFFICIAL BASE SOURCE RECOVERY PASS' -ForegroundColor Green
Write-Host "Repository : $($manifest.identity.repository)"
Write-Host "Workspace  : $repoRoot"
Write-Host "Git SHA    : $currentSha"
Write-Host "Version    : $($manifest.identity.versionName)+$($manifest.identity.versionCode)"
Write-Host "Firebase   : $($manifest.identity.firebaseProjectId)"
Write-Host "Package    : $($manifest.identity.androidApplicationId)"
Write-Host ''
Write-Host 'Next safety step: run .\tool\audit_production_state.ps1 before any Firebase recovery/deployment.' -ForegroundColor Cyan
