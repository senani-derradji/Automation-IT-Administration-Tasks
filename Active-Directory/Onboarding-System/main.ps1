Import-Module ActiveDirectory
. ".\OrganizationalUnitsFunc.ps1"
. ".\GroupsFunc.ps1"
. ".\UsersFunc.ps1"
. ".\SharedFoldersAndMappingDrivs.ps1"

# Ensure FS-Resource-Manager is installed
if ((Get-WindowsFeature -Name FS-Resource-Manager).InstallState -ne 'Installed') { 
    Install-WindowsFeature -Name FS-Resource-Manager -IncludeManagementTools 
}

# Paths
$csvUsersPath = "C:\Users\Administrator\Desktop\users.csv"
$users = Import-Csv -Path $csvUsersPath -Delimiter ','
$DC1 = "derradji"
$DC2 = "com"
$domain = "$DC1.$DC2"
$hostname = HOSTNAME.EXE
$netlogonPath = "\\$hostname\netlogon"
$basePath = "$env:USERPROFILE\Desktop\DERRADJI@SHARED-FOLDERS"
$EventsLogPath = "$env:USERPROFILE\Desktop\Events.log"
$ErrorsLogPath = "$env:USERPROFILE\Desktop\Errors.log"

#Random CHARs
$letters = ([char[]](65..90)) + ([char[]](97..122))
$digits = ([char[]](48..57))
$special = @(
    '.', '@', ',', '?', '!', '#', '$', '%', '&', '*',
    '(', ')', '-', '_', '=', '+', '[', ']', '{', '}',
    ':', ';', '<', '>', '/', '\', '|', '`', '~', '^'
)
$chars = $letters + $digits + $special

# Main command execution function
function Execute-Command {
    param ([string]$command)
    
    $cmdParts = $command.ToLower().Split(' ')
    $mainCmd = $cmdParts[0]
    $target = if ($cmdParts.Count -gt 1) { $cmdParts[1] } else { "all" }

    switch ($mainCmd) {
        "create" {
            switch ($target) {
                "users" {Create-Users }
                "groups" { Create-Groups }
                "ous" { Create-OrganizationalUnits }
                "shares" { Create-OUFoldersAndShares -users $users }
                "drives" { Set-OUDriveMappings }
                "all" { Create-Groups; Create-OrganizationalUnits; Create-Users; Create-OUFoldersAndShares -users $users; Set-OUDriveMappings }
                default { Write-Warning "Unknown target for Create: $target" }
            }
        }
        "delete" {
            switch ($target) {
                "users" { Delete-Users }
                "groups" { Delete-Groups }
                "ous" { Delete-OrganizationalUnits }
                "shares" { Delete-SharedFolder }
                "all" { Delete-Users; Delete-OrganizationalUnits; Delete-Groups; Delete-SharedFolder }
                default { Write-Warning "Unknown target for Delete: $target" }
            }
        }
        "help" {
            Write-Host "Commands Available:
            - Create: Create users, groups, OUs, shares, or drives.
            - Delete: Delete users, groups, OUs, shares, or all.
            - help: Display this help message."
        }
        "exit" {
            Write-Host "Exiting..." -ForegroundColor Red
            Exit-PSSession
        }
        default {
            Write-Host "Unknown command: $command. Type 'Help' for options." -ForegroundColor Yellow
        }
    }
}


# Main loop to continuously prompt for user input and execute commands
while ($true) {
    Write-Host "DERRADJI@SHELL~$ " -ForegroundColor Green -NoNewline
    $cmd = Read-Host
    Execute-Command -command $cmd
}