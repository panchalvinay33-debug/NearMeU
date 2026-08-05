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
if ($currentBranch -ne 'admin/a05-recovery-health-backend') {
  throw "Expected branch admin/a05-recovery-health-backend, found $currentBranch"
}
if (-not [string]::IsNullOrWhiteSpace((& git status --porcelain))) {
  throw 'Working tree must be clean before A05 deployment.'
}

$env:FUNCTIONS_DISCOVERY_TIMEOUT = '60'

Write-Host 'Running NearMeU function tests before A05 deployment...'
npm test --prefix functions
if ($LASTEXITCODE -ne 0) {
  throw 'Function tests failed. A05 deployment stopped.'
}

Write-Host 'Deploying only NearMeU Admin A05 recovery health callable to nearmeu-e82c7...'
firebase deploy `
  --project nearmeu-e82c7 `
  --only 'functions:getAdminRecoveryHealth'
if ($LASTEXITCODE -ne 0) {
  throw 'A05 Admin recovery health deployment failed.'
}

Write-Host 'PASS NearMeU Admin A05 backend deployed.'
