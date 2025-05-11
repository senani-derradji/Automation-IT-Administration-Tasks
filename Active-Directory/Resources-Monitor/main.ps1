$EventsPath = "$PSScriptRoot\Events.log"
$ErrorsPath = "$PSScriptRoot\Errors.log"
$csvPath = "$PSScriptRoot\MonitoringResult.csv"

function CheckOnlineDevices {
    $ComputersOnlineDict = @{}
    $ComputersOfflineDict = @{}
    $Computers = Get-ADComputer -Filter * -Property Name
    foreach ($Computer in $Computers) {
        try {
            $ping = Test-Connection $Computer.Name -Count 1 -ErrorAction Stop
            $ComputersOnlineDict[$Computer.Name] = "$($ping.IPV4Address.IPAddressToString) ON"
            Add-Content -Value "$($Computer.Name),ON,$(Get-Date)" -Path $EventsPath
        } catch {
            $ComputersOfflineDict[$Computer.Name] = "$($Computer.Name) OFF"
            Add-Content -Value "$($Computer.Name),OFF,$(Get-Date)" -Path $EventsPath
        }
    }

    return $ComputersOnlineDict
}

while ($true) {
   $ComputersOnlineDict = CheckOnlineDevices
   if ($null -ne $ComputersOnlineDict){
     foreach ($ComputerName in $ComputersOnlineDict.Keys) {
        #write-host $ComputerName
        try {
            $CPU = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 5).CounterSamples |
                    ForEach-Object { $_.CookedValue }
            }

            $RAM = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                (Get-Counter '\Memory\% Committed Bytes In Use' -SampleInterval 1 -MaxSamples 5).CounterSamples |
                    ForEach-Object { $_.CookedValue }
            }

            $Disks = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                $DisksUsage = @{}
                Get-PSDrive -PSProvider FileSystem | ForEach-Object {
                    $DisksUsage[$_.Root] = [math]::Round($_.Free / 1GB, 2)
                }
                return $DisksUsage
            }

            $CPU_Value = [math]::Round(($CPU | Measure-Object -Average).Average)
            $RAM_Value = [math]::Round(($RAM | Measure-Object -Average).Average)

            if (-not (Test-Path $csvPath)) {
                Add-Content -Path $csvPath -Value "Computer, H-Value,H-Alert,H-Processes,Time"
            }

            $DisksUs = $Disks
            $timestamp = Get-Date -Format 'MM-dd HH:mm:ss'

            # CPU Check
            if ($CPU_Value -gt 50) {
                add-Content -Path $EventsPath -Value "CPU Alert : $CPU_Value in $timestamp"
                $First3CpuProcesses = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                    Get-Process | Sort-Object CPU -Descending | Select-Object -First 3 Name, @{Name="CPU_Sec"; Expression={[math]::Round($_.CPU, 2)}}
                }
                $msg = "$ComputerName,$CPU_Value%,CPU alert,$($First3CpuProcesses.Name) : $($First3CpuProcesses.CPU_Sec),$timestamp"
                Write-Host $msg
                Add-Content -Path $csvPath -Value $msg
            }

            # RAM Check
            if ($RAM_Value -gt 70) {
                add-Content -Path $EventsPath -Value "RAM Alert : $RAM_Value in $timestamp"
                $First3RamProcesses = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                    Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 3 Name, @{Name="RAM_MB"; Expression={[math]::Round($_.WorkingSet / 1MB, 2)}}
                }
                $msg = "$ComputerName,$RAM_Value%,RAM alert,$($First3RamProcesses.Name) : $($First3RamProcesses.RAM_MB),$timestamp"
                Write-Host $msg
                Add-Content -Path $csvPath -Value $msg
            }

            # Disk Check
            foreach ($data in $DisksUs.GetEnumerator()) {
                $key = $data.Key
                $Value = $data.Value
                if($value -ne 0){
                if ($Value -lt 10) {
                    add-Content -Path $EventsPath -Value "Disk Alert : Driver ($key) - Free Space ($Value) in $timestamp"
                    $msg = "$ComputerName,Driver $key : Free $Value,Disk Alert,$timestamp"
                    Write-Host $msg
                    Add-Content -Path $csvPath -Value $msg
                }}
            }

        } catch {
            write-host "error to connect"
            Add-Content -Path $ErrorsPath -Value "Error collecting data: $($_.Exception.Message) in $timestamp"
        }
    }
    Start-Sleep -Seconds 300
   }else {
        $msg =  "There is no Online Computers"
        Add-Content -Path $ErrorsPath -Value $msg : $timestamp
        # Write-Host $msg
   }
}