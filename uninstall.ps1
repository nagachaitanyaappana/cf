# PowerShell uninstaller for cf (Choose Folder)
$ErrorActionPreference = "SilentlyContinue"

Write-Host "Uninstalling cf (Choose Folder)..." -ForegroundColor Yellow

$binDir = Join-Path $HOME ".local\bin\cf"
if (Test-Path $binDir) {
    Remove-Item -Recurse -Force $binDir
    Write-Host "✓ Removed $binDir" -ForegroundColor Green
}

$profilePath = $PROFILE
if (Test-Path $profilePath) {
    $content = Get-Content $profilePath -Raw
    $cleaned = $content -replace "(?ms)# cf \(Choose Folder\).*?function cf \{.*?\}\r?\n?", ""
    Set-Content -Path $profilePath -Value $cleaned
    Write-Host "✓ Removed cf function from PowerShell profile" -ForegroundColor Green
}

Write-Host "Uninstallation complete. Recent folder history in ~/.local/share/cf was kept."
Write-Host "To remove recent history: Remove-Item -Recurse -Force ~\.local\share\cf"
