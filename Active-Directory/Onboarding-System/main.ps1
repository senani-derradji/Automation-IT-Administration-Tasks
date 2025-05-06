Import-Module ActiveDirectory
. "$PSScriptRoot\OrganizationalUnitsFunc.ps1"
. "$PSScriptRoot\GroupsFunc.ps1"
. "$PSScriptRoot\UsersFunc.ps1"
. "$PSScriptRoot\SharedFoldersAndMappingDrivs.ps1"

# Ensure FS-Resource-Manager is installed
if ((Get-WindowsFeature -Name FS-Resource-Manager).InstallState -ne 'Installed') { 
    Install-WindowsFeature -Name FS-Resource-Manager -IncludeManagementTools 
}

# Paths
$csvUsersPath = "$PSScriptRoot\Data\Data.csv"
$users = Import-Csv -Path $csvUsersPath -Delimiter ','
$DC1 = "derradji"
$DC2 = "com"
$domain = "$DC1.$DC2"
$hostname = HOSTNAME.EXE
$netlogonPath = "\\$hostname\netlogon"
$basePath = "$PSScriptRoot\$DC1@SHARED-FOLDERS"
$EventsLogPath = "$PSScriptRoot\Backup and Logs\Events.log"
$ErrorsLogPath = "$PSScriptRoot\Backup and Logs\Errors.log"

#Random CHARs
$letters = ([char[]](65..90)) + ([char[]](97..122))
$digits = ([char[]](48..57))
$special = @(
    '.', '@', ',', '?', '!', '#', '$', '%', '&', '*',
    '(', ')', '-', '_', '=', '+', '[', ']', '{', '}',
    ':', ';', '<', '>', '/', '\', '|', '`', '~', '^'
)
$chars = $letters + $digits + $special

# Command Dispatcher
function Execute-Command {
    param (
        [string]$command
    )
    switch ($command) {
        "Create" {
            Create-Groups
            Create-OrganizationalUnits
            Create-Users
            Create-OUFoldersAndShares -users $users
            Set-OUDriveMappings
        }
        "Delete" {
            Delete-Users
            Delete-OrganizationalUnits
            Delete-Groups
            Delete-SharedFolder
        }
        "help" {
            Write-Host @"
           Commands Available
-------------------------------------------------
- Create     :     Create groups, users, and OUs.
- Delete     :     Delete groups, users, and OUs.
- help       :     Display this help message.
- exist      :     Exit from the Shell.
- clear      :     Clean the Shell Window.
-------------------------------------------------
"@ -ForegroundColor Cyan
        }
        "clear"{Clear-Host}
        "exit" {
           Write-Host "Salam , See You ...." -ForegroundColor DarkRed
           break
        }
        default {
            Write-Host "Unknown command: $command. Type 'Help' for options." -ForegroundColor Yellow
        }
    }
}

clear-host

while ($true) {
    Write-Host "DERRADJI@SHELL~$ " -ForegroundColor Green -NoNewline
    $cmd = Read-Host
    Execute-Command -command $cmd
}