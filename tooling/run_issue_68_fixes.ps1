$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root

$targets = @(
    'lib/screens/auth_gate_screen.dart',
    'lib/screens/nearby_screen.dart',
    'lib/screens/chats_screen.dart',
    'lib/screens/settings_screen.dart',
    'lib/screens/chat_screen.dart',
    'lib/services/local_chat_store.dart'
)

# Normalize only the files this guarded patch touches. This makes the exact
# source checks deterministic on Windows regardless of Git autocrlf settings.
foreach ($relativePath in $targets) {
    $path = Join-Path $root $relativePath
    $content = Get-Content -Raw -LiteralPath $path
    $normalized = $content.Replace("`r`n", "`n")
    [System.IO.File]::WriteAllText(
        $path,
        $normalized,
        [System.Text.UTF8Encoding]::new($false)
    )
}

$sourcePatch = Join-Path $PSScriptRoot 'apply_issue_68_fixes.ps1'
$tempPatch = Join-Path $env:TEMP 'nearmeu_apply_issue_68_fixes.ps1'
$patchContent = (Get-Content -Raw -LiteralPath $sourcePatch).Replace("`r`n", "`n")
[System.IO.File]::WriteAllText(
    $tempPatch,
    $patchContent,
    [System.Text.UTF8Encoding]::new($false)
)

try {
    & $tempPatch
} finally {
    Remove-Item -LiteralPath $tempPatch -Force -ErrorAction SilentlyContinue
}
