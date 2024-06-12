# A Better MSTeams Installer (Work or School)
A Better MS Teams Installer is meant for organizations that have to install New MS Teams on a wide range of Windows Operating System Versions. If you work at an organization that still use older version of Windows 10/11, that the teamsboostrapper.exe does not support, this script installer will assist you in installing Teams on these machines. By checking to see if any version of Teams is currently installed, the script will uninstall those older versions of Microsoft Teams either by checking the uninstall string in registy or checking the appxpackages and removing them accordingly. Then the script will check the OS version, and determain the best course of action to install the new MS Teams (for work or school). This is done either by using the teamsbootstrapper.exe, provisioning the msix file, or by creating a scheduled task. Let's face it, as Administrators or Engineers, we know that there are times users do something that breaks something on the machine that no one solution can handle. That is why I created this script, to combat all the issues I have ran accross with installing the new MS Teams.

# Requirements:
1) Download Teams x64 - https://go.microsoft.com/fwlink/?linkid=2196106

2) Download Teamsbootstrapper.exe - https://go.microsoft.com/fwlink/?linkid=2243204&clcid=0x409

# Instructions:
1) Host all files (MSTeams-x64.msix, NewTeamsApp_Installer.ps1, and Teamsbootstrapper.exe) in the same folder.

2) Run NewTeamsApp_Installer.ps1 as Admin