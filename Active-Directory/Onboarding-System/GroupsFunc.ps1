# Create Groups
function Create-Groups {
    foreach ($group in $groups) {
        try {
            if (-not (Get-ADGroup -Filter "Name -eq '$group'" -ErrorAction SilentlyContinue)) {
                New-ADGroup -Name $group `
                            -GroupScope Global `
                            -GroupCategory Security `
                            -Path "DC=$DC1,DC=$DC2" `
                            -Description "$group Permissions Group"
                Write-Host "Created group: $group" -ForegroundColor Green
            }
        } catch {
            Write-Host "Error creating group '$group': $($_.Exception.Message)" -ForegroundColor Red
            Add-Content -Path $ErrorsLogPath -Value "Error creating group '$group': $($_.Exception.Message)"
        }
    }
}



# Delete Groups
function Delete-Groups {
    foreach ($group in $groups) {
        try {
            if (Get-ADGroup -Filter "Name -eq '$group'" -ErrorAction SilentlyContinue) {
                Remove-ADGroup -Identity $group -Confirm:$false
                Write-Host "Deleted group: $group" -ForegroundColor Green
            }
        } catch {
            Write-Host "Error deleting group '$group': $($_.Exception.Message)" -ForegroundColor Red
            Add-Content -Path $ErrorsLogPath -Value "Error deleting group '$group': $($_.Exception.Message)"
        }
    }
    Add-Content -Path $EventsLogPath -Value "Delete Groups of $groups in $Time"
}
