$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
Set-Location $root

$targets = @(
    'lib/screens/auth_gate_screen.dart',
    'lib/screens/chat_screen.dart',
    'lib/services/local_chat_store.dart'
)

# Normalize only the files this guarded patch actually touches. This keeps the
# regex behavior deterministic on Windows without creating unrelated diffs.
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

$env:NEARMEU_PROJECT_ROOT = $root
try {
    $sourcePatch = Join-Path $PSScriptRoot 'apply_issue_68_fixes.ps1'
    & $sourcePatch
} finally {
    Remove-Item Env:NEARMEU_PROJECT_ROOT -ErrorAction SilentlyContinue
}
