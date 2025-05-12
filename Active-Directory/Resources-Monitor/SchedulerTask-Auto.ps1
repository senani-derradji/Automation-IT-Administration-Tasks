$scriptPath = "$PSScriptRoot\main.ps1"

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$scriptPath`""

$start = (Get-Date).AddSeconds(30)
$interval = New-TimeSpan -Minutes 5
$end = [TimeSpan]::MaxValue

$trigger = New-ScheduledTaskTrigger -Once -At $start -RepetitionInterval $interval -RepetitionDuration $end

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Start the Scheduler Task after 30 Seconds and Every 5 minuts ForEver
Register-ScheduledTask -TaskName "MonitoringDC" -Action $action -Trigger $trigger -Principal $principal -Description "Derradji Monitoring Resources !!"

# To Remove Scheduler Task 
# Unregister-ScheduledTask -TaskName "MonitoringDC" -Confirm:$false

# To get State of This Scheduler Task
#Get-ScheduledTask -TaskName "MonitoringDC"