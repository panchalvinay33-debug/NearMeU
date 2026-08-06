$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$manifestPath = Join-Path $repoRoot 'config\official_base_manifest.json'
$projectStatePath = Join-Path $repoRoot 'config\project_state_manifest.json'
$startRulesPath = Join-Path $repoRoot 'docs\PROJECT_START_DEPLOYMENT_RULES.md'

if (-not (Test-Path $manifestPath)) { throw 'Missing config/official_base_manifest.json' }
if (-not (Test-Path $projectStatePath)) { throw 'Missing config/project_state_manifest.json' }
if (-not (Test-Path $startRulesPath)) { throw 'Missing docs/PROJECT_START_DEPLOYMENT_RULES.md' }
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$state = Get-Content $projectStatePath -Raw | ConvertFrom-Json
if (-not $state.developmentState.permanentStartAndDeploymentRulesEnabled) { throw 'Permanent project start/deployment governance rule is not enabled.' }

Set-Location $repoRoot
$currentSha = (git rev-parse HEAD 2>$null)
$currentBranch = (git branch --show-current 2>$null)
$dirty = git status --porcelain 2>$null

Write-Host '========================================' -ForegroundColor Cyan
Write-Host ' NearMeU PROJECT STATE' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host 'Operating rule    : PERMANENT START + DEPLOYMENT GOVERNANCE ENABLED' -ForegroundColor Green
Write-Host "Rules document    : $($state.officialTruth.projectStartDeploymentRules)"
Write-Host "Repository        : $($manifest.identity.repository)"
Write-Host "Canonical folder  : $($manifest.identity.canonicalPcWorkspace)"
Write-Host "Firebase project  : $($manifest.identity.firebaseProjectId)"
Write-Host "Android package   : $($manifest.identity.androidApplicationId)"
Write-Host "App version       : $($manifest.identity.versionName)+$($manifest.identity.versionCode)"
Write-Host "Accepted boundary : Batch $($manifest.acceptedProductBoundary.throughBatch)"
Write-Host "Manifest status   : $($manifest.status)"
Write-Host "Official source   : $($manifest.recovery.currentOfficialSourceSha)"
Write-Host "Recovery branch   : $($manifest.identity.recoveryBranch)"
if ($state.ecosystem) {
    Write-Host ''
    Write-Host 'NearMeU ecosystem:' -ForegroundColor Cyan
    Write-Host "  Consumer repo   : $($state.ecosystem.consumerRepository)"
    Write-Host "  Admin repo      : $($state.ecosystem.adminRepository)"
    Write-Host "  Admin package   : $($state.ecosystem.adminAndroidApplicationId)"
    Write-Host "  Shared backend  : $($state.ecosystem.sharedBackendOwnerRepository)"
    Write-Host "  Admin status    : $($state.ecosystem.adminDevelopmentStatus)" -ForegroundColor Yellow
    Write-Host '  Admin branches  : PRESERVE AS REFERENCE while Admin is paused; do not direct-merge/deploy.' -ForegroundColor Yellow
}
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
Write-Host 'Production closeout:' -ForegroundColor Cyan
Write-Host "  Firebase audit  : $($manifest.production.firebaseProductionAudit)"

Write-Host ''
Write-Host 'Persistent evidence gaps:' -ForegroundColor Cyan
$manifest.persistentEvidenceGaps | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }

Write-Host ''
if ($manifest.acceptedProductBoundary.futureRuntimeWorkLocked) {
    Write-Host 'Future runtime work: LOCKED until owner explicitly unlocks a new batch.' -ForegroundColor Yellow
}
if ($state.futureRoadmap -and $state.futureRoadmap.plannedBatches) {
    Write-Host ''
    Write-Host 'Locked future roadmap:' -ForegroundColor Cyan
    $state.futureRoadmap.plannedBatches | ForEach-Object {
        Write-Host ("  Batch {0} - {1} [{2}]" -f $_.id, $_.name, $_.status)
    }
}

Write-Host ''
Write-Host 'Permanent project-start rule:' -ForegroundColor Cyan
Write-Host '  Establish accepted base first -> work on a fresh branch -> never deploy from feature/Admin/history branches.'
Write-Host '  Production Firebase deploys only from clean NearMeU main == origin/main after deployment gate PASS.'
Write-Host '  Production cleanup/deploy is followed by production-state audit before acceptance.'

Write-Host ''
Write-Host 'Useful commands:' -ForegroundColor Cyan
Write-Host '  .\tool\restore_official_base.ps1   # restore source to official base'
Write-Host '  .\tool\verify_deployment_gate.ps1  # pre-production deploy safety gate'
Write-Host '  .\tool\audit_production_state.ps1  # detect deployed function drift'
Write-Host '  docs\PROJECT_START_DEPLOYMENT_RULES.md # permanent project/deployment operating rule'
Write-Host '  docs\NEARMEEU_ECOSYSTEM_BOUNDARY.md    # consumer/Admin ownership and branch rules'
Write-Host '========================================' -ForegroundColor Cyan
