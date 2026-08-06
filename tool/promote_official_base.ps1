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
if ([string]$manifest.production.firebaseProductionAudit -ne 'PASS') {
    Fail "Production audit must be PASS; current value is '$($manifest.production.firebaseProductionAudit)'."
}

$testedRuntimeSha = [string]$manifest.currentRecertificationCandidate.runtimeTestedSha
if ([string]::IsNullOrWhiteSpace($testedRuntimeSha)) {
    Fail 'Manifest currentRecertificationCandidate.runtimeTestedSha is missing.'
}

git cat-file -e "$testedRuntimeSha^{commit}" 2>$null
if ($LASTEXITCODE -ne 0) { Fail "Physically-tested runtime SHA does not resolve: $testedRuntimeSha" }

git merge-base --is-ancestor $testedRuntimeSha $head
if ($LASTEXITCODE -ne 0) {
    Fail "Physically-tested runtime SHA $testedRuntimeSha is not an ancestor of current main $head."
}

# The runtime was physically tested at runtimeTestedSha. Between that SHA and the
# final immutable closeout snapshot, only non-runtime governance/evidence paths
# may change. Any consumer/runtime/Firebase source change requires a new APK and
# focused physical re-test before promotion.
$changedPaths = @(git diff --name-only "$testedRuntimeSha..$head")
$forbiddenPaths = @()
foreach ($path in $changedPaths) {
    $allowed = (
        $path -eq 'README.md' -or
        $path.StartsWith('.github/') -or
        $path.StartsWith('config/') -or
        $path.StartsWith('docs/') -or
        $path.StartsWith('tool/')
    )
    if (-not $allowed) { $forbiddenPaths += $path }
}
if ($forbiddenPaths.Count -gt 0) {
    Write-Host 'Runtime/source drift detected after the physically-tested candidate:' -ForegroundColor Red
    $forbiddenPaths | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
    Fail 'Final promotion requires a new signed APK and physical re-test for these runtime changes.'
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

Write-Host "Preparing immutable acceptance tag $tagName at $head" -ForegroundColor Cyan
git tag -a $tagName $head -m "NearMeU official recoverable Base $($manifest.acceptedProductBoundary.throughBatch) accepted $($manifest.lastUpdated)"
if ($LASTEXITCODE -ne 0) { Fail 'Unable to create acceptance tag.' }

$recoveryBranch = [string]$manifest.identity.recoveryBranch
Write-Host "Atomically promoting tag + recovery branch to $head" -ForegroundColor Cyan
git push --atomic origin "HEAD:refs/heads/$recoveryBranch" "refs/tags/$tagName"
if ($LASTEXITCODE -ne 0) {
    git tag -d $tagName *> $null
    Fail 'Atomic tag/recovery promotion failed. Nothing should be force-moved automatically.'
}

git fetch origin $recoveryBranch --tags
if ($LASTEXITCODE -ne 0) { Fail 'Unable to verify promoted refs.' }

$remoteRecovery = (git rev-parse "origin/$recoveryBranch").Trim()
if ($remoteRecovery -ne $head) { Fail 'Recovery branch did not resolve to promoted main HEAD.' }

$remoteTagSha = (git rev-list -n 1 $tagName).Trim()
if ($remoteTagSha -ne $head) { Fail 'Immutable tag did not resolve to promoted main HEAD.' }

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

$apkHash = $null
$apkDest = $null
if ($AcceptedApkPath) {
    if (-not (Test-Path $AcceptedApkPath)) { Fail "Accepted APK path not found: $AcceptedApkPath" }
    $apkDest = Join-Path $bundleDir ("NearMeU-$tagName.apk")
    Copy-Item $AcceptedApkPath $apkDest -Force
    $apkHash = (Get-FileHash -Algorithm SHA256 $apkDest).Hash.ToLowerInvariant()
    "$apkHash  $([IO.Path]::GetFileName($apkDest))" | Set-Content -Encoding ascii "$apkDest.sha256"
}

$evidence = [ordered]@{
    project = 'NearMeU'
    promotedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    promotedMainSha = $head
    physicallyTestedRuntimeSha = $testedRuntimeSha
    immutableTag = $tagName
    recoveryBranch = $recoveryBranch
    bundlePath = $bundlePath
    bundleSha256 = $bundleHash
    acceptedApkPath = $apkDest
    acceptedApkSha256 = $apkHash
}
$evidencePath = Join-Path $bundleDir ("promotion-evidence-$tagName.json")
$evidence | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 $evidencePath

Write-Host ''
Write-Host 'NearMeU OFFICIAL BASE PROMOTION PASS' -ForegroundColor Green
Write-Host "Main / recovery SHA : $head"
Write-Host "Tested runtime SHA  : $testedRuntimeSha"
Write-Host "Immutable tag       : $tagName"
Write-Host "Offline bundle      : $bundlePath"
Write-Host "Bundle SHA-256      : $bundleHash"
Write-Host "Promotion evidence  : $evidencePath"
Write-Host ''
Write-Host 'No post-tag repository commit is required: tag existence + local promotion evidence are the promotion proof.' -ForegroundColor Green
