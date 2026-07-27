param(
  [string]$FirebaseProjectId = "nearmeu-e82c7",
  [switch]$Apply,
  [switch]$SkipProjectState
)

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

if (-not $Apply) {
  Write-Host "DRY RUN ONLY" -ForegroundColor Yellow
  Write-Host "This command will not deploy anything without -Apply."
}

& "$PSScriptRoot/pre_test_readiness.ps1" -FirebaseProjectId $FirebaseProjectId
if ($LASTEXITCODE -ne 0) { throw "Pre-test readiness checks failed." }

$currentProject = (& firebase use 2>$null | Out-String).Trim()
if ($currentProject -notmatch [regex]::Escape($FirebaseProjectId)) {
  throw "Firebase CLI is not using expected project '$FirebaseProjectId'. Current output: $currentProject"
}

$commands = @(
  "firebase deploy --only firestore:rules,firestore:indexes --project $FirebaseProjectId",
  "firebase deploy --only storage --project $FirebaseProjectId",
  "firebase deploy --only functions --project $FirebaseProjectId"
)

Write-Host ""
Write-Host "Planned production deployment:" -ForegroundColor Cyan
$commands | ForEach-Object { Write-Host "  $_" }

if (-not $Apply) {
  Write-Host ""
  Write-Host "Re-run with -Apply only after confirming billing, backup, Firebase project and maintenance window." -ForegroundColor Yellow
  exit 0
}

$confirmation = Read-Host "Type the exact Firebase project ID '$FirebaseProjectId' to continue"
if ($confirmation -ne $FirebaseProjectId) {
  throw "Deployment cancelled: project confirmation did not match."
}

Write-Host "Deploying Firestore rules and indexes..." -ForegroundColor Cyan
& firebase deploy --only "firestore:rules,firestore:indexes" --project $FirebaseProjectId
if ($LASTEXITCODE -ne 0) { throw "Firestore deployment failed." }

Write-Host "Deploying Storage rules..." -ForegroundColor Cyan
& firebase deploy --only storage --project $FirebaseProjectId
if ($LASTEXITCODE -ne 0) { throw "Storage rules deployment failed." }

Write-Host "Deploying Cloud Functions..." -ForegroundColor Cyan
$env:FUNCTIONS_DISCOVERY_TIMEOUT = "120"
try {
  & firebase deploy --only functions --project $FirebaseProjectId
  if ($LASTEXITCODE -ne 0) { throw "Cloud Functions deployment failed." }
} finally {
  Remove-Item Env:FUNCTIONS_DISCOVERY_TIMEOUT -ErrorAction SilentlyContinue
}

if (-not $SkipProjectState) {
  Write-Host "Storing project-state manifest..." -ForegroundColor Cyan
  Push-Location functions
  try {
    $env:NEARMEU_EXPECTED_FIREBASE_PROJECT_ID = $FirebaseProjectId
    & npm run project-state:store
    if ($LASTEXITCODE -ne 0) { throw "Project-state manifest write failed." }
  } finally {
    Remove-Item Env:NEARMEU_EXPECTED_FIREBASE_PROJECT_ID -ErrorAction SilentlyContinue
    Pop-Location
  }
}

Write-Host ""
Write-Host "DEPLOYMENT COMPLETE." -ForegroundColor Green
Write-Host "Do not enable App Check enforcement until release/debug tokens are verified on physical test devices." -ForegroundColor Yellow
