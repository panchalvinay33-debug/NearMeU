param(
    [string]$ApkPath = "build\app\outputs\flutter-apk\app-debug.apk",
    [string]$OutputDirectory = "compatibility_reports"
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
    Write-Host "DEVICE COMPATIBILITY TEST FAILED: $Message" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Fail 'adb is not available in PATH.'
}

if (-not (Test-Path $ApkPath)) {
    Fail "APK not found: $ApkPath"
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

$deviceLines = @(adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "\tdevice$" })
if ($deviceLines.Count -eq 0) {
    Fail 'No authorized Android device is connected.'
}

$packageId = 'com.nearmeu.nearmeu'
$activity = 'com.nearmeu.nearmeu/.MainActivity'
$results = @()

foreach ($line in $deviceLines) {
    $serial = ($line -split "\t")[0].Trim()
    Write-Host "Testing $serial ..." -ForegroundColor Cyan

    $manufacturer = (adb -s $serial shell getprop ro.product.manufacturer).Trim()
    $model = (adb -s $serial shell getprop ro.product.model).Trim()
    $sdk = (adb -s $serial shell getprop ro.build.version.sdk).Trim()
    $release = (adb -s $serial shell getprop ro.build.version.release).Trim()
    $abi = (adb -s $serial shell getprop ro.product.cpu.abi).Trim()
    $memLine = (adb -s $serial shell cat /proc/meminfo | Select-String '^MemTotal:' | Select-Object -First 1).ToString().Trim()

    adb -s $serial install -r $ApkPath | Out-Host
    if ($LASTEXITCODE -ne 0) { Fail "APK install failed on $serial" }

    adb -s $serial shell am force-stop $packageId | Out-Null
    adb -s $serial logcat -c | Out-Null
    adb -s $serial shell am start -W -n $activity | Out-Host
    if ($LASTEXITCODE -ne 0) { Fail "App launch failed on $serial" }

    Start-Sleep -Seconds 10

    $ps = adb -s $serial shell ps -A 2>$null
    if (-not $ps) { $ps = adb -s $serial shell ps }
    $alive = (($ps | Out-String) -match [regex]::Escape($packageId))

    $logcat = adb -s $serial logcat -d -v brief
    $fatal = (($logcat | Out-String) -match 'FATAL EXCEPTION') -or (($logcat | Out-String) -match "ANR in $([regex]::Escape($packageId))")

    $result = [ordered]@{
        serial = $serial
        manufacturer = $manufacturer
        model = $model
        androidRelease = $release
        apiLevel = $sdk
        primaryAbi = $abi
        memory = $memLine
        install = 'PASS'
        launch = if ($alive -and -not $fatal) { 'PASS' } else { 'FAIL' }
        processAlive = $alive
        fatalOrAnrDetected = $fatal
        testedAtUtc = (Get-Date).ToUniversalTime().ToString('o')
    }
    $results += [pscustomobject]$result

    $safeName = ($manufacturer + '-' + $model + '-' + $serial) -replace '[^A-Za-z0-9._-]', '_'
    $logcat | Set-Content -Encoding utf8 (Join-Path $OutputDirectory "$safeName-logcat.txt")
    adb -s $serial shell dumpsys activity activities | Set-Content -Encoding utf8 (Join-Path $OutputDirectory "$safeName-activity.txt")
}

$summaryPath = Join-Path $OutputDirectory 'device-compatibility-summary.json'
$results | ConvertTo-Json -Depth 5 | Set-Content -Encoding utf8 $summaryPath
$results | Format-Table -AutoSize

if ($results.launch -contains 'FAIL') {
    Fail "One or more devices failed launch stability. See $summaryPath"
}

Write-Host ''
Write-Host 'NearMeU CONNECTED DEVICE COMPATIBILITY SMOKE PASS' -ForegroundColor Green
Write-Host "Evidence: $summaryPath"
Write-Host 'This validates install/start stability only; functional feature checks still require the Batch08.1 physical matrix.' -ForegroundColor Yellow
