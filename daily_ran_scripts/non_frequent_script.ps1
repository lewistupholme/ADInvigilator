## gets users with no group membership

function getUsersNoGroup {

$filename = "users-nogroups" + "-" + (Get-Date -Format "dd-MM-yyyy")
$results = "C:\ADInvigilator\logs\users-nogroup-logs\$filename"
$UserOU = "CN=Users,DC=production,DC=local"


try { ##error handling

get-ADUser -SearchBase $UserOU -filter "MemberOf -notlike '*'" -Properties * | select cn, DistinguishedName, Created | 
foreach {
        new-object psobject -Property @{
                            "winlog.event_data.TargetUserName" = $_.cn
                             DistinguishedName = $_.DistinguishedName
                             Created = $_.Created
                            }
            } | select "winlog.event_data.TargetUserName",DistinguishedName,Created  | Export-Csv $results -notypeinformation


}
catch { ##error output
$false
Write-Host "An error has occured in the getUsersNoGroup function" -ForegroundColor red
Write-Host $_ -ForegroundColor red
Write-Log -message 'An error has occured in the getUsersNoGroup function' -error $_ 

}
}

## gets a users token size and issues a high or low risk scoring

function getTokenSizeAlerter {

$UserOU = "CN=Users,DC=production,DC=local"
$allUsers = Get-ADUser -SearchBase $UserOU -Filter * | Select Name -ExpandProperty Name 
$filename = "token-warning" + "-" + (Get-Date -Format "dd-MM-yyyy")
$results = "C:\ADInvigilator\logs\token-size-logs\$filename"

try { ##error handling

foreach ($username in $allusers)
{
        # get direct group count
        $directgroups = (get-ADUser -Identity $username -properties * | select -expand memberof).count
        
        # gets the users total group SID count
        $cn = (Get-ADUser $username).DistinguishedName  
        $totalSIDCount = (Get-ADUser -SearchScope Base -SearchBase $cn -LDAPFilter '(objectClass=user)' -Properties tokenGroups | Select-Object `
        -ExpandProperty tokenGroups | Select-Object -ExpandProperty Value).count
            
        # risk scores
        if($totalSIDCount -gt 1000)
		{$riskScore = "High Risk"}
		elseif($totalSIDCount -gt 800)
		{$riskScore = "Medium Risk"}
		elseif($totalSIDCount -lt 500)
		{$riskScore = "Low Risk"}
        
           # Create a custom group object 
            New-Object PSCustomObject -Property @{
                     "winlog.event_data.TargetUserName" = $username.Name
                      status = $riskScore
                      direct_groups = $directgroups
                      nested_groups = $totalSIDCount
                    } | export-csv -Path $results -NoTypeInformation -Append
          
}
}

catch { ##error output
$false
Write-Host "An error has occured in the getTokenSizeAlerter function" -ForegroundColor red
Write-Host $_ -ForegroundColor red
Write-Log -message 'An error has occured in the getTokenSizeAlerter function' -error $_ 
}
}


## gets inactive users

function getInactiveUsers {


$filename = "inactive-users" + "-" + (Get-Date -Format "dd-MM-yyyy")
$results = "C:\ADInvigilator\logs\inactive-user-logs\$filename"
$UserOU = "CN=Users,DC=production,DC=local"
# current date - 7 days
$date = (Get-Date).AddDays(-7)



try { ##error handling

# Checks to see if last login date exceeds 7 days
Get-ADUser -SearchBase $UserOU -Filter {LastLogon -lt $date} -Properties LastLogon |
select-object Name,@{Name="last_login"; Expression={[DateTime]::FromFileTime($_.LastLogon).ToString('g')}} |
foreach {
        new-object psobject -Property @{
                            "winlog.event_data.TargetUserName" = $_.Name
                             last_login = $_.last_login
                             }
            } | select "winlog.event_data.TargetUserName",last_login  | Export-Csv $results -notypeinformation

}
catch { ##error output
$false
Write-Host "An error has occured in the getInactiveUsers function" -ForegroundColor red
Write-Host $_ -ForegroundColor red
Write-Log -message 'An error has occured in the getInactiveUsers function' -error $_
}
}


## gets groups which have been created but have no direct memberships

function getEmptyGroups {

$filename = "empty-groups" + "-" + (Get-Date -Format "dd-MM-yyyy")
$results = "C:\ADInvigilator\logs\empty-group-logs\$filename"
$groupOU = "OU=Groups,DC=production,DC=local"

try { ##error handling

Get-ADGroup -SearchBase $groupOU -filter "Members -notlike '*'" -Properties * | select SamAccountName, classification, whenCreated |
    foreach {
        new-object psobject -Property @{
                            "winlog.event_data.TargetGroupName" = $_.SamAccountName
                             classification = $_.classification
                             whenCreated = $_.whenCreated
                            }
            } | select "winlog.event_data.TargetGroupName",classification,whenCreated  | Export-Csv $results -notypeinformation 


}
catch { ##error output
$false
Write-Host "An error has occured in the getEmptyGroups function" -ForegroundColor red
Write-Host $_ -ForegroundColor red
Write-Log -message 'An error has occured in the getEmptyGroups function' -error $_
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
         location = "master_script.ps1"
     } | Export-Csv -Path "C:\ADInvigilator\ps_error_logs\error.csv" -Append -NoTypeInformation
 
 }




## loop for service

while($true) {
getEmptyGroups
getTokenSizeAlerter
getUsersNoGroup
getInactiveUsers
Start-Sleep –Seconds 86400
}

###### unit testing

<#

Describe  'Unit testing' {

    Context 'Checking users no group function for errors' {

        It 'no erorrs found' {
            getUsersNoGroup | Should -Not -Be $false
        }

    }
}

Describe  'Unit testing' {

    Context 'Checking inactive users function for errors' {

        It 'no erorrs found' {
            getInactiveUsers | Should -Not -Be $false
        }

    }
}

Describe  'Unit testing' {

    Context 'Checking token size function for errors' {

        It 'no erorrs found' {
            getTokenSizeAlerter | Should -Not -Be $false
        }

    }
}


Describe  'Unit testing' {

    Context 'Checking empty groups function for errors' {

        It 'no erorrs found' {
            getEmptyGroups | Should -Not -Be $false
        }

    }
}

#>