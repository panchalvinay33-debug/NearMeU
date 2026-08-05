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
if ($currentBranch -ne 'admin/a07-system-health-backend') {
  throw "Expected branch admin/a07-system-health-backend, found $currentBranch"
}
if (-not [string]::IsNullOrWhiteSpace((& git status --porcelain))) {
  throw 'Working tree must be clean before A07 deployment.'
}

$env:FUNCTIONS_DISCOVERY_TIMEOUT = '60'

Write-Host 'Running NearMeU function tests before A07 deployment...'
npm test --prefix functions
if ($LASTEXITCODE -ne 0) {
  throw 'Function tests failed. A07 deployment stopped.'
}

Write-Host 'Deploying only NearMeU Admin A07 system-health callable...'
firebase deploy `
  --project nearmeu-e82c7 `
  --only 'functions:getAdminSystemHealth'
if ($LASTEXITCODE -ne 0) {
  throw 'A07 Admin system health deployment failed.'
}

Write-Host 'PASS NearMeU Admin A07 backend deployed.'
