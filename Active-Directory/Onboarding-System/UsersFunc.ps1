# Create Users and Assign Groups
function Create-Users {
    foreach ($user in $users) {
        $password = ConvertTo-SecureString -String $user.Password -AsPlainText -Force
        $firstName, $lastName = $user.FullName -split ' ', 2
        $ouPath = "OU=$($user.OU),DC=$DC1,DC=$DC2"

        try {
            if (-not (Get-ADUser -Filter "SamAccountName -eq '$($user.Username)'" -ErrorAction SilentlyContinue)) {
                New-ADUser -Name $user.FullName `
                           -SamAccountName $user.Username `
                           -GivenName $firstName `
                           -Surname $lastName `
                           -DisplayName $user.FullName `
                           -AccountPassword $password `
                           -Enabled $true `
                           -Path $ouPath `
                           -Description "Permissions: $($user.Permissions)"
                Write-Host "Created user: $($user.FullName)" -ForegroundColor Green
                #$result = Create-SharedFolderProfile -Name $user.FullName -UserWhoCanAccess $user.Username
                #$allUsersDict[$user.Username] = $result
            }

            switch ($user.Permissions) {
                "Read"   { $group = "Read_Group" }
                "Write" { $group = "Write_Group" }
                "Create" { $group = "Create_Group" }
                "Delete" { $group = "Delete_Group" }
                "Full"   { $group = "Full_Group" }
                default  { $group = $null }
            }

            if ($group -ne $null) {
                Add-ADGroupMember -Identity $group -Members $user.Username
                Write-Host "Added $($user.Username) to group $group" -ForegroundColor Cyan
            }

        } catch {
            Write-Host "Error creating user '$($user.Username)': $($_.Exception.Message)" -ForegroundColor Red
            Add-Content -Path $ErrorsLogPath -Value "Error creating user '$($user.Username)': $($_.Exception.Message)"
        }
    }
    Add-Content -Path $EventsLogPath -Value "Creating Users of $csvUsersPath in $Time"
}

# BackUP for Users
function MakeBackup {
    $backupPath = "$PSScriptRoot\Backup and Logs\DeletedUsers_Backup_$((Get-Date).ToString('yyyyMMddHHmmss')).csv"
    $backupList | Export-Csv -Path $backupPath -NoTypeInformation
    Write-Host "User backup saved to: $backupPath" -ForegroundColor Yellow
    Add-Content -Path $EventsLogPath -Value "Backup of deleted users saved to: $backupPath at $Time"
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
