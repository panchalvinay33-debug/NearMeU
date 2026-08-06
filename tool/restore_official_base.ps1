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

if (-not (Test-Path $manifestPath)) { Fail 'Missing config/official_base_manifest.json' }

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

Write-Host 'Fetching main, recovery branch and immutable tags...' -ForegroundColor Cyan
git fetch --prune --tags origin
if ($LASTEXITCODE -ne 0) { Fail 'git fetch failed.' }

$targetSha = $null
$resolvedFrom = $null
$tagName = [string]$manifest.recovery.immutableTagName
$tagStatus = [string]$manifest.recovery.immutableTagStatus

if (-not [string]::IsNullOrWhiteSpace($tagName) -and $tagStatus -eq 'PROMOTED') {
    git rev-parse -q --verify "refs/tags/$tagName^{commit}" *> $null
    if ($LASTEXITCODE -eq 0) {
        $targetSha = (git rev-parse "refs/tags/$tagName^{commit}").Trim()
        $resolvedFrom = "immutable tag $tagName"
    } else {
        Fail "Manifest says immutable tag '$tagName' is PROMOTED, but the tag is unavailable. Do not guess a recovery target."
    }
}

if (-not $targetSha) {
    $manifestSha = [string]$manifest.recovery.currentOfficialSourceSha
    if (-not [string]::IsNullOrWhiteSpace($manifestSha)) {
        git cat-file -e "$manifestSha^{commit}" 2>$null
        if ($LASTEXITCODE -eq 0) {
            $targetSha = $manifestSha
            $resolvedFrom = 'official manifest SHA'
        }
    }
}

if (-not $targetSha) {
    $recoveryRef = "origin/$($manifest.identity.recoveryBranch)"
    git rev-parse -q --verify "$recoveryRef^{commit}" *> $null
    if ($LASTEXITCODE -eq 0) {
        $targetSha = (git rev-parse "$recoveryRef^{commit}").Trim()
        $resolvedFrom = "recovery branch $recoveryRef"
    }
}

if (-not $targetSha) { Fail 'No valid official recovery target could be resolved from tag, manifest SHA or recovery branch.' }

Write-Host "Recovering NearMeU from $resolvedFrom" -ForegroundColor Cyan
Write-Host "Target SHA: $targetSha" -ForegroundColor Cyan

if ($Force -and $dirty) {
    git reset --hard
    if ($LASTEXITCODE -ne 0) { Fail 'Unable to discard tracked local changes.' }
    git clean -fd
    if ($LASTEXITCODE -ne 0) { Fail 'Unable to remove untracked local files.' }
}

git switch main
if ($LASTEXITCODE -ne 0) { Fail 'Unable to switch to main.' }

git reset --hard $targetSha
if ($LASTEXITCODE -ne 0) { Fail 'Unable to reset to official recovery target.' }

$currentSha = (git rev-parse HEAD).Trim()
if ($currentSha -ne $targetSha) { Fail "Recovery SHA mismatch. Expected $targetSha, got $currentSha" }

$pubspec = Get-Content (Join-Path $repoRoot 'pubspec.yaml') -Raw
$expectedVersion = "version: $($manifest.identity.versionName)+$($manifest.identity.versionCode)"
if ($pubspec -notmatch [regex]::Escape($expectedVersion)) { Fail "pubspec version does not match manifest ($expectedVersion)." }

$firebaseRc = Join-Path $repoRoot '.firebaserc'
if (Test-Path $firebaseRc) {
    $firebaseText = Get-Content $firebaseRc -Raw
    if ($firebaseText -notmatch [regex]::Escape($manifest.identity.firebaseProjectId)) { Fail 'Firebase project in .firebaserc does not match official manifest.' }
}

Write-Host ''
Write-Host 'NearMeU OFFICIAL BASE SOURCE RECOVERY PASS' -ForegroundColor Green
Write-Host "Repository : $($manifest.identity.repository)"
Write-Host "Workspace  : $repoRoot"
Write-Host "Resolved   : $resolvedFrom"
Write-Host "Git SHA    : $currentSha"
Write-Host "Version    : $($manifest.identity.versionName)+$($manifest.identity.versionCode)"
Write-Host "Firebase   : $($manifest.identity.firebaseProjectId)"
Write-Host "Package    : $($manifest.identity.androidApplicationId)"
Write-Host ''
Write-Host 'Next safety step: run .\tool\audit_production_state.ps1 before any Firebase recovery/deployment.' -ForegroundColor Cyan
