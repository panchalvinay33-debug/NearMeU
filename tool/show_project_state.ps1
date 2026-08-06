$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$manifestPath = Join-Path $repoRoot 'config\official_base_manifest.json'
$projectStatePath = Join-Path $repoRoot 'config\project_state_manifest.json'

if (-not (Test-Path $manifestPath)) { throw 'Missing config/official_base_manifest.json' }
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$state = $null
if (Test-Path $projectStatePath) { $state = Get-Content $projectStatePath -Raw | ConvertFrom-Json }

Set-Location $repoRoot
$currentSha = (git rev-parse HEAD 2>$null)
$currentBranch = (git branch --show-current 2>$null)
$dirty = git status --porcelain 2>$null

Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' NearMeU PROJECT STATE' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host "Repository        : $($manifest.identity.repository)"
Write-Host "Canonical folder  : $($manifest.identity.canonicalPcWorkspace)"
Write-Host "Firebase project  : $($manifest.identity.firebaseProjectId)"
Write-Host "Android package   : $($manifest.identity.androidApplicationId)"
Write-Host "App version       : $($manifest.identity.versionName)+$($manifest.identity.versionCode)"
Write-Host "Accepted boundary : Batch $($manifest.acceptedProductBoundary.throughBatch)"
Write-Host "Manifest status   : $($manifest.status)"
Write-Host "Official source   : $($manifest.recovery.currentOfficialSourceSha)"
Write-Host "Recovery branch   : $($manifest.identity.recoveryBranch)"
if ($manifest.currentRecertificationCandidate) {
    Write-Host "Current candidate : $($manifest.currentRecertificationCandidate.mainSha)"
    Write-Host "Candidate status  : $($manifest.currentRecertificationCandidate.candidateStatus)"
}
Write-Host ''
Write-Host "Current branch    : $currentBranch"
Write-Host "Current local SHA : $currentSha"
if ($dirty) { Write-Host 'Working tree      : DIRTY' -ForegroundColor Yellow } else { Write-Host 'Working tree      : CLEAN' -ForegroundColor Green }

Write-Host ''
Write-Host 'Fresh Base08 physical re-certification:' -ForegroundColor Cyan
$manifest.freshBase08PhysicalRecertification.PSObject.Properties | ForEach-Object {
    $value = [string]$_.Value
    $color = if ($value -eq 'PASS') { 'Green' } else { 'Yellow' }
    Write-Host ("  {0,-40} {1}" -f $_.Name, $value) -ForegroundColor $color
}

Write-Host ''
Write-Host 'Final version-display candidate:' -ForegroundColor Cyan
Write-Host "  PR              : #$($manifest.finalVersionDisplayCandidate.pullRequest)"
Write-Host "  Automated gates : $($manifest.finalVersionDisplayCandidate.automatedGates)"
Write-Host "  Physical check  : $($manifest.finalVersionDisplayCandidate.physicalAboutVersionCheck)"
Write-Host "  Observed label  : $($manifest.finalVersionDisplayCandidate.observedAboutLabel)"

Write-Host ''
Write-Host 'Production closeout:' -ForegroundColor Cyan
Write-Host "  Firebase audit  : $($manifest.production.firebaseProductionAudit)"

Write-Host ''
Write-Host 'Persistent evidence gaps:' -ForegroundColor Cyan
$manifest.persistentEvidenceGaps | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }

Write-Host ''
if ($manifest.acceptedProductBoundary.futureRuntimeWorkLocked) {
    Write-Host 'Future runtime work: LOCKED until owner explicitly unlocks a new batch.' -ForegroundColor Yellow
}

Write-Host ''
Write-Host 'Useful commands:' -ForegroundColor Cyan
Write-Host '  .\tool\restore_official_base.ps1   # restore source to official base'
Write-Host '  .\tool\verify_deployment_gate.ps1  # pre-production deploy safety gate'
Write-Host '  .\tool\audit_production_state.ps1  # detect deployed function drift'
Write-Host '========================================' -ForegroundColor Cyan
