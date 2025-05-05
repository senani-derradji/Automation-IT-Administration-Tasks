Import-Module ActiveDirectory
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

# Check if an OU exists before querying users
function Get-OUUsers {
    param (
        [string]$ouDN
    )

    try {
        # Verify if the OU exists in Active Directory
        $ouExists = Get-ADOrganizationalUnit -Filter "distinguishedName -eq '$ouDN'" -ErrorAction SilentlyContinue
        if (-not $ouExists) {
            Write-Host "OU not found: $ouDN" -ForegroundColor Red
            return @()  # Return an empty array if the OU doesn't exist
        }

        # Fetch users from the valid OU
        $users = Get-ADUser -Filter * -SearchBase $ouDN | Select-Object -ExpandProperty SamAccountName
        return $users
    } catch {
        Write-Host "Error fetching users from OU $ouDN : $_" -ForegroundColor Red
        return @()  # Return empty array on error
    }
}

# Create OUs, folders, and shares
function Create-OUFoldersAndShares {
    param ([array]$users)
    
    if (-not ($users | Where-Object { $_.OU -and $_.OU.Trim() })) {
        Write-Warning "No OUs found in users data."
        return
    }

    if (-not (Test-Path $basePath)) {
        New-Item -Path $basePath -ItemType Directory | Out-Null
    }

    $ouMappings = Get-OUs -users $users
    foreach ($ouDN in $ouMappings.Keys) {
        $shareName = $ouMappings[$ouDN]
        $folderPath = Join-Path $basePath $shareName

        if (-not (Test-Path $folderPath)) {
            New-Item -Path $folderPath -ItemType Directory | Out-Null
        }

        # Log the OU and users being fetched
        Write-Host "Fetching users for OU: $ouDN"
        $ouUsers = try {
            Get-ADUser -Filter * -SearchBase $ouDN | Select-Object -ExpandProperty SamAccountName
        } catch {
            Write-Host "Failed to retrieve users for OU: $ouDN. Error: $_" -ForegroundColor Red
            return @()  # Return an empty list to avoid further errors
        }

        Write-Host "Users found for $ouDN : $($ouUsers.Count)" -ForegroundColor Cyan
        # $ouUsers | ForEach-Object { Write-Host $_ }

        # Check if users are found before proceeding
        if ($ouUsers.Count -gt 0) {
            $fullAccessList = @("Administrator") + $ouUsers

            # Create SMB Share with full access for users
            Write-Host "Creating SMB share: $shareName" -ForegroundColor Cyan
            try {
                New-SmbShare -Name $shareName -Path $folderPath -FullAccess $fullAccessList
                Write-Host "Shared folder as: $shareName" -ForegroundColor Green
            } catch {
                Write-Host "Error creating SMB share '$shareName': $_" -ForegroundColor Red
                Add-Content -Path $ErrorsLogPath -Value "Error creating SMB share '$shareName': $_"
            }
        } else {
            Write-Host "No users found for OU: $ouDN, skipping share creation." -ForegroundColor Yellow
        }

        # Apply NTFS permissions
        $acl = New-Object System.Security.AccessControl.DirectorySecurity
        $rights = [System.Security.AccessControl.FileSystemRights]::Read -bor [System.Security.AccessControl.FileSystemRights]::Write `
                  -bor [System.Security.AccessControl.FileSystemRights]::Modify -bor [System.Security.AccessControl.FileSystemRights]::Delete

        foreach ($user in $ouUsers) {
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule($user, $rights, "ContainerInherit,ObjectInherit", "None", "Allow")
            $acl.AddAccessRule($rule)
        }

        $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule("Administrator", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
        $acl.AddAccessRule($adminRule)

        $acl.SetAccessRuleProtection($true, $false)
        Set-Acl -Path $folderPath -AclObject $acl

        Write-Host "Applied NTFS permissions to: $folderPath" -ForegroundColor Cyan
    }
}



# Map OUs to network drives
function Get-OUsAndDriveMappings {
    $driveLetters = @("H:", "I:", "F:", "G:", "J:")
    $ouDriveMappings = @{ }
    $ouFolders = Get-OUs -users $users

    $i = 0
    foreach ($ouDN in $ouFolders.Keys) {
        $shareName = $ouFolders[$ouDN]
        $driveLetter = $driveLetters[$i]
        $sharePath = "\\$hostname\$shareName"

        $ouDriveMappings[$ouDN] = @{
            SharePath   = $sharePath
            DriveLetter = $driveLetter
        }
        $i++
    }

    return $ouDriveMappings
}


# Create drive mappings for users in each OU
function Set-OUDriveMappings {
    $ouDriveMappings = Get-OUsAndDriveMappings
    foreach ($ou in $ouDriveMappings.Keys) {
        $sharePath = $ouDriveMappings[$ou].SharePath
        $driveLetter = $ouDriveMappings[$ou].DriveLetter

        # Get users for the current OU
        $ouUsers = Get-OUUsers -ouDN $ou

        if ($ouUsers.Count -gt 0) {
            foreach ($user in $ouUsers) {
                $username = $user
                $scriptName = "MapDrive_$username.bat"
                $scriptContent = "net use $driveLetter $sharePath /persistent:no"
                $scriptFullPath = Join-Path $netlogonPath $scriptName

                Set-Content -Path $scriptFullPath -Value $scriptContent -Force
                Set-ADUser -Identity $username -ScriptPath $scriptName

                Write-Host "Mapped $driveLetter -> $sharePath to $username" -ForegroundColor Green
            }
        } else {
            Write-Host "No users found for OU: $ou. Skipping drive mapping." -ForegroundColor Yellow
        }
    }
}
function Create-OrganizationalUnits {
    foreach ($user in $users) {
        if ($user.OU) {
            try {
                $ouName = $user.OU
                $ouPath = "DC=$DC1,DC=$DC2"
                $ouDN = "OU=$ouName,$ouPath"

                # Check if OU exists, and create it if not
                if (-not (Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$ouDN)" -ErrorAction SilentlyContinue)) {
                    New-ADOrganizationalUnit -Name $ouName -Path $ouPath
                    Write-Host "Created OU: $ouName" -ForegroundColor Green
                } # else {continue}
            } catch {
                Write-Host "Error creating OU '$($user.OU)': $($_.Exception.Message)" -ForegroundColor Red
                Add-Content -Path $ErrorsLogPath -Value "Error creating OU '$($user.OU)': $($_.Exception.Message)"
            }
        }
    }
}


# Create Users and Assign Groups
$letters = ([char[]](65..90)) + ([char[]](97..122))
$digits = ([char[]](48..57))
$special = @(
    '.', '@', ',', '?', '!', '#', '$', '%', '&', '*',
    '(', ')', '-', '_', '=', '+', '[', ']', '{', '}',
    ':', ';', '<', '>', '/', '\', '|', '`', '~', '^'
)
$chars = $letters + $digits + $special

# Create Users and Assign Groups
function Create-Users {
    foreach ($user in $users) {
        # Ensure the password is set or generate a random one if not present
        if ($user.Password) {
            $password = ConvertTo-SecureString -String $user.Password -AsPlainText -Force
        } else {
            # Generate a random password
            $RandomName = -join (Get-Random -InputObject $chars -Count 10)
            $password = ConvertTo-SecureString -String $RandomName -AsPlainText -Force
        }

        # Split the full name into first and last names
        $firstName, $lastName = $user.FullName -split ' ', 2
        $PhoneNumber = $user.phone

        # Ensure the OU exists and the path is valid
        if ($user.OU) {
            $ouPath = "OU=$($user.OU),DC=$DC1,DC=$DC2"
            Create-OrganizationalUnits
        } else {
            $ouPath = "CN=Users,DC=$DC1,DC=$DC2"
        }

        # Try creating the user
        try {
            # Check if the OU exists before creating the user
            $ouExists = Get-ADOrganizationalUnit -Filter "distinguishedName -eq '$ouPath'" -ErrorAction SilentlyContinue
            if (-not $ouExists) {
                Write-Host "OU does not exist: $ouPath. Skipping user creation." -ForegroundColor Red
                Add-Content -Path $ErrorsLogPath -Value "OU does not exist: $ouPath. Skipping user creation."
                continue  # Skip user creation if the OU doesn't exist
            }

            if (-not (Get-ADUser -Filter "SamAccountName -eq '$($user.Username)'" -ErrorAction SilentlyContinue)) {
                New-ADUser -Name $user.FullName `
                           -SamAccountName $user.Username `
                           -GivenName $firstName `
                           -Surname $lastName `
                           -DisplayName $user.FullName `
                           -AccountPassword $password `
                           -Enabled $true `
                           -Path $ouPath `
                           -Description "$($user.Permissions)" `
                           -ChangePasswordAtLogon $true `
                           -CannotChangePassword $false `
                           -PasswordNeverExpires $false `
                           -EmailAddress "$($user.Username)@$DC1.$DC2" `
                           -OfficePhone $PhoneNumber `
                           -Department $user.OU
                Write-Host "Created user: $($user.FullName)" -ForegroundColor Green
            }
        } catch {
            Write-Host "Error in User Creation: $($_.Exception.Message)" -ForegroundColor Red
            Add-Content -Path $ErrorsLogPath -Value "Error creating user '$($user.Username)': $($_.Exception.Message)"
        }

        # Assign user to the appropriate group if permissions are specified
        if ($user.Permissions) {
            $group = Get-GroupForPermission $user.Permissions
            if ($group) {
                try {
                    Add-ADGroupMember -Identity $group -Members $user.Username
                    Write-Host "Added $($user.Username) to group $group" -ForegroundColor Green
                } catch {
                    Write-Host "Error adding user to group: $($_.Exception.Message)" -ForegroundColor Red
                }
            }
        }
    }
}

# Function to map permissions to groups
function Get-GroupForPermission {
    param ($permission)
    
    switch ($permission) {
        "Read"   { return "Read Group" }
        "Write"  { return "Write Group" }
        "Create" { return "Create Group" }
        "Delete" { return "Delete Group" }
        "Full"   { return "FullControl Group" }
        default  { return $null }
    }
}

# Create AD Groups
function Create-Groups {
    $groups = @("Read Group", "Write Group", "Create Group", "Delete Group", "FullControl Group")
    foreach ($group in $groups) {
        try {
            if (-not (Get-ADGroup -Filter "Name -eq '$group'" -ErrorAction SilentlyContinue)) {
                New-ADGroup -Name $group -GroupScope Global -GroupCategory Security -Path "DC=$DC1,DC=$DC2" -Description "$($group) Permissions Group"
                Write-Host "Created group: $group" -ForegroundColor Green
            }
        } catch {
            Write-Host "Error creating group '$group': $($_.Exception.Message)" -ForegroundColor Red
            Add-Content -Path $ErrorsLogPath -Value "Error creating group '$group': $($_.Exception.Message)"
        }
    }
}

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
    # Display prompt for user input
    Write-Host "DERRADJI@SHELL~$ " -ForegroundColor Green -NoNewline
    
    # Get the command from the user
    $cmd = Read-Host
    
    # Execute the corresponding command based on user input
    Execute-Command -command $cmd
}