##classification variables

$PreviousScan = 'C:\ADInvigilator\compare_csv\classificationChange\PrieviousScan'
$NewScan = 'C:\ADInvigilator\compare_csv\classificationChange\NewScan'
$groupOU = "OU=Groups,DC=production,DC=local"
$filename = "classification-changes" + "-" + (Get-Date -Format "dd-MM-yyyy")
$Results = "C:\ADInvigilator\logs\classification-logs\$filename"

## run to get starting group classifications

Function setupClassification {

get-adgroup -filter * -SearchBase $groupOU -Properties * | select Name,classification | sort-object CanonicalName | Export-Csv -Path $PreviousScan

}

##runs classification compare and updates previous scan results

Function runScanClassification {


try { ##error handling

get-adgroup -filter * -SearchBase $groupOU -Properties * | select Name,classification | sort-object CanonicalName | Export-Csv -Path $NewScan
runCompareClassification
get-adgroup -filter * -SearchBase $groupOU -Properties * | select Name,classification | sort-object CanonicalName | Export-Csv -Path $PreviousScan ##updates Previous scan

}
catch { ##error output
Write-Host "An error has occured in the classfication_runScan function" -ForegroundColor red
Write-Host $_ -ForegroundColor red
Write-Log -message 'An error has occured in the classfication_runScan function' -error $_ 
}
}

##classification compare function

Function runCompareClassification {

$oldScan = Import-Csv -Path $PreviousScan
$newScan = Import-Csv -Path $NewScan
$timeStamp = Get-Date -UFormat '%m-%d-%y %H:%M'

try {
## compare old and new scan
Compare-Object $oldScan $newScan -property Name,classification | Group-Object -Property Name |
    ForEach-Object {
        New-Object PSObject -Property @{
        "winlog.event_data.TargetGroupName"=$_.name
        classification_new=($_.group[0].classification) 
        classification_old=($_.group[1].classification)
        'time_stamp' = $timeStamp
        } | export-csv -Path $Results -NoTypeInformation -Append
    } 
}
catch {
$false
Write-Host "An error has occured in the classfication_compare function" -ForegroundColor red
Write-Host $_ -ForegroundColor red
Write-Log -message 'An error has occured in the classfication_compare function' -error $_ 
}

}



 ## adminCount variables

$exportPreviousScan = "C:\ADInvigilator\compare_csv\adminCount\PreviousScan.csv"
$exportNewScan = 'C:\ADInvigilator\compare_csv\adminCount\NewScan.csv'
$filenameAdminCount = "AdminCount-changes" + "-" + (Get-Date -Format "dd-MM-yyyy")
$ResultsAdminCount = "C:\ADInvigilator\logs\admin-count-logs\$filenameAdminCount"

## gets all users with an admin count

function setUpAdminCount {

Get-ADObject -LDAPFilter “(&(admincount=1)(|(objectclass=user)))” -Properties * | select name, created | Export-Csv -Path $exportPreviousScan

}

## admincount compare function

function runScanAdminCount {

try { ##error handling

Get-ADObject -LDAPFilter “(&(admincount=1)(|(objectclass=user)))” -Properties * | select name, created | Export-Csv -Path $exportNewScan
runCompareAdminCount
Get-ADObject -LDAPFilter “(&(admincount=1)(|(objectclass=user)))” -Properties * | select name, created | Export-Csv -Path $exportPreviousScan
}

catch { ##error output
Write-Host "An error has occured in the adminCount_runScan function" -ForegroundColor red
Write-Host $_ -ForegroundColor red
Write-Log -message 'An error has occured in the adminCountn_runScan function' -error $_ 
}


}


function runCompareAdminCount {

try { ##error handling

$PreviousScanAdminCount = Import-CSV -Path "C:\ADInvigilator\compare_csv\adminCount\PreviousScan.csv"
$NewScanAdminCount = Import-CSV -Path "C:\ADInvigilator\compare_csv\adminCount\NewScan.csv"

Compare-Object $PreviousScanAdminCount $NewScanAdminCount -Property Name -PassThru |
ForEach-Object {
        new-object psobject -Property @{
            "event_message" = "WARNING: A user has been added to an Administration group"
            "winlog.event_data.TargetUserName"=$_.name
            "Created" = $_.Created
            
        } | Export-CSV -Path $ResultsAdminCount -NoTypeInformation -Append
    }

}
catch {  ##error output
$false
Write-Host "An error has occured in the adminCount_runCompare function" -ForegroundColor red
Write-Host $_ -ForegroundColor red
Write-Log -message 'An error has occured in the adminCount_runCompare function' -error $_ 

}
}

##error function to write to error log file

function Write-Log {
     [CmdletBinding()]
     param(
         [Parameter()]
         [ValidateNotNullOrEmpty()]
         [string]$message,
 
         [Parameter()]
         [ValidateNotNullOrEmpty()]
         [string]$error
     )

     new-object psobject -Property @{
         
         time = (Get-Date -f g)
         ps_message = $message
         error = $error
         location = "frequent_script.ps1"
     } | Export-Csv -Path "C:\ADInvigilator\ps_error_logs\error.csv" -Append -NoTypeInformation
 
 }


##loop for service

#while($true){
runScanClassification
#runScanAdminCount
#Start-Sleep –Seconds 60
#}



###### unit testing
<#

Describe  'Unit testing' {

    Context 'Checking classification function for errors' {

        It 'no erorrs found' {
            runCompareClassification | Should -Not -Be $false
        }

    }
}

Describe  'Unit testing' {

    Context 'Checking admin count function for errors' {

        It 'no erorrs found' {
            runCompareAdminCount | Should -Not -Be $false
        }

    }
}

#>
