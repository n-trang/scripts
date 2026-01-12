<#
.SYNOPSIS
    Helper script to install and manage smtp4dev.

.DESCRIPTION
    This script checks for winget and installs smtp4dev if not present.
    It also provides instructions for starting the server.

.EXAMPLE
    .\setup-smtp.ps1
#>

# Check for winget
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Error "winget not found. Please install Windows Package Manager."
    return
}

# Check if smtp4dev is already installed
if (Get-Command smtp4dev -ErrorAction SilentlyContinue) {
    Write-Host "smtp4dev is already installed." -ForegroundColor Green
}
else {
    Write-Host "Installing smtp4dev via winget..." -ForegroundColor Cyan
    winget install Rnwood.Smtp4dev --accept-package-agreements --accept-source-agreements
}

# Create shim for smtp4dev command
$packageDir = "C:\Users\administrator.TN\AppData\Local\Microsoft\WinGet\Packages"
$exe = Get-ChildItem -Path $packageDir -Recurse -Filter "Rnwood.Smtp4dev.exe" | Select-Object -First 1

if ($exe) {
    $exePath = $exe.FullName
    $shimPath = "C:\Users\administrator.TN\AppData\Local\Microsoft\WindowsApps\smtp4dev.bat"
    "@echo off`n`"$exePath`" %*" | Out-File -FilePath $shimPath -Encoding ascii
    Write-Host "Created command shim: smtp4dev" -ForegroundColor Green

    # Configure Persistence via Scheduled Task
    Write-Host "Configuring persistence via Scheduled Task..." -ForegroundColor Cyan
    $taskName = "Smtp4dev_Autostart"
    $action = New-ScheduledTaskAction -Execute $exePath
    $trigger = New-ScheduledTaskTrigger -AtStartup
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -MultipleInstances Parallel
    
    # Unregister if exists
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
    Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -Settings $settings -TaskName $taskName -Description "Runs smtp4dev at startup" | Out-Null
    
    # Start the task now
    Start-ScheduledTask -TaskName $taskName
    Write-Host "Scheduled Task '$taskName' created and started." -ForegroundColor Green
}

Write-Host "`nTo check if the server is running, visit:" -ForegroundColor Yellow
Write-Host "http://localhost:5000" -ForegroundColor White
Write-Host "`nDefault Ports:" -ForegroundColor Gray
Write-Host "- SMTP: 25" -ForegroundColor Gray
Write-Host "- Web UI: 5000" -ForegroundColor Gray
