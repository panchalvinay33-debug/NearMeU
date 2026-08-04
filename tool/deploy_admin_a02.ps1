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

Write-Host 'Running NearMeU function tests before A02 deployment...'
npm test --prefix functions
if ($LASTEXITCODE -ne 0) {
  throw 'Function tests failed. A02 deployment stopped.'
}

Write-Host 'Deploying only NearMeU Admin A02 callables to nearmeu-e82c7...'
firebase deploy `
  --project nearmeu-e82c7 `
  --only 'functions:lookupAdminUser,functions:setUserSuspension,functions:getAdminPremiumEntitlement,functions:setAdminPremiumGrant'
if ($LASTEXITCODE -ne 0) {
  throw 'A02 Admin callable deployment failed.'
}

Write-Host 'PASS NearMeU Admin A02 backend deployed.'
