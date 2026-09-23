# PowerShell installer for cf (Choose Folder)
$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Installing cf (Choose Folder) - Windows" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 1. Check Python
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Write-Error "Python 3 is required but not found in PATH. Please install Python from https://www.python.org/ or the Microsoft Store."
    exit 1
}

# 2. Check / Install windows-curses
Write-Host "Checking windows-curses dependency..."
$cursesCheck = python -c "import curses; print('ok')" 2>$null
if ($cursesCheck -ne "ok") {
    Write-Host "Installing windows-curses..." -ForegroundColor Yellow
    pip install windows-curses
    Write-Host "✓ windows-curses installed successfully." -ForegroundColor Green
} else {
    Write-Host "✓ curses support already available." -ForegroundColor Green
}

# 3. Setup Directories
$binDir = Join-Path $HOME ".local\bin\cf"
$dataDir = Join-Path $HOME ".local\share\cf"
if (-not (Test-Path $binDir)) { New-Item -ItemType Directory -Path $binDir -Force | Out-Null }
if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir -Force | Out-Null }

# 4. Copy or Download cf.py
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$targetFile = Join-Path $binDir "cf.py"

if ($scriptDir -and (Test-Path (Join-Path $scriptDir "cf.py"))) {
    Copy-Item (Join-Path $scriptDir "cf.py") -Destination $targetFile -Force
    Write-Host "✓ Installed cf.py to $targetFile" -ForegroundColor Green
} else {
    Write-Host "Downloading cf.py from GitHub..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/nagachaitanyaappana/cf/main/cf.py" -OutFile $targetFile
    Write-Host "✓ Downloaded cf.py to $targetFile" -ForegroundColor Green
}

# 5. Add to PowerShell Profile
$profilePath = $PROFILE
if (-not (Test-Path $profilePath)) {
    $profileDir = Split-Path -Parent $profilePath
    if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force | Out-Null }
    New-Item -ItemType File -Path $profilePath -Force | Out-Null
}

$cfSnippet = @"

# cf (Choose Folder)
function cf {
    `$dir = python "$HOME\.local\bin\cf\cf.py"
    if (`$dir -and (Test-Path `$dir)) {
        Set-Location `$dir
    }
}
"@

$profileContent = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
if ($profileContent -notmatch "function cf") {
    Add-Content -Path $profilePath -Value $cfSnippet
    Write-Host "✓ Added cf function to PowerShell profile: $profilePath" -ForegroundColor Green
} else {
    Write-Host "✓ cf function already exists in PowerShell profile" -ForegroundColor Green
}

# 6. Create CMD batch wrapper (for cmd.exe)
$cmdWrapper = @"
@echo off
for /f "delims=" %%i in ('python "%USERPROFILE%\.local\bin\cf\cf.py"') do (
    if exist "%%i" cd /d "%%i"
)
"@
Set-Content -Path (Join-Path $binDir "cf.cmd") -Value $cmdWrapper -Encoding ASCII
Write-Host "✓ Created Command Prompt wrapper at $(Join-Path $binDir 'cf.cmd')" -ForegroundColor Green

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  Installation Successful! 🎉" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "To start using cf right away, reload your PowerShell profile:"
Write-Host "  . `$PROFILE" -ForegroundColor Yellow
Write-Host "Then simply type: cf"
