$EventsPath = "$PSScriptRoot\Events.log"
$csvPath = "$PSScriptRoot\MonitoringResult.csv"

$ComputersOnlineDict = @{}
$ComputersOfflineDict = @{}

try {
    $Computers = Get-ADComputer -Filter * -Properties Name | Select-Object Name
} catch {
    Write-Host "$_" -ForegroundColor Red
    exit
}

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

$row = @{}

foreach ($ComputerName in $ComputersOnlineDict.Keys) {
    try {
        $CPU = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 6 -MaxSamples 10).CounterSamples |
            ForEach-Object { $_.CookedValue }
        }

        $RAM = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            (Get-Counter '\Memory\% Committed Bytes In Use' -SampleInterval 6 -MaxSamples 10).CounterSamples |
            ForEach-Object { $_.CookedValue }
        }

        $CPU_Value = [math]::Round(($CPU | Measure-Object -Average).Average)
        $RAM_Value = [math]::Round(($RAM | Measure-Object -Average).Average)

        if (-not (Test-Path $csvPath)) {
            Add-Content -Path $csvPath -Value "Ram usage,Cpu Usage,Date And Time"
        }

        Add-Content -Path $csvPath -Value "$RAM_Value%,$CPU_Value%,$(Get-Date -Format 'MM-dd HH:mm:ss')"
        $row[$ComputerName] = "C=$CPU_Value% ~ R=$RAM_Value%"
    } catch {
        
        $row[$ComputerName] = "Error collecting data"
    }
}

$UsageTable = [PSCustomObject]$row
$UsageTable