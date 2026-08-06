$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

if (-not (Get-Command node -ErrorAction SilentlyContinue)) { throw 'Node.js is not available on PATH.' }
if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { throw 'npm is not available on PATH.' }
if (-not (Get-Command firebase -ErrorAction SilentlyContinue)) { throw 'Firebase CLI is not available on PATH.' }

$currentBranch = (& git branch --show-current).Trim()
if ($currentBranch -ne 'admin/a08-audit-read-backend') {
  throw "Expected branch admin/a08-audit-read-backend, found $currentBranch"
}
if (-not [string]::IsNullOrWhiteSpace((& git status --porcelain))) {
  throw 'Working tree must be clean before A08 deployment.'
}

$env:FUNCTIONS_DISCOVERY_TIMEOUT = '60'

Write-Host 'Running NearMeU function tests before A08 deployment...'
npm test --prefix functions
if ($LASTEXITCODE -ne 0) { throw 'Function tests failed. A08 deployment stopped.' }

Write-Host 'Deploying only NearMeU Admin A08 audit-read callable...'
firebase deploy --project nearmeu-e82c7 --only 'functions:listAdminAuditEvents'
if ($LASTEXITCODE -ne 0) { throw 'A08 Admin audit deployment failed.' }

Write-Host 'PASS NearMeU Admin A08 backend deployed.'