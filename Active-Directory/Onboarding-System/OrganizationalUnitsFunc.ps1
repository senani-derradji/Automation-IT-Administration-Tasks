# Create OU's
function Create-OrganizationalUnits {
    foreach ($user in $users) {
        try {
            $ouName = $user.OU
            $ouPath = "DC=$DC1,DC=$DC2"
            $ouDN = "OU=$ouName,$ouPath"
            if (-not (Get-ADOrganizationalUnit -LDAPFilter "(distinguishedName=$ouDN)" -ErrorAction SilentlyContinue)) {
                New-ADOrganizationalUnit -Name $ouName -Path $ouPath
                Write-Host "Created OU: $ouName" -ForegroundColor Green

            }
        
        } catch {
            Write-Host "Error creating OU '$($user.OU)': $($_.Exception.Message)" -ForegroundColor Red
            Add-Content -Path $ErrorsLogPath -Value "Error creating OU '$($user.OU)': $($_.Exception.Message)"
        }
        
    }
}

# Get OU's
function Create-AndShareFolderOFOU {
    param (
        [Parameter(Mandatory)]
        [array]$users
    )

    $ouDict = @{}

    $users | Select-Object -ExpandProperty OU -Unique | ForEach-Object {
        $ouName = $_.Trim()
        if ($ouName) {
            $dn = "OU=$ouName,DC=$DC1,DC=$DC2"
            $shareName = "${ouName}Share"
            $ouDict[$dn] = $shareName
        }
    }

    return $ouDict
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
