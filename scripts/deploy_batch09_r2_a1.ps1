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
if ($currentBranch -ne 'batch/09-r2-audio-calling') {
  throw "Expected branch batch/09-r2-audio-calling, found $currentBranch"
}
if (-not [string]::IsNullOrWhiteSpace((& git status --porcelain))) {
  throw 'Working tree must be clean before R2-A deployment.'
}

Write-Host 'Running NearMeU Functions tests before R2-A deployment...'
npm test --prefix functions
if ($LASTEXITCODE -ne 0) {
  throw 'Function tests failed. R2-A deployment stopped.'
}

$targets = @(
  'functions:startAudioCallR2',
  'functions:getAudioCallR2',
  'functions:respondAudioCallR2',
  'functions:endAudioCallR2',
  'functions:expireStaleAudioCallsR2',
  'functions:getAudioRtcAccessR2'
) -join ','

Write-Host 'Deploying only Batch 09 R2-A lifecycle and RTC access functions...'
firebase deploy --project nearmeu-e82c7 --only $targets
if ($LASTEXITCODE -ne 0) {
  throw 'R2-A backend deployment failed.'
}

Write-Host 'PASS Batch 09 R2-A lifecycle and RTC access backend deployed.'
