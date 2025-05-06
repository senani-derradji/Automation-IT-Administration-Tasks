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


# Creation of Organizational Units
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

# Delete Organizational Units (OUs)
function Delete-OrganizationalUnits {
    foreach ($user in $users) {
        try {
            $ouDN = "OU=$($user.OU),DC=$DC1,DC=$DC2"
            if (Get-ADOrganizationalUnit -Filter "Name -eq '$($user.OU)'" -ErrorAction SilentlyContinue) {
                Get-ADOrganizationalUnit -Identity $ouDN | Set-ADObject -ProtectedFromAccidentalDeletion $false -ErrorAction SilentlyContinue
                Remove-ADOrganizationalUnit -Identity $ouDN -Recursive -Confirm:$false -ErrorAction SilentlyContinue
                Write-Host "Deleted OU: $($user.OU)" -ForegroundColor Cyan
            }
        } catch {
            continue
            # Write-Host "Error deleting OU '$($user.OU)': $($_.Exception.Message)" -ForegroundColor Red
            Add-Content -Path $ErrorsLogPath -Value "Error deleting OU '$($user.OU)': $($_.Exception.Message)"
        }
    }
    Add-Content -Path $EventsLogPath -Value "Delete Oru's of $csvUsersPath in $Time"
}
