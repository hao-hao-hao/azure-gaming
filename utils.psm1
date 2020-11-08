[Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
$webClient = new-object System.Net.WebClient

function Disable-InternetExplorerESC {
    # From https://stackoverflow.com/questions/9368305/disable-ie-security-on-windows-server-via-powershell
    $AdminKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}"
    $UserKey = "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}"
    Set-ItemProperty -Path $AdminKey -Name "IsInstalled" -Value 0 -Force
    Set-ItemProperty -Path $UserKey -Name "IsInstalled" -Value 0 -Force
    Stop-Process -Name Explorer -Force
    Write-Output "IE Enhanced Security Configuration (ESC) has been disabled." -ForegroundColor Green
}

function Install-Chocolatey {
    Write-Output "Installing Chocolatey"
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    chocolatey feature enable -n allowGlobalConfirmation
}

function Update-Windows {
    $url = "https://gallery.technet.microsoft.com/scriptcenter/Execute-Windows-Update-fc6acb16/file/144365/1/PS_WinUpdate.zip"
    $compressed_file = "PS_WinUpdate.zip"
    $update_script = "PS_WinUpdate.ps1"

    Write-Output "Downloading Windows Update Powershell Script from $url"
    $webClient.DownloadFile($url, "$PSScriptRoot\$compressed_file")
    Unblock-File -Path "$PSScriptRoot\$compressed_file"

    Write-Output "Extracting Windows Update Powershell Script"
    Expand-Archive "$PSScriptRoot\$compressed_file" -DestinationPath "$PSScriptRoot\" -Force

    Write-Output "Running Windows Update"
    Invoke-Expression $PSScriptRoot\$update_script
}

function Update-Firewall {
    Write-Output "Enable ICMP Ping in Firewall."
    Set-NetFirewallRule -DisplayName "File and Printer Sharing (Echo Request - ICMPv4-In)" -Enabled True
}

function Disable-Defender {
    Write-Output "Disable Windows Defender real-time protection."
    Set-MpPreference -DisableRealtimeMonitoring $true
}

function Disable-ScheduledTasks {
    Write-Output "Disable unnecessary scheduled tasks"
    Disable-ScheduledTask -TaskName 'ScheduledDefrag' -TaskPath '\Microsoft\Windows\Defrag'
    Disable-ScheduledTask -TaskName 'ProactiveScan' -TaskPath '\Microsoft\Windows\Chkdsk'
    Disable-ScheduledTask -TaskName 'Scheduled' -TaskPath '\Microsoft\Windows\Diagnosis'
    Disable-ScheduledTask -TaskName 'SilentCleanup' -TaskPath '\Microsoft\Windows\DiskCleanup'
    Disable-ScheduledTask -TaskName 'WinSAT' -TaskPath '\Microsoft\Windows\Maintenance'
    Disable-ScheduledTask -TaskName 'Windows Defender Cache Maintenance' -TaskPath '\Microsoft\Windows\Windows Defender'
    Disable-ScheduledTask -TaskName 'Windows Defender Cleanup' -TaskPath '\Microsoft\Windows\Windows Defender'
    Disable-ScheduledTask -TaskName 'Windows Defender Scheduled Scan' -TaskPath '\Microsoft\Windows\Windows Defender'
    Disable-ScheduledTask -TaskName 'Windows Defender Verification' -TaskPath '\Microsoft\Windows\Windows Defender'
}

function Edit-VisualEffectsRegistry {
    Write-Output "Adjust performance options in registry"
    New-Item -Path "Registry::\HKEY_USERS\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    Set-ItemProperty -Path "Registry::\HKEY_USERS\.DEFAULT\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2
}

function Install-NvidiaDriver ($manual_install) {
    Write-Output "Installing Nvidia Driver"
    $driver_file = "nvidia-driver.exe"
    $version = "391.03"
    $url = "http://us.download.nvidia.com/Windows/Quadro_Certified/$version/$version-quadro-grid-desktop-notebook-win10-64bit-international-whql.exe"

    Write-Output "Downloading Nvidia M60 driver from URL $url"
    $webClient.DownloadFile($url, "$PSScriptRoot\$driver_file")

    Write-Output "Installing Nvidia M60 driver from file $PSScriptRoot\$driver_file"
    Start-Process -FilePath "$PSScriptRoot\$driver_file" -ArgumentList "-s", "-noreboot" -Wait
    Start-Process -FilePath "C:\NVIDIA\$version\setup.exe" -ArgumentList "-s", "-noreboot" -Wait
}

function Disable-Devices {
    $url = "https://gallery.technet.microsoft.com/PowerShell-Device-60d73bb0/file/147248/2/DeviceManagement.zip"
    $compressed_file = "DeviceManagement.zip"
    $extract_folder = "DeviceManagement"

    Write-Output "Downloading Device Management Powershell Script from $url"
    $webClient.DownloadFile($url, "$PSScriptRoot\$compressed_file")
    Unblock-File -Path "$PSScriptRoot\$compressed_file"

    Write-Output "Extracting Device Management Powershell Script"
    Expand-Archive "$PSScriptRoot\$compressed_file" -DestinationPath "$PSScriptRoot\$extract_folder" -Force

    Write-Output "Disabling Hyper-V Video"
    Import-Module "$PSScriptRoot\$extract_folder\DeviceManagement.psd1"
    Get-Device | Where-Object -Property Name -Like "Microsoft Hyper-V Video" | Disable-Device -Confirm:$false
}

function Disable-TCC {
    $nvsmi = "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe"
    $gpu = & $nvsmi --format=csv,noheader --query-gpu=pci.bus_id
    & $nvsmi -g $gpu -fdm 0
}

function Enable-Audio {
    Write-Output "Enabling Audio Service"
    Set-Service -Name "Audiosrv" -StartupType Automatic
    Start-Service Audiosrv
}

function Install-VirtualAudio {
    $compressed_file = "VBCABLE_Driver_Pack43.zip"
    $driver_folder = "VBCABLE_Driver_Pack43"

    Write-Output "Downloading Virtual Audio Driver"
    $webClient.DownloadFile("https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack43.zip", "$PSScriptRoot\$compressed_file")
    Unblock-File -Path "$PSScriptRoot\$compressed_file"

    Write-Output "Extracting Virtual Audio Driver"
    Expand-Archive "$PSScriptRoot\$compressed_file" -DestinationPath "$PSScriptRoot\$driver_folder" -Force

}


function Disable-IPv6To4 {
    Set-Net6to4Configuration -State disabled
    Set-NetTeredoConfiguration -Type disabled
    Set-NetIsatapConfiguration -State disabled
}


function Install-NSSM {
    Write-Output "Installing NSSM for launching services that run apps at startup"
    choco install nssm --force
}

function Install-Chrome{
    Write-Output "Installing Chrome"
    $Path = $env:TEMP; $Installer = "chrome_installer.exe"; Invoke-WebRequest "http://dl.google.com/chrome/install/375.126/chrome_installer.exe" -OutFile $Path\$Installer; Start-Process -FilePath $Path\$Installer -Args "/silent /install" -Verb RunAs -Wait; Remove-Item $Path\$Installer
}

function Install-Parsec{
    choco install parsec -y --force
}

function Install-Epic{
    choco install epicgameslauncher -y --force
}

function Install-Steam {
    choco install steam -y --force
}

function Install-UPlay{
    choco install uplay -y --force
}

function Set-ScheduleWorkflow ($admin_username, $admin_password, $manual_install) {
    $script_name = "setup2.ps1"
    $url = "https://raw.githubusercontent.com/ecalder6/azure-gaming/master/$script_name"

    Write-Output "Downloading second stage setup script from $url"
    $webClient.DownloadFile($url, "C:\$script_name")

    $powershell = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $service_name = "SetupSecondStage"
    Write-Output "Creating a service $service_name to finish setting up"
    $cmd = "-ExecutionPolicy Unrestricted -NoProfile -File C:\$script_name -admin_username `"$admin_username`" -admin_password `"$admin_password`""
    if ($manual_install) {
        $cmd = -join ($cmd, " -manual_install")
    }

    nssm install $service_name $powershell $cmd
    nssm set $service_name Start SERVICE_AUTO_START
    nssm set $service_name AppExit 0 Exit
}

function Disable-ScheduleWorkflow {
    $service_name = "SetupSecondStage"
    nssm remove $service_name confirm
}

function Add-DisconnectShortcut {
    # From https://stackoverflow.com/questions/9701840/how-to-create-a-shortcut-using-powershell
    Write-Output "Create disconnect shortcut on the desktop"

    $WshShell = New-Object -comObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut("C:\Users\Public\Desktop\disconnect.lnk")
    $Shortcut.TargetPath = "C:\Windows\System32\tscon.exe"
    $Shortcut.Arguments = "1 /dest:console"
    $Shortcut.Save()
}

function Add-AutoLogin ($admin_username, $admin_password) {
    Write-Output "Make the password and account of admin user never expire."
    Set-LocalUser -Name $admin_username -PasswordNeverExpires $true -AccountNeverExpires

    Write-Output "Make the admin login at startup."
    $registry = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
    Set-ItemProperty $registry "AutoAdminLogon" -Value "1" -type String
    Set-ItemProperty $registry "DefaultDomainName" -Value "$env:computername" -type String
    Set-ItemProperty $registry "DefaultUsername" -Value $admin_username -type String
    Set-ItemProperty $registry "DefaultPassword" -Value $admin_password -type String
}
