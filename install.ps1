# PowerShell installer for cf (Choose Folder)
$ErrorActionPreference = "Stop"
Write-Host "Installing cf (Choose Folder) for Windows..." -ForegroundColor Cyan

$pythonExe = $null
$pythonPrefixArgs = @()
$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
if ($pythonCommand -and $pythonCommand.Source) {
    try {
        & $pythonCommand.Source -c "import sys; raise SystemExit(0 if sys.version_info.major -eq 3 else 1)" 2>$null
        if ($LASTEXITCODE -eq 0) { $pythonExe = $pythonCommand.Source }
    } catch {}
}
if (-not $pythonExe) {
    $pyCommand = Get-Command py -ErrorAction SilentlyContinue
    if ($pyCommand -and $pyCommand.Source) {
        try {
            & $pyCommand.Source -3 -c "import sys; print(sys.version_info.major)" 2>$null | Out-Null
            if ($LASTEXITCODE -eq 0) { $pythonExe = $pyCommand.Source; $pythonPrefixArgs = @("-3") }
        } catch {}
    }
}
if (-not $pythonExe) { throw "Python 3 was not found. Install Python 3 and add it to PATH." }
Write-Host "Using Python: $pythonExe" -ForegroundColor Green

& $pythonExe @pythonPrefixArgs -c "import curses" 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Installing windows-curses..." -ForegroundColor Yellow
    & $pythonExe @pythonPrefixArgs -m pip install --user windows-curses
    if ($LASTEXITCODE -ne 0) { throw "Could not install windows-curses." }
}

$binDir = Join-Path $HOME ".local\bin\cf"
$dataDir = Join-Path $HOME ".local\share\cf"
New-Item -ItemType Directory -Path $binDir -Force | Out-Null
New-Item -ItemType Directory -Path $dataDir -Force | Out-Null

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$targetFile = Join-Path $binDir "cf.py"
$sourceFile = if ($scriptDir) { Join-Path $scriptDir "cf.py" } else { $null }
if ($sourceFile -and (Test-Path -LiteralPath $sourceFile -PathType Leaf)) {
    Copy-Item -LiteralPath $sourceFile -Destination $targetFile -Force
} else {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/nagachaitanyaappana/cf/main/cf.py" -OutFile $targetFile
}

$profilePath = $PROFILE
$profileDir = Split-Path -Parent $profilePath
New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
if (-not (Test-Path -LiteralPath $profilePath)) { New-Item -ItemType File -Path $profilePath -Force | Out-Null }
$profileContent = Get-Content -LiteralPath $profilePath -Raw -ErrorAction SilentlyContinue
$beginMarker = "# >>> cf (Choose Folder) >>>"
$endMarker = "# <<< cf (Choose Folder) <<<"
$pythonForProfile = $pythonExe.Replace("'", "''")
$scriptForProfile = $targetFile.Replace("'", "''")
$cfSnippet = @'
# >>> cf (Choose Folder) >>>
function cf {
    $selected = & '__PYTHON__' '__SCRIPT__'
    if ($LASTEXITCODE -eq 0 -and $selected) {
        $selectedPath = ($selected | Select-Object -Last 1).ToString().Trim()
        if (Test-Path -LiteralPath $selectedPath -PathType Container) {
            Set-Location -LiteralPath $selectedPath
        }
    }
}
# <<< cf (Choose Folder) <<<
'@
$cfSnippet = $cfSnippet.Replace("__PYTHON__", $pythonForProfile).Replace("__SCRIPT__", $scriptForProfile)
if ($profileContent -match [regex]::Escape($beginMarker)) {
    $pattern = "(?s)" + [regex]::Escape($beginMarker) + ".*?" + [regex]::Escape($endMarker)
    $profileContent = [regex]::Replace($profileContent, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $cfSnippet })
    Set-Content -LiteralPath $profilePath -Value $profileContent
} else {
    Add-Content -LiteralPath $profilePath -Value ([Environment]::NewLine + $cfSnippet)
}

$cmdWrapper = @'
@echo off
for /f "delims=" %%i in ('python "%USERPROFILE%\.local\bin\cf\cf.py"') do (
    if exist "%%i\." cd /d "%%i"
)
'@
$cmdPath = Join-Path $binDir "cf.cmd"
Set-Content -LiteralPath $cmdPath -Value $cmdWrapper -Encoding ASCII

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathEntries = @($userPath -split ";" | Where-Object { $_ })
if (-not ($pathEntries | Where-Object { $_.TrimEnd("\") -ieq $binDir.TrimEnd("\") })) {
    [Environment]::SetEnvironmentVariable("Path", ((@($pathEntries) + $binDir) -join ";"), "User")
}
$currentEntries = @($env:Path -split ";" | Where-Object { $_ })
if (-not ($currentEntries | Where-Object { $_.TrimEnd("\") -ieq $binDir.TrimEnd("\") })) {
    $env:Path = ((@($currentEntries) + $binDir) -join ";")
}

Write-Host "cf installed successfully." -ForegroundColor Green
Write-Host 'PowerShell: open a new terminal, or run: . $PROFILE' -ForegroundColor Yellow
Write-Host "CMD: open a new Command Prompt and type: cf" -ForegroundColor Yellow
Write-Host "If PowerShell blocks profile scripts, inspect: Get-ExecutionPolicy -List" -ForegroundColor Yellow
Write-Host "The installer does not change your execution policy."
