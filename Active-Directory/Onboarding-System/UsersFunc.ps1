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


# Delete Users
function Delete-Users {
    $backupList = @()
    foreach ($user in $users) {
        try {
            if (Get-ADUser -Filter "SamAccountName -eq '$($user.Username)'" -ErrorAction SilentlyContinue) {
                $userData = Get-ADUser -Identity $user.Username -Properties * |
                            Select-Object SamAccountName, GivenName, Surname, Description, Enabled
                $backupList += $userData
                Remove-ADUser -Identity $user.Username -Confirm:$false
                Write-Host "Deleted user: $($user.Username)" -ForegroundColor Green

            }
        } catch {
            Write-Host "Error deleting user '$($user.Username)': $($_.Exception.Message)" -ForegroundColor Red
            Add-Content -Path $ErrorsLogPath -Value "Error deleting user '$($user.Username)': $($_.Exception.Message)"
        }
    }
    MakeBackup
    Add-Content -Path $EventsLogPath -Value "Delete Users of $csvUsersPath in $Time"
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