param(
  [string]$FirebaseProjectId = "nearmeu-e82c7",
  [switch]$RequireReleaseSigning,
  [switch]$Json
)

$ErrorActionPreference = "Stop"
$results = New-Object System.Collections.Generic.List[object]

function Add-Check {
  param([string]$Name, [bool]$Passed, [string]$Detail, [bool]$Blocking = $true)
  $results.Add([pscustomobject]@{
    name = $Name
    passed = $Passed
    blocking = $Blocking
    detail = $Detail
  })
}

function Test-Command {
  param([string]$Name)
  return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

Add-Check "Git" (Test-Command "git") "Git CLI must be installed."
Add-Check "Flutter" (Test-Command "flutter") "Flutter SDK must be available on PATH."
Add-Check "Node.js" (Test-Command "node") "Node.js 20 is required for Cloud Functions."
Add-Check "npm" (Test-Command "npm") "npm is required for Functions and rules tests."
Add-Check "Java" (Test-Command "java") "Java is required for Firebase emulator tests and Android builds."
Add-Check "Firebase CLI" (Test-Command "firebase") "Firebase CLI is required for production deployment."

$requiredFiles = @(
  "pubspec.yaml",
  "firebase.json",
  ".firebaserc",
  "firestore.rules",
  "firestore.indexes.json",
  "storage.rules",
  "functions/package.json",
  "functions/bootstrap.js",
  "config/project_state_manifest.json",
  "docs/final/NEARMEU_FINAL_BASELINE.md",
  "docs/final/ROADMAP_AND_RELEASE_PLAN.md",
  "docs/final/BACKUP_AND_RECOVERY_PLAN.md"
)
foreach ($file in $requiredFiles) {
  Add-Check "File: $file" (Test-Path $file) "Required tracked project file."
}

if (Test-Path ".firebaserc") {
  $firebaseRc = Get-Content ".firebaserc" -Raw
  Add-Check "Firebase project mapping" ($firebaseRc -match [regex]::Escape($FirebaseProjectId)) "Expected project ID: $FirebaseProjectId"
}

$secretPatterns = @(
  "**/key.properties",
  "**/*.jks",
  "**/*.keystore",
  "**/*service-account*.json",
  "**/*firebase-adminsdk*.json"
)
$trackedSecrets = @()
if (Test-Command "git") {
  $tracked = @(git ls-files)
  foreach ($pattern in $secretPatterns) {
    $wildcard = $pattern.Replace("**/", "*")
    $trackedSecrets += $tracked | Where-Object { $_ -like $wildcard }
  }
}
Add-Check "No tracked signing/admin secrets" ($trackedSecrets.Count -eq 0) ($(if ($trackedSecrets.Count -eq 0) { "No credential-like files tracked." } else { "Tracked: $($trackedSecrets -join ', ')" }))

$signingReady = (Test-Path "android/key.properties") -and (
  (Test-Path Env:NEARMEU_UPLOAD_KEYSTORE_B64) -or
  (Test-Path Env:ANDROID_KEYSTORE_PATH)
)
Add-Check "Release signing locally configured" $signingReady "Required only before signed AAB generation." $RequireReleaseSigning.IsPresent

$ownerValuesReady = -not [string]::IsNullOrWhiteSpace($env:NEARMEU_SUPPORT_EMAIL) -and
                    -not [string]::IsNullOrWhiteSpace($env:NEARMEU_PRIVACY_POLICY_URL) -and
                    -not [string]::IsNullOrWhiteSpace($env:NEARMEU_ACCOUNT_DELETION_URL)
Add-Check "Owner legal values supplied" $ownerValuesReady "Set NEARMEU_SUPPORT_EMAIL, NEARMEU_PRIVACY_POLICY_URL and NEARMEU_ACCOUNT_DELETION_URL before Play submission." $false

$blockingFailures = @($results | Where-Object { $_.blocking -and -not $_.passed })
$report = [pscustomobject]@{
  firebaseProjectId = $FirebaseProjectId
  readyForPreTestDeployment = ($blockingFailures.Count -eq 0)
  blockingFailureCount = $blockingFailures.Count
  checks = $results
}

if ($Json) {
  $report | ConvertTo-Json -Depth 5
} else {
  Write-Host ""
  Write-Host "NearMeU pre-test readiness" -ForegroundColor Cyan
  foreach ($check in $results) {
    $symbol = if ($check.passed) { "PASS" } elseif ($check.blocking) { "FAIL" } else { "TODO" }
    $color = if ($check.passed) { "Green" } elseif ($check.blocking) { "Red" } else { "Yellow" }
    Write-Host ("[{0}] {1} - {2}" -f $symbol, $check.name, $check.detail) -ForegroundColor $color
  }
  Write-Host ""
  if ($report.readyForPreTestDeployment) {
    Write-Host "READY: repository and local tooling satisfy pre-test deployment checks." -ForegroundColor Green
  } else {
    Write-Host "NOT READY: fix blocking checks before production Firebase deployment." -ForegroundColor Red
  }
}

if ($blockingFailures.Count -gt 0) { exit 1 }
