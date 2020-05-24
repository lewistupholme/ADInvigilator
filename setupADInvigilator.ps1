
##installs nssm used to setup services

function installDependencies {
Set-ExecutionPolicy Bypass -Scope Process -Force; `iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install nssm
}

##creates group asset classification compare CSV
Function setupClassification {
$groupOU = "OU=Groups,DC=production,DC=local"
$PreviousScan = 'C:\ADInvigilator\compare_csv\classificationChange\PrieviousScan'
get-adgroup -filter * -SearchBase $groupOU -Properties * | select Name,classification | sort-object CanonicalName | Export-Csv -Path $PreviousScan

}

##creates admin count compare CSV

function setUpAdminCount {
$exportPreviousScan = "C:\ADInvigilator\compare_csv\adminCount\PreviousScan.csv"
Get-ADObject -LDAPFilter “(&(admincount=1)(|(objectclass=user)))” -Properties * | select name, created | Export-Csv -Path $exportPreviousScan

}

##creates daily script as a service using NSSM

function setUpDailyScriptService {
$nssm = (Get-Command nssm).Source
$ScriptPath = 'C:\ADInvigilator\daily_ran_scripts\non_frequent_script.ps1'
$ServiceName = 'ADInvigilator'

$ServicePath = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
$ServiceArguments = '-ExecutionPolicy Bypass -NoProfile -File "{0}"' -f $ScriptPath

& $nssm install $ServiceName $ServicePath $ServiceArguments
Start-Sleep -Seconds .5

# check the status... should be stopped
& $nssm status $ServiceName

# start things up!
& $nssm start $ServiceName

# verify it's running
& $nssm status $ServiceName

}

##creates classification service using NSSM

function setFrequentScriptService {
$nssm = (Get-Command nssm).Source
$ScriptPath = 'C:\ADInvigilator\frequent_ran_scripts\frequent_script.ps1'
$ServiceName = 'ADInvigilator-Frequent'

$ServicePath = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
$ServiceArguments = '-ExecutionPolicy Bypass -NoProfile -File "{0}"' -f $ScriptPath

& $nssm install $ServiceName $ServicePath $ServiceArguments
Start-Sleep -Seconds .5

# check the status... should be stopped
& $nssm status $ServiceName

# start things up!
& $nssm start $ServiceName

# verify it's running
& $nssm status $ServiceName

}

##creates winlogbeat service 

function setUpWinlogbeatService {

# Delete and stop the service if it already exists.
if (Get-Service winlogbeat -ErrorAction SilentlyContinue) {
  $service = Get-WmiObject -Class Win32_Service -Filter "name='winlogbeat'"
  $service.StopService()
  Start-Sleep -s 1
  $service.delete()
}

$workdir = "C:\ADInvigilator\Winlogbeat"

# Create the new service.
New-Service -name winlogbeat `
  -displayName Winlogbeat `
  -binaryPathName "`"$workdir\winlogbeat.exe`" -c `"$workdir\winlogbeat.yml`" -path.home `"$workdir`" -path.data `"C:\ADInvigilator\winlogbeat`" -path.logs `"C:\ADInvigilator\winlogbeat\logs`" -E logging.files.redirect_stderr=true"

# Attempt to set the service to delayed start using sc config.
Try {
  Start-Process -FilePath sc.exe -ArgumentList 'config winlogbeat start= delayed-auto'
  Start-Service winlogbeat
}
Catch { Write-Host -f red "An error occured setting the service to delayed start." }

}

##creates filebeat service

function setUpFilebeatService {

# Delete and stop the service if it already exists.
if (Get-Service filebeat -ErrorAction SilentlyContinue) {
  $service = Get-WmiObject -Class Win32_Service -Filter "name='filebeat'"
  $service.StopService()
  Start-Sleep -s 1
  $service.delete()
}

$workdir = "C:\ADInvigilator\Filebeat"

# Create the new service.
New-Service -name filebeat `
  -displayName Filebeat `
  -binaryPathName "`"$workdir\filebeat.exe`" -c `"$workdir\filebeat.yml`" -path.home `"$workdir`" -path.data `"C:\ADInvigilator\filebeat`" -path.logs `"C:\ADInvigilator\filebeat\logs`" -E logging.files.redirect_stderr=true"

# Attempt to set the service to delayed start using sc config.
Try {
  Start-Process -FilePath sc.exe -ArgumentList 'config filebeat start= delayed-auto'
  Start-Service filebeat
}
Catch { Write-Host -f red "An error occured setting the service to delayed start." }

}


##runs the above functions at setup for ADInvigilator 

installDependencies
Start-Sleep -Second 30
setupClassification
setUpAdminCount
setUpDailyScriptService
setFrequentScriptService
setUpWinlogbeatService
setUpFilebeatService


