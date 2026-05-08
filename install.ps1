# Install-Office.ps1 - Interactive Office Deployment Tool Installer
# Usage:
#   Local:  .\install.ps1 (or powershell -ExecutionPolicy Bypass -File .\install.ps1)
#   Remote: powershell -c "irm https://raw.githubusercontent.com/P1N2O/office-deployment-tool/main/install.ps1 | iex"

$ErrorActionPreference = "Stop"

$repoOwner = "P1N2O"
$repoName = "office-deployment-tool"
$branch   = "main"
$baseUrl  = "https://raw.githubusercontent.com/$repoOwner/$repoName/$branch"

# Detect execution context
$scriptPath = $MyInvocation.MyCommand.Path
$isLocal   = ![string]::IsNullOrEmpty($scriptPath) -and (Test-Path $scriptPath -ErrorAction SilentlyContinue)

# --- Admin elevation ---
function Test-Admin {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Admin)) {
    if ($isLocal) {
        $proc = Start-Process PowerShell "-ExecutionPolicy Bypass -NoProfile -File `"$scriptPath`"" -Verb RunAs -PassThru
        $proc.WaitForExit()
        exit $proc.ExitCode
    } else {
        # Running remotely (irm|iex) — download script to temp and relaunch as admin
        $tempDir = Join-Path $env:TEMP "OfficeInstall_$(Get-Date -Format 'yyyyMMddHHmmss')"
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
        $tempScript = Join-Path $tempDir "install.ps1"
        Invoke-WebRequest -Uri "$baseUrl/install.ps1" -OutFile $tempScript -UseBasicParsing
        $proc = Start-Process PowerShell "-ExecutionPolicy Bypass -NoProfile -File `"$tempScript`"" -Verb RunAs -PassThru
        $proc.WaitForExit()
        # Cleanup temp directory after relaunched script finishes (it may have already cleaned)
        Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        exit $proc.ExitCode
    }
}

# --- Now running as admin ---
if ($isLocal) {
    $workDir = Split-Path -Parent $scriptPath
} else {
    # If we're here, we were remote but somehow already admin (unlikely) or were relaunched from temp
    # Check if scriptPath is set (if relaunched, it will be)
    if (![string]::IsNullOrEmpty($scriptPath) -and (Test-Path $scriptPath)) {
        $workDir = Split-Path -Parent $scriptPath
    } else {
        # Fallback: create a new temp directory
        $workDir = Join-Path $env:TEMP "OfficeInstall_Runtime"
        New-Item -ItemType Directory -Path $workDir -Force | Out-Null
    }
}

$setupExe = Join-Path $workDir "setup.exe"
$xmlSource = Join-Path $workDir "office365.xml"

# Download missing files
if (-not (Test-Path $setupExe)) {
    Write-Host "Downloading setup.exe ..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "$baseUrl/setup.exe" -OutFile $setupExe -UseBasicParsing
}
if (-not (Test-Path $xmlSource)) {
    Write-Host "Downloading office365.xml ..." -ForegroundColor Cyan
    Invoke-WebRequest -Uri "$baseUrl/office365.xml" -OutFile $xmlSource -UseBasicParsing
}

# Read original XML template
$originalXml = Get-Content $xmlSource -Raw

# App definitions (must match IDs in office365.xml)
$apps = @(
    @{ Name = "Word";       ID = "Word";       Checked = $true },
    @{ Name = "Excel";      ID = "Excel";      Checked = $true },
    @{ Name = "PowerPoint"; ID = "PowerPoint"; Checked = $true },
    @{ Name = "Outlook";    ID = "Outlook";    Checked = $true },
    @{ Name = "OneNote";    ID = "OneNote";    Checked = $true },
    @{ Name = "Publisher";  ID = "Publisher";  Checked = $true },
    @{ Name = "Access";     ID = "Access";     Checked = $true }
)

$cursor = 0
$appsCount = $apps.Count
$menuRendered = $false
$menuTop = 0

function Render-Menu {
    if ($script:menuRendered) {
        # Update only the lines that changed - no clearing
        for ($i = 0; $i -lt $appsCount; $i++) {
            [Console]::SetCursorPosition(0, $script:menuTop + $i)
            $marker = if ($i -eq $cursor) { ">" } else { " " }
            $check  = if ($apps[$i].Checked) { "[X]" } else { "[ ]" }
            $color  = if ($i -eq $cursor) { "Yellow" } else { "White" }
            Write-Host ("  $marker $check {0,-12} " -f $apps[$i].Name) -ForegroundColor $color
        }
        [Console]::SetCursorPosition(0, $script:menuTop + $appsCount + 1)
        $color = if ($cursor -eq $appsCount) { "Green" } else { "White" }
        Write-Host "  [INSTALL]" -ForegroundColor $color
    } else {
        Clear-Host
        Write-Host "" -ForegroundColor Cyan
        Write-Host "   ___   ______    _________  
 .'   `.|_   _ `. |  _   _  | 
/  .-.  \ | | `. \|_/ | | \_| 
| |   | | | |  | |    | |     
\  `-'  /_| |_.' /   _| |_    
 `.___.'|______.'   |_____|" -ForegroundColor Cyan
        Write-Host "" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  Use UP/DOWN arrows to navigate, SPACE to toggle, ENTER to proceed"
        Write-Host ""
        $script:menuTop = [Console]::CursorTop
        for ($i = 0; $i -lt $appsCount; $i++) {
            $marker = if ($i -eq $cursor) { ">" } else { " " }
            $check  = if ($apps[$i].Checked) { "[X]" } else { "[ ]" }
            $color  = if ($i -eq $cursor) { "Yellow" } else { "White" }
            Write-Host "  $marker $check $($apps[$i].Name)" -ForegroundColor $color
        }
        Write-Host ""
        $color = if ($cursor -eq $appsCount) { "Green" } else { "White" }
        Write-Host "  [INSTALL]" -ForegroundColor $color
        Write-Host ""
        $script:menuRendered = $true
    }
}

function Build-Xml($selectedApps) {
    $xml = $originalXml
    foreach ($app in $apps) {
        $id = $app.ID
        $xml = $xml -replace "<!-- <ExcludeApp ID=`"$id`" /> -->", "<ExcludeApp ID=`"$id`" />"
    }
    foreach ($app in $selectedApps) {
        $id = $app.ID
        $xml = $xml -replace "<ExcludeApp ID=`"$id`" />", "<!-- <ExcludeApp ID=`"$id`" /> -->"
    }
    return $xml
}

Render-Menu

while ($true) {
    $key = $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    switch ($key.VirtualKeyCode) {
        38 { # Up arrow
            if ($cursor -gt 0) { $cursor-- }; Render-Menu
        }
        40 { # Down arrow
            if ($cursor -lt $appsCount) { $cursor++ }; Render-Menu
        }
        32 { # Space
            if ($cursor -lt $appsCount) {
                $apps[$cursor].Checked = !$apps[$cursor].Checked
                Render-Menu
            }
        }
        13 { # Enter
            if ($cursor -eq $appsCount) {
                # Proceed
                Clear-Host
                $selected = $apps | Where-Object { $_.Checked }
                if ($selected.Count -eq 0) {
                    Write-Host "No apps selected. Exiting." -ForegroundColor Yellow
                    Start-Sleep 2
                    exit 0
                }
                Write-Host "Selected apps: $($selected.Name -join ', ')" -ForegroundColor Green
                Write-Host "`nGenerating configuration..." -ForegroundColor Cyan

                $tempXml = Join-Path $env:TEMP "office365-install-$(Get-Date -Format 'yyyyMMddHHmmss').xml"
                $newXml = Build-Xml $selected
                Set-Content -Path $tempXml -Value $newXml -Encoding UTF8

                Write-Host "Starting Office Deployment Tool..." -ForegroundColor Cyan
                & $setupExe /configure $tempXml

                Write-Host "`nCleaning up..." -ForegroundColor Gray
                Remove-Item $tempXml -Force -ErrorAction SilentlyContinue
                exit 0
            } elseif ($cursor -lt $appsCount) {
                $apps[$cursor].Checked = !$apps[$cursor].Checked
                Render-Menu
            }
        }
    }
}
