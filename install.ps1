# Windows installer for cf (Choose Folder)
$ErrorActionPreference = "Stop"

Write-Host "Installing cf (Choose Folder) for Windows" -ForegroundColor Cyan

# Resolve one Python 3 interpreter and use it consistently for all operations.
$pythonCommand = Get-Command python -ErrorAction SilentlyContinue
$pythonArgs = @()
if (-not $pythonCommand -or -not $pythonCommand.Source -or $pythonCommand.Source -like "*\WindowsApps\*") {
    $pythonCommand = Get-Command py -ErrorAction SilentlyContinue
    if ($pythonCommand -and $pythonCommand.Source) {
        $pythonExe = $pythonCommand.Source
        $pythonArgs = @("-3")
    } else {
        throw "Python 3 was not found. Install it from https://www.python.org/downloads/windows/ and enable Add python.exe to PATH."
    }
} else {
    $pythonExe = $pythonCommand.Source
}

$pythonVersion = & $pythonExe @pythonArgs -c "import sys; print(sys.version_info.major)"
if ($LASTEXITCODE -ne 0 -or $pythonVersion -ne "3") { throw "The selected launcher did not start Python 3." }

Write-Host "Checking curses support..."
$cursesCheck = & $pythonExe @pythonArgs -c "import curses; print('ok')" 2>$null
if ($LASTEXITCODE -ne 0 -or $cursesCheck -notcontains "ok") {
    Write-Host "Installing windows-curses for the selected interpreter..." -ForegroundColor Yellow
    & $pythonExe @pythonArgs -m pip install windows-curses
    if ($LASTEXITCODE -ne 0) { throw "Could not install windows-curses. Run: python -m pip install windows-curses" }
    & $pythonExe @pythonArgs -c "import curses"
    if ($LASTEXITCODE -ne 0) { throw "windows-curses installed but curses still cannot be imported." }
}
Write-Host "Python and curses are ready." -ForegroundColor Green

$binDir = Join-Path $HOME ".local\bin\cf"
$dataDir = Join-Path $HOME ".local\share\cf"
New-Item -ItemType Directory -Path $binDir -Force | Out-Null
New-Item -ItemType Directory -Path $dataDir -Force | Out-Null

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
$sourceFile = Join-Path $scriptDir "cf.py"
$targetFile = Join-Path $binDir "cf.py"
if (Test-Path -LiteralPath $sourceFile -PathType Leaf) {
    Copy-Item -LiteralPath $sourceFile -Destination $targetFile -Force
} else {
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/nagachaitanyaappana/cf/main/cf.py" -OutFile $targetFile
}
if (-not (Test-Path -LiteralPath $targetFile -PathType Leaf)) { throw "cf.py was not installed at $targetFile" }
Write-Host "Installed cf.py to $targetFile" -ForegroundColor Green

# Replace only cf's managed profile block; never change execution policy here.
$profilePath = $PROFILE
New-Item -ItemType Directory -Path (Split-Path -Parent $profilePath) -Force | Out-Null
if (-not (Test-Path -LiteralPath $profilePath)) { New-Item -ItemType File -Path $profilePath -Force | Out-Null }

$pythonForProfile = $pythonExe.Replace("'", "''")
$cfSnippet = @'
# >>> cf (Choose Folder) >>>
function cf {
    $pythonExe = '__CF_PYTHON__'
    $pythonArgs = __CF_PYARGS__
    $cfScript = Join-Path $HOME '.local\bin\cf\cf.py'
    $selected = & $pythonExe @pythonArgs $cfScript
    if ($LASTEXITCODE -eq 0 -and $selected) {
        $target = ($selected | Select-Object -Last 1).ToString().Trim()
        if (Test-Path -LiteralPath $target -PathType Container) {
            Set-Location -LiteralPath $target
        }
    }
}
# <<< cf (Choose Folder) <<<
'@
$pythonArgsText = if ($pythonArgs.Count -gt 0) { "@('-3')" } else { "@()" }
$cfSnippet = $cfSnippet.Replace("__CF_PYTHON__", $pythonForProfile).Replace("__CF_PYARGS__", $pythonArgsText)

$profileContent = Get-Content -LiteralPath $profilePath -Raw -ErrorAction SilentlyContinue
if ($null -eq $profileContent) { $profileContent = "" }
$managedBlock = '(?ms)^# >>> cf \(Choose Folder\) >>>\r?\n.*?^# <<< cf \(Choose Folder\) <<<\r?\n?'
$profileContent = [regex]::Replace($profileContent, $managedBlock, "")
$legacyBlock = '(?ms)^# cf \(Choose Folder\)\r?\nfunction cf \{.*?^\}\r?\n?'
$profileContent = [regex]::Replace($profileContent, $legacyBlock, "")
Set-Content -LiteralPath $profilePath -Value ($profileContent.TrimEnd() + [Environment]::NewLine + [Environment]::NewLine + $cfSnippet + [Environment]::NewLine) -Encoding UTF8
Write-Host "Updated PowerShell profile: $profilePath" -ForegroundColor Green

# Create CMD wrapper and add its folder to the current-user PATH.
$cmdWrapper = Join-Path $binDir "cf.cmd"
# Use the same interpreter selected above; %~dp0 keeps the script path independent
# of the caller's working directory and avoids relying on PATH resolution.
$cmdCommand = '"' + $pythonExe + '" ' + ($pythonArgs -join " ") + ' "%~dp0cf.py"'
$cmdContent = @"
@echo off
for /f "delims=" %%i in ('$cmdCommand') do (
    if exist "%%i\\." cd /d "%%i"
)
"@
Set-Content -LiteralPath $cmdWrapper -Value $cmdContent -Encoding ASCII

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$pathEntries = @($userPath -split ";" | Where-Object { $_ })
if (-not ($pathEntries | Where-Object { $_.TrimEnd("\") -ieq $binDir.TrimEnd("\") })) {
    [Environment]::SetEnvironmentVariable("Path", ((@($pathEntries) + $binDir) -join ";"), "User")
}
if (-not ($env:Path -split ";" | Where-Object { $_.TrimEnd("\") -ieq $binDir.TrimEnd("\") })) {
    $env:Path = $env:Path.TrimEnd(";") + ";" + $binDir
}
Write-Host "Installed CMD wrapper and added $binDir to your user PATH." -ForegroundColor Green

Write-Host ""
Write-Host "Installation complete." -ForegroundColor Green
Write-Host "PowerShell: restart the terminal, then run cf."
Write-Host "CMD: open a new Command Prompt, then run cf."
Write-Host "Python used: $pythonExe"

$policy = Get-ExecutionPolicy -Scope CurrentUser
if ($policy -eq "Restricted" -or $policy -eq "AllSigned") {
    Write-Host ""
    Write-Host "Your CurrentUser execution policy is '$policy'; PowerShell may block your profile." -ForegroundColor Yellow
    Write-Host "If you trust your local profile scripts, you can allow them for this account with:"
    Write-Host "  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned"
    Write-Host "The installer did not change your execution policy."
}
