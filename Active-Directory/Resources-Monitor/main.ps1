# Path's
$EventsPath = "$PSScriptRoot\Events.log"
$ErrorsPath = "$PSScriptRoot\Errors.log"
$csvPath = "$PSScriptRoot\MonitoringResult.csv"

# Loop Time Checking
Write-Host "Time of Checking (seconds) :" -ForegroundColor Green -NoNewline
$LoopTime = Read-Host

# This Function For Checking On/Off Computers and Return On Computers
function CheckOnlineDevices {

    $ComputersOnlineDict = @{}
    $ComputersOfflineDict = @{}
    $Computers = Get-ADComputer -Filter * -Property Name # Get All Computers

    # If You Have Special Servers Put it Here
    if (-not ($Computers)){
           $Computers = @{
           Name = "DC12"
           }
    }

    foreach ($Computer in $Computers) {
        
        # Test Connection is This Computer Support PS Remoting or Not ?
        try {
            $ping = Test-Connection $Computer.Name -Count 1 -ErrorAction Stop
            $ComputersOnlineDict[$Computer.Name] = "$($ping.IPV4Address.IPAddressToString) ON"
            Add-Content -Value "$($Computer.Name),ON,$(Get-Date)" -Path $EventsPath
        } 
        catch {
            $ComputersOfflineDict[$Computer.Name] = "$($Computer.Name) OFF"
            Add-Content -Value "$($Computer.Name),OFF,$(Get-Date)" -Path $EventsPath
        }
    }
    return $ComputersOnlineDict
}

# Start Checking with While True Func
while ($true) {
   $ComputersOnlineDict = CheckOnlineDevices

   # Make Sure Online Dict not Empty
   if ($ComputersOnlineDict -ne $null){
     foreach ($ComputerName in $ComputersOnlineDict.Keys) {
        write-host "$ComputerName Checking ...." -ForegroundColor Green
        try {
            $Informations = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
                
                # Get CPU and RAM Percent /100 | get 1 Percent 5 Times
                $CPU = (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 5).CounterSamples |ForEach-Object { $_.CookedValue }
                $RAM = (Get-Counter '\Memory\% Committed Bytes In Use' -SampleInterval 1 -MaxSamples 5).CounterSamples |ForEach-Object { $_.CookedValue }
                
                # Make The Average Of 5 Times Percent
                $CPU_Value = [math]::Round(($CPU | Measure-Object -Average).Average)
                $RAM_Value = [math]::Round(($RAM | Measure-Object -Average).Average)

                # Get Disk Free Size in GB
                $DisksUsage = @{}
                Get-PSDrive -PSProvider FileSystem | ForEach-Object {
                    $DisksUsage[$_.Root] = [math]::Round($_.Free / 1GB, 2)
                }

                # Get First 3 Tasks (We Need This Vars When we Check if CPU, Ram Values is Risky)
                $First3CpuProcesses = Get-Process | Sort-Object CPU -Descending | Select-Object -First 3 Name, @{Name="CPU_Sec"; Expression={[math]::Round($_.CPU, 2)}}
                $First3RamProcesses = Get-Process | Sort-Object WorkingSet -Descending | Select-Object -First 3 Name, @{Name="RAM_MB"; Expression={[math]::Round($_.WorkingSet / 1MB, 2)}}

   
                return [PSCustomObject]@{
                       CPU_Value = $CPU_Value
                       RAM_Value = $RAM_Value
                       DiskUsage = $DisksUsage
                       First3CpuProcesses =  $First3CpuProcesses
                       First3RamProcesses =  $First3RamProcesses
                }
            }

            
            # Monitoring File .csv
            if (-not (Test-Path $csvPath)) {
                Write-Host "There is no Monitoring Result File !!" -ForegroundColor Red
                Add-Content -Path $csvPath -Value "Computer, H-Value,H-Alert,H-Processes,Time"
                Write-Host "Create It Successfully !! " -ForegroundColor Green
            }

            # Time Of Operation or Task Check
            $timestamp = Get-Date -Format 'MM-dd HH:mm:ss'


            # CPU Check
            if ($Informations.CPU_Value -gt 50) {
                add-Content -Path $EventsPath -Value "CPU Alert : $($Informations.CPU_Value) in $timestamp"
                $msg = "$ComputerName,$CPU_Value%,CPU alert,$($Informations.First3CpuProcesses.Name) : $($Informations.First3CpuProcesses.CPU_Sec),$timestamp"
                Write-Host $msg -BackgroundColor Red
                Add-Content -Path $csvPath -Value $msg
            }
            else{
                Write-Host "$ComputerName CPU is Alright !" -BackgroundColor Green
            }

            
            # RAM Check
            if ($Informations.RAM_Value -gt 50) {
                add-Content -Path $EventsPath -Value "RAM Alert : $($Informations.RAM_Value) in $timestamp"
                $msg = "$ComputerName,$RAM_Value%,RAM alert,$($Informations.First3RamProcesses.Name) : $($Informations.First3RamProcesses.RAM_MB),$timestamp"
                Write-Host $msg -BackgroundColor Red
                Add-Content -Path $csvPath -Value $msg
            }
            else{
                Write-Host "$ComputerName RAM is Alright !" -BackgroundColor Green
            }


            # Disk Check
            $DisksUs = $Informations.DiskUsage
            foreach ($data in $DisksUs.GetEnumerator()) {
                $key = $data.Key
                $Value = $data.Value
                if($value -ne 0){
                    if ($Value -lt 10) {
                        add-Content -Path $EventsPath -Value "Disk Alert : ($key) : ($Value) in $timestamp"
                        $msg = "$ComputerName,Driver $key : Free $Value,Disk Alert,$timestamp"
                        Write-Host $msg -BackgroundColor Red
                        Add-Content -Path $csvPath -Value $msg
                    }else{ Write-Host "$ComputerName DISK Space is Alright !" -BackgroundColor Green }
                }
            }

        } catch {
            write-host "Error to connect"
            Add-Content -Path $ErrorsPath -Value "Error collecting data: $($_.Exception.Message) in $timestamp"
        }
      }
    # Sleep ....
    Start-Sleep -Seconds $LoopTime
    }else {
       $msg =  "There is no Online Computers"
       Add-Content -Path $ErrorsPath -Value $msg : $timestamp
       Write-Host $msg -ForegroundColor Red
    }
}