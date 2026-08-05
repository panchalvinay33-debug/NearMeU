$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  throw 'Node.js is not available on PATH.'
}
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
  throw 'npm is not available on PATH.'
}
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) {
  throw 'Firebase CLI is not available on PATH.'
}

$currentBranch = (& git branch --show-current).Trim()
if ($currentBranch -ne 'admin/a06-messaging-health-backend') {
  throw "Expected branch admin/a06-messaging-health-backend, found $currentBranch"
}
if (-not [string]::IsNullOrWhiteSpace((& git status --porcelain))) {
  throw 'Working tree must be clean before A06 deployment.'
}

$env:FUNCTIONS_DISCOVERY_TIMEOUT = '60'

Write-Host 'Running NearMeU function tests before A06 deployment...'
npm test --prefix functions
if ($LASTEXITCODE -ne 0) {
  throw 'Function tests failed. A06 deployment stopped.'
}

Write-Host 'Deploying declared Firestore indexes required by A06...'
firebase deploy `
  --project nearmeu-e82c7 `
  --only 'firestore:indexes'
if ($LASTEXITCODE -ne 0) {
  throw 'A06 Firestore index deployment failed.'
}

Write-Host 'Deploying only NearMeU Admin A06 messaging health callable...'
firebase deploy `
  --project nearmeu-e82c7 `
  --only 'functions:getAdminMessagingHealth'
if ($LASTEXITCODE -ne 0) {
  throw 'A06 Admin messaging health deployment failed.'
}

Write-Host 'PASS NearMeU Admin A06 backend deployed.'
