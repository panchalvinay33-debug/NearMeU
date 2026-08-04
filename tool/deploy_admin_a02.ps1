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

# NearMeU loads a large shared function surface during Firebase CLI discovery.
# Firebase defaults discovery to 10 seconds, which is too short on some Windows
# machines even when the function suite is healthy. Firebase documents this
# environment variable as the supported fallback when initialization cannot yet
# be refactored behind onInit().
$previousDiscoveryTimeout = $env:FUNCTIONS_DISCOVERY_TIMEOUT
$env:FUNCTIONS_DISCOVERY_TIMEOUT = '60'

try {
  Write-Host 'Deploying only NearMeU Admin A02 callables to nearmeu-e82c7...'
  firebase deploy `
    --project nearmeu-e82c7 `
    --only 'functions:lookupAdminUser,functions:setUserSuspension,functions:getAdminPremiumEntitlement,functions:setAdminPremiumGrant'
  if ($LASTEXITCODE -ne 0) {
    throw 'A02 Admin callable deployment failed.'
  }
} finally {
  $env:FUNCTIONS_DISCOVERY_TIMEOUT = $previousDiscoveryTimeout
}

Write-Host 'PASS NearMeU Admin A02 backend deployed.'
