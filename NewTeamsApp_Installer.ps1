function Write-Log {

    [CmdletBinding()]

    param (

        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]

        [ValidateNotNullOrEmpty()]

        [Alias("LogContent")]

        [string]$Message,

 

        [Parameter(Mandatory=$true)]

        [Alias('LogPath')]

        [string]$Path,

 

        [Parameter(Mandatory=$false)]

        [ValidateSet("Error","Warn","Info","Success")]

        [string]$Level="Info"

    )

    Begin {}

    Process {

        $LogSize = (Get-Item -Path $Path -ErrorAction SilentlyContinue).Length/1MB

        $MaxLogSize = 5

 

        If ((Test-Path $Path) -AND $LogSize -gt $MaxLogSize){

            Remove-Item $Path -Force

            New-Item $Path -Force -ItemType File

        } ElseIf (!(Test-Path $Path)){

            New-Item $Path -Force -ItemType File

        }

 

        $FormattedDate = Get-Date -Format "MM-dd-yyyy HH:mm:ss"

 

        Switch ($Level) {

            'Error' {

                Write-Error $Message

                $LevelText = 'ERROR:'

            }

            'Warn' {

                Write-Warning $Message

                $LevelText = 'WARNING:'

            }

            'Info' {

                Write-Verbose $Message

                $LevelText = 'INFO:'

            }

            'Success' {

                Write-Verbose $Message

                $LevelText = 'SUCCESS:'

            }

        }

 

        "$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append

    }

 

    End {}

 

}

 

function Remove-TeamsAppXPackages {

 

    Write-Log -LogPath $logPath -Message "Checking for older versions of teams" -Level Info

 

    $oldAppPackages = Get-AppxPackage -name *Teams* -AllUsers

    If ($oldAppPackages) {

        Write-Log -LogPath $logPath -Message "App Packages: Found" -Level Info

        Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like "*teams*" | Remove-ProvisionedAppxPackage -Online

        Get-AppxPackage -name *Teams* -AllUsers | Remove-AppxPackage -AllUsers

        Clear-Variable oldAppPackages

        $oldAppPackages = Get-AppxPackage -name *Teams* -AllUsers

        If (!$oldAppPackages) {

            Write-Log -LogPath $logPath -Message "App Packages: Uninstalled." -Level Success

        } Else {

            Write-Log -LogPath $logPath -Message "App Packages: Present." -Level Error

        }   

    }

   

}

 

function Remove-TeamsMSI {

    $WOW64Uninstall = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object {$_.DisplayName -like "*Teams*"}

    if ($WOW64Uninstall) {

        Write-Log -LogPath $logPath -Message "WOW6432Node Version: Found" -Level Info

        ForEach ($Registry in $WOW64Uninstall) {

            $uninstall = $Registry.UninstallString

            Write-Log -LogPath $logPath -Message "Updating String: $uninstall" -Level Info

            if($uninstall -like "MsiExec.exe /I*") {

                $uninstall = $uninstall.Replace('MsiExec.exe /I','/X"') + '" /qn'

                Write-Log -LogPath $logPath -Message "New Uninstall String: $uninstall" -Level Success

                Start-Process msiexec.exe -ArgumentList "$uninstall" -Wait -NoNewWindow

            } elseif ($uninstall -like "MsiExec.exe /X*") {

                $uninstall = $uninstall.Replace('MsiExec.exe /X','/X"') + '" /qn'

                Write-Log -LogPath $logPath -Message "New Uninstall String: $uninstall" -Level Success

                Start-Process msiexec.exe -ArgumentList "$uninstall" -Wait -NoNewWindow

            } else {

                Start-Process cmd.exe -ArgumentList $uninstall

            }

            Write-Log -LogPath $logPath -Message "Uninstall: Successful" -Level Success

        }

    }

    $SoftwareUninstall = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object {$_.DisplayName -like "*Teams*"}

    if ($SoftwareUninstall) {

        Write-Log -LogPath $logPath -Message "MSI Version: Found" -Level Info

        ForEach ($Registry in $SoftwareUninstall) {

            $uninstall = $Registry.UninstallString

            Write-Log -LogPath $logPath -Message "Updating String: $uninstall" -Level Info

            if($uninstall -like "MsiExec.exe /I*") {

                $uninstall = $uninstall.Replace('MsiExec.exe /I','/X"') + '" /qn'

                Write-Log -LogPath $logPath -Message "New Uninstall String: $uninstall" -Level Success

                Start-Process msiexec.exe -ArgumentList "$uninstall" -Wait -NoNewWindow

            } elseif ($uninstall -like "MsiExec.exe /X*") {

                $uninstall = $uninstall.Replace('MsiExec.exe /X','/X"') + '" /qn'

                Write-Log -LogPath $logPath -Message "New Uninstall String: $uninstall" -Level Success

                Start-Process msiexec.exe -ArgumentList "$uninstall" -Wait -NoNewWindow

            } else {

                Start-Process cmd.exe -ArgumentList $uninstall

            }

            Write-Log -LogPath $logPath -Message "Uninstall: Successful" -Level Success

        }

    }

    New-PSDrive -name hku -root HKEY_USERS -PSProvider Registry | Out-Null

    $userProfiles = Get-Item hku:\* | Where-Object {$_.name -notmatch "s-1-5-19|s-1-5-20|s-1-5-18|Classes|.Default"}

    $UserUninstall = @()

    foreach ($userProfile in $userProfiles.name){

        $userProfile =$userProfile.Replace("HKEY_USERS\", "")

        If (Test-Path -Path "HKU:\$userProfile\Software\Microsoft\Windows\CurrentVersion\Uninstall\"){

            $UserUninstall += Get-ItemProperty -Path "HKU:\$userProfile\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" |  Where-Object {$_.DisplayName -like "*Teams*"} -ErrorAction SilentlyContinue

        }

    }

    if ($UserUninstall) {

        Write-Log -LogPath $logPath -Message "User Version: Found" -Level Info

        ForEach ($Registry in $UserUninstall) {

            $uninstall = $Registry.QuietUninstallString -Split '\s+'

            $uninstallPath = $uninstall[0]

            $argument = " $($uninstall[1]) $($uninstall[2])"

            Start-Process $uninstallPath -ArgumentList $argument -WindowStyle Hidden -Wait

            Write-Log -LogPath $logPath -Message "Uninstall: Successful" -Level Success

        }

    }

   

}

 

$ProgressPreference = 'SilentlyContinue'

$windowsInfo = Get-ComputerInfo -Property OsVersion,CsCaption,CsDomain

$logPath = "$env:SystemRoot\$($windowsInfo.CsDomain)\Logs\" + "MSTeams_Install.log"

$ScriptPath = $PSScriptRoot

Remove-TeamsAppXPackages

 

Remove-TeamsMSI

 

If ($windowsInfo.OsVersion -lt "10.0.19041") {

    Write-Log -LogPath $logPath -Message "Teams Boostrapper: Not Supported (Windows $($windowsInfo.OsVersion))" -Level Error

    Write-Log -LogPath $logPath -Message "Registry: Setting key to allow sideloading apps." -Level Info

    New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowAllTrustedApps" -Value "1" -PropertyType "DWord" -Force

    Write-Log -LogPath $logPath -Message "Attempt: Provisioning teams." -Level Info

    try {

        Add-ProvisionedAppPackage -Online -PackagePath "$ScriptPath\MSTeams-x64.msix" -SkipLicense

        Write-Log -LogPath $logPath -Message "Teams Provisioned" -Level Success

        Exit 2

    } catch {

        Write-Log -LogPath $logPath -Message "Teams Provisioned: Faild" -Level Error

    }

    Write-Log -LogPath $logPath -Message "Teams Installer: Creating Scheduled Task for user base install." -Level info

    $destiination = "$env:windir\$($windowsInfo.CsDomain)\Application\Teams"

    If (!(Test-path -Path $destiination)){

        New-Item -Path $destiination -ItemType Directory -Force

    }

    Move-Item -Path "$ScriptPath\MSTeams-x64.msix" -Destination "$env:windir\$($windowsInfo.CsDomain)\Application\Teams" -Force

    $argument = '-windowstyle hidden -command &{Add-AppXPackage -Path ' + "`"$env:windir\$($windowsInfo.CsDomain)\Application\Teams\MSTeams-x64.msix`" > $null 2>&1}"

    $taskTrigger = New-ScheduledTaskTrigger -AtLogOn

    $taskAction = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument $argument

    $principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Users"

    Register-ScheduledTask -TaskName "New Teams Install (User)" -Action $taskAction -Trigger $taskTrigger -Principal $principal -Force

    if (Get-ScheduledTask -TaskName "New Teams Install (User)") {

        Write-Log -LogPath $logPath -Message "Schedual Task: Created" -Level Info

        Start-ScheduledTask -TaskName "New Teams Install (User)" -AsJob

       Exit 3

    }

}else {

    Write-Log -LogPath $logPath -Message "Installing Teams: All Users" -Level Info

    $argument =" -p -o " + "`"$ScriptPath\MSTeams-x64.msix`""

    Start-Process "$ScriptPath\teamsbootstrapper.exe" -ArgumentList $argument -WindowStyle Hidden -Wait

    if (Get-AppxPackage -name *Teams* -AllUsers){

        Write-Log -LogPath $logPath -Message "Installed Teams: All Users" -Level Success

        Exit 0

    }

    Exit 1

}