param(
    [switch]$OwnerAccepted,
    [string]$AcceptedApkPath
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
    Write-Host "PROMOTION BLOCKED: $Message" -ForegroundColor Red
    exit 1
}

if (-not $OwnerAccepted) {
    Fail 'Explicit -OwnerAccepted is required. Promotion must never happen automatically before owner acceptance.'
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$manifestPath = Join-Path $repoRoot 'config\official_base_manifest.json'
if (-not (Test-Path $manifestPath)) { Fail 'Missing official base manifest.' }
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json

Set-Location $repoRoot

$branch = (git branch --show-current).Trim()
if ($branch -ne 'main') { Fail "Promotion requires main; current branch is '$branch'." }

$dirty = git status --porcelain
if ($dirty) { git status --short; Fail 'Working tree must be clean.' }

git fetch --prune --tags origin
if ($LASTEXITCODE -ne 0) { Fail 'git fetch failed.' }

$head = (git rev-parse HEAD).Trim()
$originMain = (git rev-parse origin/main).Trim()
if ($head -ne $originMain) { Fail "Local main ($head) does not match origin/main ($originMain)." }

if ([string]$manifest.status -ne 'READY_FOR_PROMOTION') {
    Fail "Manifest status must be READY_FOR_PROMOTION; current status is '$($manifest.status)'."
}

$manifestSha = [string]$manifest.recovery.currentOfficialSourceSha
if ($manifestSha -ne $head) {
    Fail "Manifest official source SHA ($manifestSha) must equal current main HEAD ($head) before promotion."
}

$tagName = [string]$manifest.recovery.immutableTagName
if ([string]::IsNullOrWhiteSpace($tagName)) { Fail 'Manifest immutableTagName is empty.' }
if ([string]$manifest.recovery.immutableTagStatus -ne 'READY_TO_CREATE') {
    Fail "Manifest immutableTagStatus must be READY_TO_CREATE; current value is '$($manifest.recovery.immutableTagStatus)'."
}

git rev-parse -q --verify "refs/tags/$tagName" *> $null
if ($LASTEXITCODE -eq 0) { Fail "Tag '$tagName' already exists locally. Promotion refuses to move it." }

$remoteTag = git ls-remote --tags origin "refs/tags/$tagName"
if ($remoteTag) { Fail "Tag '$tagName' already exists on origin. Promotion refuses to move it." }

Write-Host "Creating immutable acceptance tag $tagName at $head" -ForegroundColor Cyan
git tag -a $tagName $head -m "NearMeU official recoverable Base $($manifest.acceptedProductBoundary.throughBatch) accepted $($manifest.lastUpdated)"
if ($LASTEXITCODE -ne 0) { Fail 'Unable to create acceptance tag.' }

git push origin "refs/tags/$tagName"
if ($LASTEXITCODE -ne 0) { Fail 'Unable to push acceptance tag.' }

Write-Host "Promoting recovery branch $($manifest.identity.recoveryBranch) to $head" -ForegroundColor Cyan
git push origin "HEAD:refs/heads/$($manifest.identity.recoveryBranch)"
if ($LASTEXITCODE -ne 0) { Fail 'Unable to fast-forward recovery branch. Do not force automatically; inspect branch protection/history.' }

$remoteRecovery = (git rev-parse "origin/$($manifest.identity.recoveryBranch)").Trim()
if ($remoteRecovery -ne $head) {
    git fetch origin $($manifest.identity.recoveryBranch)
    $remoteRecovery = (git rev-parse "origin/$($manifest.identity.recoveryBranch)").Trim()
}
if ($remoteRecovery -ne $head) { Fail 'Recovery branch did not resolve to promoted main HEAD.' }

$bundleDir = [string]$manifest.recovery.localBundleDirectory
if ([string]::IsNullOrWhiteSpace($bundleDir)) { $bundleDir = Join-Path $repoRoot 'local_recovery' }
New-Item -ItemType Directory -Force -Path $bundleDir | Out-Null

$bundlePath = Join-Path $bundleDir ("NearMeU-$tagName.bundle")
Write-Host "Creating offline Git bundle: $bundlePath" -ForegroundColor Cyan
git bundle create $bundlePath "refs/tags/$tagName"
if ($LASTEXITCODE -ne 0) { Fail 'Unable to create offline Git bundle.' }

$bundleHash = (Get-FileHash -Algorithm SHA256 $bundlePath).Hash.ToLowerInvariant()
$bundleHashPath = "$bundlePath.sha256"
"$bundleHash  $([IO.Path]::GetFileName($bundlePath))" | Set-Content -Encoding ascii $bundleHashPath

Copy-Item $manifestPath (Join-Path $bundleDir "official_base_manifest-$tagName.json") -Force

if ($AcceptedApkPath) {
    if (-not (Test-Path $AcceptedApkPath)) { Fail "Accepted APK path not found: $AcceptedApkPath" }
    $apkDest = Join-Path $bundleDir ("NearMeU-$tagName.apk")
    Copy-Item $AcceptedApkPath $apkDest -Force
    $apkHash = (Get-FileHash -Algorithm SHA256 $apkDest).Hash.ToLowerInvariant()
    "$apkHash  $([IO.Path]::GetFileName($apkDest))" | Set-Content -Encoding ascii "$apkDest.sha256"
    Write-Host "Accepted APK copied with SHA-256 $apkHash" -ForegroundColor Green
}

Write-Host ''
Write-Host 'NearMeU OFFICIAL BASE PROMOTION PASS' -ForegroundColor Green
Write-Host "Main / recovery SHA : $head"
Write-Host "Immutable tag       : $tagName"
Write-Host "Offline bundle      : $bundlePath"
Write-Host "Bundle SHA-256      : $bundleHash"
Write-Host ''
Write-Host 'Final documentation step: update manifest immutableTagStatus to PROMOTED and record the bundle/hash evidence in the closeout ledger.' -ForegroundColor Yellow
