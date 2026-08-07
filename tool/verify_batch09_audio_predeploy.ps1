$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
    Write-Host "BATCH09 PRE-DEPLOY BLOCKED: $Message" -ForegroundColor Red
    exit 1
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $repoRoot

$expectedBranch = 'batch/09-audio-calling-v3'
$branch = (git branch --show-current).Trim()
if ($branch -ne $expectedBranch) { Fail "Expected branch '$expectedBranch', current branch is '$branch'." }

$dirty = git status --porcelain
if ($dirty) {
    git status --short
    Fail 'Working tree is not clean.'
}

git fetch --prune origin
if ($LASTEXITCODE -ne 0) { Fail 'git fetch failed.' }

$localSha = (git rev-parse HEAD).Trim()
$remoteSha = (git rev-parse "origin/$expectedBranch").Trim()
if ($localSha -ne $remoteSha) { Fail "Local branch ($localSha) does not exactly match origin/$expectedBranch ($remoteSha)." }

$mainSha = (git rev-parse origin/main).Trim()
git merge-base --is-ancestor $mainSha $localSha
if ($LASTEXITCODE -ne 0) { Fail 'Current accepted main is not an ancestor of this Batch09 branch.' }

$manifestPath = Join-Path $repoRoot 'config\official_base_manifest.json'
$statePath = Join-Path $repoRoot 'config\project_state_manifest.json'
if (-not (Test-Path $manifestPath)) { Fail 'Missing official base manifest.' }
if (-not (Test-Path $statePath)) { Fail 'Missing project state manifest.' }
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$state = Get-Content $statePath -Raw | ConvertFrom-Json

if ([string]$manifest.identity.repository -ne 'panchalvinay33-debug/NearMeU') { Fail 'Repository identity mismatch.' }
if ([string]$state.ecosystem.sharedBackendOwnerRepository -ne 'panchalvinay33-debug/NearMeU') { Fail 'Shared Firebase backend ownership mismatch.' }
if ([string]$state.ecosystem.adminRepository -ne 'panchalvinay33-debug/NearMeU-Admin') { Fail 'Admin companion metadata mismatch.' }
if ([string]$state.ecosystem.adminDevelopmentStatus -ne 'PAUSED_UNTIL_CONSUMER_PUBLIC_LAUNCH_OWNER_RESUME') { Fail 'Admin pause state changed unexpectedly.' }

$firebaseRcPath = Join-Path $repoRoot '.firebaserc'
if (-not (Test-Path $firebaseRcPath)) { Fail '.firebaserc missing.' }
$firebaseRc = Get-Content $firebaseRcPath -Raw
if ($firebaseRc -notmatch [regex]::Escape([string]$manifest.identity.firebaseProjectId)) { Fail 'Firebase project mismatch.' }

$requiredFiles = @(
    'functions\bootstrap.js',
    'functions\audio_call_functions.js',
    'functions\audio_call_safety_functions.js',
    'functions\package.json',
    'functions\package-lock.json',
    'pubspec.yaml',
    'android\app\src\main\AndroidManifest.xml'
)
foreach ($file in $requiredFiles) {
    if (-not (Test-Path (Join-Path $repoRoot $file))) { Fail "Missing Batch09 required file: $file" }
}

npm ci --prefix functions --no-audit --no-fund
if ($LASTEXITCODE -ne 0) { Fail 'functions npm ci failed.' }

$audioSource = Get-Content (Join-Path $repoRoot 'functions\audio_call_functions.js') -Raw
foreach ($secretName in @('AGORA_APP_ID','AGORA_APP_CERTIFICATE')) {
    $pattern = 'defineSecret\("' + [regex]::Escape($secretName) + '"\)'
    if ($audioSource -notmatch $pattern) { Fail "Missing Firebase secret binding: $secretName" }
}

$project = [string]$manifest.identity.firebaseProjectId
$previousGcloudProject = $env:GCLOUD_PROJECT
$previousGoogleCloudProject = $env:GOOGLE_CLOUD_PROJECT
$previousGcpProject = $env:GCP_PROJECT
$previousFirebaseConfig = $env:FIREBASE_CONFIG
try {
    $env:GCLOUD_PROJECT = $project
    $env:GOOGLE_CLOUD_PROJECT = $project
    $env:GCP_PROJECT = $project
    $env:FIREBASE_CONFIG = '{"projectId":"' + $project + '"}'
    $env:FIREBASE_CONFIG = $env:FIREBASE_CONFIG.Replace('\"','"')

    $exports = @(node -e "const x=require('./functions/bootstrap.js'); console.log(Object.keys(x).filter((k)=>x[k]&&x[k].__endpoint).sort().join('\n'))") | Where-Object { $_ -and $_.Trim() }
    if ($LASTEXITCODE -ne 0 -or $exports.Count -eq 0) { Fail 'Unable to load Cloud Function exports.' }
} finally {
    $env:GCLOUD_PROJECT = $previousGcloudProject
    $env:GOOGLE_CLOUD_PROJECT = $previousGoogleCloudProject
    $env:GCP_PROJECT = $previousGcpProject
    $env:FIREBASE_CONFIG = $previousFirebaseConfig
}

$requiredAudioExports = @(
    'startAudioCall',
    'respondAudioCall',
    'endAudioCall',
    'getAudioCall',
    'getPendingAudioCall',
    'listAudioCallHistory',
    'expireStaleAudioCalls',
    'endAudioCallOnBlock',
    'endAudioCallOnSuspension',
    'endAudioCallOnUserDelete'
)
foreach ($name in $requiredAudioExports) {
    if ($exports -notcontains $name) { Fail "Missing required Batch09 export: $name" }
}

$forbidden = @($exports | Where-Object { $_ -match '(?i)admin|videoCall|videoSession' })
if ($forbidden.Count -gt 0) { Fail "Forbidden Admin/video exports detected: $($forbidden -join ', ')" }

Write-Host ''
Write-Host 'NearMeU BATCH09 AUDIO PRE-DEPLOY GATE PASS' -ForegroundColor Green
Write-Host "Branch        : $branch"
Write-Host "Git SHA       : $localSha"
Write-Host "Accepted main : $mainSha"
Write-Host "Firebase      : $project"
Write-Host "Audio exports : $($requiredAudioExports.Count) required exports verified"
Write-Host 'Secrets       : AGORA_APP_ID + AGORA_APP_CERTIFICATE bindings verified (values not read or printed)'
Write-Host ''
Write-Host 'This gate performs validation only. It does NOT deploy Firebase and does NOT mark Batch09 accepted.' -ForegroundColor Cyan
