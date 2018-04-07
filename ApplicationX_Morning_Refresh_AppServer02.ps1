#this variable is sensitive to the order of the services it contains.
$services = @(
"ApplicationX ABC - Common",
"ApplicationX ABC - BHU Process - Common",
"ApplicationX ABC - BHU Process - Custom - Adhoc",
"ApplicationX ABC - BHU Process - Custom - Straight",
"ApplicationX ABC - External",
"ApplicationX ABC - FDS",
"ApplicationX ABC - FDS Invoices",
"ApplicationX ABC - FDS Notices",
"ApplicationX ABC - FDS Payments",
"ApplicationX ABC - FDS Import",
"ApplicationX ABC - BHU Import",
"ApplicationX ABC - BHU Export",
"ApplicationX ABC - BHU Import AUX",
"ApplicationX ABC - BHU EGI",
"ApplicationX ABC - EGI Export"
)


{#Service List - AppServer02P:
#"ApplicationX ABC",
#"ApplicationX ABC - BSP",
#"ApplicationX ABC - ERT Transfer",
#"ApplicationX ABC - POL Export",
#"ApplicationX ABC - POL Import",
#"ApplicationX ABC - POL Transfer",
#"ApplicationX ABC - Common",
#"ApplicationX ABC - GHU",
#"ApplicationX ABC - FDE",
#"ApplicationX ABC - BHU Baseline",
#"ApplicationX ABC - BHU Export",
#"ApplicationX ABC - BHU Import",
#"ApplicationX ABC - BHU Import AUX",
#"ApplicationX ABC - BHU Portal",
#"ApplicationX ABC - BHU PreAudit",
#"ApplicationX ABC - BHU Process",
#"ApplicationX ABC - BHU Process - Common",
#"ApplicationX ABC - BHU Process - Custom - Adhoc",
#"ApplicationX ABC - BHU Process - Custom - Straight",
#"ApplicationX ABC - BHU EGI",
#"ApplicationX ABC - External",
#"ApplicationX ABC - FDS",
#"ApplicationX ABC - FDS Autopay",
#"ApplicationX ABC - FDS BOA",
#"ApplicationX ABC - FDS Import",
#"ApplicationX ABC - FDS Invoices",
#"ApplicationX ABC - FDS Notices",
#"ApplicationX ABC - FDS Payments",
#"ApplicationX ABC - FDS JCT",
#"ApplicationX ABC - FDS JCT Invoices",
#"ApplicationX ABC - FDS JCT Notices",
#"ApplicationX ABC - FDS JCT Payments",
#"ApplicationX ABC - KSYB",
#"ApplicationX ABC - JCT",
#"ApplicationX ABC - JCT Import",
#"ApplicationX ABC - JCT SBC",
#"ApplicationX ABC - WBHP",
#"ApplicationX ABC - WBHP Export",
#"ApplicationX ABC - EGI",
#"ApplicationX ABC - EGI Export",
}

$date = Get-Date -format yyyyMMdd

$runningPIDlist = @()
$hungPIDlist = @()

"Stopping Services"
Stop-Service -nowait -name "ApplicationX*" 

"Archiving Logs"
if(test-path "D:\Logs\ABC"){
New-Item "D:\Logs\ABC\Archive\$date" -type directory
Copy-Item "D:\Logs\ABC\ApplicationX ABC *.xml" "D:\Logs\ABC\Archive\$date"
Remove-Item "D:\Logs\ABC\ApplicationX ABC *.xml" -force
}

if(test-path "D:\Program Files\ApplicationX\Logs"){
New-Item "D:\Program Files\ApplicationX\Logs\Archive\$date" -type directory
Copy-Item "D:\Program Files\ApplicationX\Logs\ApplicationX ABC *.xml" "D:\Program Files\ApplicationX\Logs\Archive\$date"
Remove-Item "D:\Program Files\ApplicationX\Logs\ApplicationX ABC *.xml" -force
}

"2 minute pause for process's to close"
Start-Sleep -s 120

"Building runningPIDlist"
Foreach ($s in $services){
$s
$ServicePID = (get-wmiobject win32_service | where { $_.name -eq $s}).processID
write-host $s " - " $servicePID
if( $ServicePID -ne 0 ){
	$runningPIDlist = $runningPIDlist += $servicePID
	}
}

write-host $runningPIDlist

"Stopping remaining process's"
if($runningPIDlist -ne $null){
Stop-Process $runningPIDlist -Force
}

"Checking for hung process's"
Foreach ($s in $services){
$s
$ServicePID = (get-wmiobject win32_service | where { $_.name -eq $s}).processID
write-host $s " - " $servicePID
if( $ServicePID -ne 0 ){
	$hungPIDlist = $hungPIDlist += $servicePID
	}
}

if($hungPIDlist -ne $null){
wait-process -Id $hungPIDlist -Timeout 120
write-host "Waiting on hung process('s)"
}else{ write-host "No hung process's" }

#pause

"Starting Services"
Foreach ($s in $services){
$s
Start-Service -name $s
}


#pause
"IISresets"
iisreset ApplicationXui01p
iisreset ApplicationXui02p
iisreset ApplicationXrate01p
iisreset ApplicationXrate02p
