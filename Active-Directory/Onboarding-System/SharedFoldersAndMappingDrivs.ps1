# Create Shared Folders
function Create-OUFoldersAndShares {
    param (
        [Parameter(Mandatory)]
        [array]$users
    )
    
    if (-not (Test-Path $basePath)) {
        New-Item -Path $basePath -ItemType Directory | Out-Null
    }

    $ouMappings = Create-AndShareFolderOFOU -users $users

    foreach ($ouDN in $ouMappings.Keys) {
        $shareName = $ouMappings[$ouDN]
        $folderPath = Join-Path $basePath $shareName

        if (-not (Test-Path $folderPath)) {
            New-Item -Path $folderPath -ItemType Directory | Out-Null
            Write-Host "Created folder: $folderPath"
        } else {
            Write-Host "Folder already exists: $folderPath"
        }
        #New-FsrmQuotaTemplate -Name "10GB_$RandomName" -Description "Limits to 10GB" -Size 10GB
        #New-FsrmQuota -Path $folderPath -Template "10GB_$RandomName"
        $ouUsers = Get-ADUser -Filter * -SearchBase $ouDN | Select-Object -ExpandProperty SamAccountName

        if (-not (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue)) {
            $fullAccessList = @("Administrator") + $ouUsers
            New-SmbShare -Name $shareName -Path $folderPath -FullAccess $fullAccessList
            Write-Host "Shared folder as: $shareName"
        }

        $acl = New-Object System.Security.AccessControl.DirectorySecurity
        $rights = [System.Security.AccessControl.FileSystemRights]::Read `
            -bor [System.Security.AccessControl.FileSystemRights]::Write `
            -bor [System.Security.AccessControl.FileSystemRights]::Modify `
            -bor [System.Security.AccessControl.FileSystemRights]::Delete
        foreach ($user in $ouUsers) {
            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                $user,
                $rights,
                "ContainerInherit,ObjectInherit",
                "None",
                "Allow"
            )
            $acl.AddAccessRule($rule)
        }

        $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "Administrator",
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.AddAccessRule($adminRule)

        $acl.SetAccessRuleProtection($true, $false)
        Set-Acl -Path $folderPath -AclObject $acl

        Write-Host "Reset and applied NTFS permissions to: $folderPath"
    }
}



function GetOusAndShareNamesAndDrivLetter {
$driveLetters = @("H:", "I:", "F:", "G:", "J:") # More if needed
$ouDriveMappings = @{}
$ouFolders = Create-AndShareFolderOFOU -users $users

$i = 0
foreach ($ouDN in $ouFolders.Keys) {
    $shareName = $ouFolders[$ouDN]
    Write-Host $shareName
    $sharePath = "\\$hostname\$shareName"
    Write-Host $sharePath
    $driveLetter = $driveLetters[$i]

    $ouDriveMappings[$ouDN] = @{
        SharePath   = $sharePath
        DriveLetter = $driveLetter
    }
    Write-Host $ouDriveMappings[$ouDN]

    $i++
}
return $ouDriveMappings
}


function Set-OUDriveMappings {
    Import-Module ActiveDirectory

    # Define OU-to-share mapping
    $ouDriveMappings = GetOusAndShareNamesAndDrivLetter

    foreach ($ou in $ouDriveMappings.Keys) {
        $sharePath   = $ouDriveMappings[$ou].SharePath
        $driveLetter = $ouDriveMappings[$ou].DriveLetter

        # Get users in this OU
        $users = Get-ADUser -Filter * -SearchBase $ou

        foreach ($user in $users) {
            $username = $user.SamAccountName
            $scriptName = "MapDrive_$username.bat"
            $scriptContent = "net use $driveLetter $sharePath /persistent:no"
            $scriptFullPath = Join-Path $netlogonPath $scriptName

            # Write logon script to NetLogon share
            Set-Content -Path $scriptFullPath -Value $scriptContent -Force

            # Set user's logon script
            Set-ADUser -Identity $username -ScriptPath $scriptName

            Write-Host "Assigned $driveLetter -> $sharePath to $username with script $scriptName"
        }
    }
}

# Delete Shared Folders
function Delete-SharedFolder {
    $excludedShares = @("ADMIN$", "C$", "D$", "E$", "F$", "IPC$", "NETLOGON", "SYSVOL")
    $shares = Get-SmbShare | Where-Object { $excludedShares -notcontains $_.Name }
    foreach ($share in $shares) {
        try {
            Remove-SmbShare -Name $($share.Name) -Force -Confirm:$false
            write-host "$($share.Name) are Removed" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to remove share: $($share.Name) - $_"
        }
    }

    if (Test-Path -Path $basePath) {
        
        try {
            Remove-Item -Path $basePath -Recurse -Force
            Write-Host "Folder : $basePath are Removed" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to remove folder: $basePath - $_"
        }
    } else {
        Write-Host "Folder does not exist: $basePath"
    }
}