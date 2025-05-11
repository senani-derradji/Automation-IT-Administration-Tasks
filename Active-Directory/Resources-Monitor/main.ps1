$EventsPath = "$PSScriptRoot\Events.log"
$csvPath = "$PSScriptRoot\MonitoringResult.csv"

$ComputersOnlineDict = @{}
$ComputersOfflineDict = @{}
$Computers = @(
    @{ Name = "DC12" }
)

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

while ($true) {
    foreach ($ComputerName in $ComputersOnlineDict.Keys) {
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
                Add-Content -Path $csvPath -Value "RamUsage,CpuUsage,DisksUsage,Alert,DateAndTime"
            }

            $DisksUs = $Disks
            $timestamp = Get-Date -Format 'MM-dd HH:mm:ss'

            # CPU Check
            if ($CPU_Value -gt 10) {
                $First3CpuProcesses = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                    Get-Process | Sort-Object CPU -Descending | Select-Object -First 3 Name, @{Name="CPU_Sec"; Expression={[math]::Round($_.CPU, 2)}}
                }
                $msg = "$CPU_Value%,CPU alert,$($First3CpuProcesses.Name),$timestamp"
                Write-Host $msg
                Add-Content -Path $csvPath -Value $msg
            }

            # RAM Check
            if ($RAM_Value -gt 40) {
                $First3RamProcesses = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                    Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 3 Name, @{Name="RAM_MB"; Expression={[math]::Round($_.WorkingSet / 1MB, 2)}}
                }
                $msg = "$RAM_Value%,RAM alert,$($First3RamProcesses.Name),$timestamp"
                Write-Host $msg
                Add-Content -Path $csvPath -Value $msg
            }

            # Disk Check
            foreach ($data in $DisksUs.GetEnumerator()) {
                $key = $data.Key
                $Value = $data.Value

                if ($Value -lt 5) {
                    $msg = "Driver $key : Free $Value,Disk Alert,$timestamp"
                    Write-Host $msg
                    Add-Content -Path $csvPath -Value $msg
                }
            }

        } catch {
            Write-Host "Error collecting data: $($_.Exception.Message)"
        }
    }
}