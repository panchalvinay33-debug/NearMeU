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

$env:FUNCTIONS_DISCOVERY_TIMEOUT = '60'

Write-Host 'Running NearMeU function tests before A03 deployment...'
npm test --prefix functions
if ($LASTEXITCODE -ne 0) {
  throw 'Function tests failed. A03 deployment stopped.'
}

Write-Host 'Deploying only NearMeU Admin A03 business dashboard callable to nearmeu-e82c7...'
firebase deploy `
  --project nearmeu-e82c7 `
  --only 'functions:getAdminBusinessDashboard'
if ($LASTEXITCODE -ne 0) {
  throw 'A03 Admin business dashboard deployment failed.'
}

Write-Host 'PASS NearMeU Admin A03 backend deployed.'
