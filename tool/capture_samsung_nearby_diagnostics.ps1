param(
    [string]$OutputDirectory = "compatibility_reports\samsung_nearby"
)

$ErrorActionPreference = 'Stop'

function Fail([string]$Message) {
    Write-Host "SAMSUNG NEARBY DIAGNOSTICS FAILED: $Message" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    Fail 'adb is not available in PATH.'
}

$devices = @(adb devices | Select-Object -Skip 1 | Where-Object { $_ -match "\tdevice$" })
if ($devices.Count -eq 0) {
    Fail 'No authorized Android device is connected.'
}
if ($devices.Count -gt 1) {
    Fail 'Connect only the Samsung test device for this diagnostic run.'
}

$serial = (($devices[0] -split "\t")[0]).Trim()
$packageId = 'com.nearmeu.nearmeu'
$activity = 'com.nearmeu.nearmeu/.MainActivity'

$manufacturer = (adb -s $serial shell getprop ro.product.manufacturer).Trim()
$model = (adb -s $serial shell getprop ro.product.model).Trim()
$sdk = (adb -s $serial shell getprop ro.build.version.sdk).Trim()
$release = (adb -s $serial shell getprop ro.build.version.release).Trim()

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

Write-Host "Samsung Nearby diagnostics" -ForegroundColor Cyan
Write-Host "Device: $manufacturer $model | Android $release | API $sdk | $serial"
Write-Host ''
Write-Host 'The app will open now.' -ForegroundColor Yellow
Write-Host 'On the phone: open Nearby, tap Refresh, wait for the problem/crash, then return here and press ENTER.' -ForegroundColor Yellow

adb -s $serial shell am force-stop $packageId | Out-Null
adb -s $serial logcat -c | Out-Null
adb -s $serial shell am start -W -n $activity | Out-Host

Read-Host 'After reproducing the Nearby/location problem, press ENTER'

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$prefix = Join-Path $OutputDirectory "samsung-nearby-$timestamp"

adb -s $serial logcat -d -v threadtime | Set-Content -Encoding utf8 "$prefix-logcat.txt"
adb -s $serial shell dumpsys location | Set-Content -Encoding utf8 "$prefix-location.txt"
adb -s $serial shell dumpsys package $packageId | Set-Content -Encoding utf8 "$prefix-package.txt"
adb -s $serial shell dumpsys activity activities | Set-Content -Encoding utf8 "$prefix-activity.txt"
adb -s $serial shell dumpsys meminfo $packageId | Set-Content -Encoding utf8 "$prefix-meminfo.txt"
adb -s $serial shell cmd appops get $packageId | Set-Content -Encoding utf8 "$prefix-appops.txt"

$log = Get-Content "$prefix-logcat.txt" -Raw
$interesting = $log -split "`r?`n" | Where-Object {
    $_ -match 'FATAL EXCEPTION|AndroidRuntime|ANR in|geolocator|geocoding|LocationManager|FusedLocation|SecurityException|PlatformException|com\.nearmeu\.nearmeu|flutter'
}
$interesting | Set-Content -Encoding utf8 "$prefix-interesting.txt"

Write-Host ''
Write-Host 'NearMeU SAMSUNG NEARBY DIAGNOSTICS CAPTURED' -ForegroundColor Green
Write-Host "Primary file: $prefix-interesting.txt"
Write-Host "Full logcat  : $prefix-logcat.txt"
Write-Host "Location dump: $prefix-location.txt"
Write-Host 'Send the interesting.txt file or a screenshot of its final section.' -ForegroundColor Yellow
