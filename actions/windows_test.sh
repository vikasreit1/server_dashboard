xenApp
################################################################################################
## XenAppServerHealthCheck
## Jason Poyner, jason.poyner@deptive.co.nz, techblog.deptive.co.nz
## 21 March 2013
## v2.7
## Thanks to Andreas Wegener for additions to this script.
##
## The script checks the health of a XenApp 6.x farm and e-mails two reports. The full farm
## health report is attached to the e-mail and any errors encountered are in an html report
## embedded in the email body.
## This script checks the following:
##   - Ping response
##   - Logon enabled
##   - Assigned Load Evaluator
##   - Active sessions
##   - ICA port response 
##   - CGP port response (session reliability)
##   - WMI response (to check for WMI corruption)
##   - Citrix IMA, Citrix XML, Citrix Print Manager and Spooler services
##   - Server uptime (to ensure scheduled reboots are occurring)
##   - Server folder path and worker group memberships are report for informational purposes
##   - PVS vDisk and write cache file size
## 
## Change history:
##   2.7 - Fixed bug with Check Services 
##   2.6 - Added support for unique load evaluators and PVS vDisks per server silo (based on 
##         server folder path). This functionality is in the $allSiloInfo hash table data 
##         structure.
##   2.5 - Added support for Cache in device RAM overflow to disk PVS option, now queries running 
##         services once for each server speeding up the script.
##   2.4 - Changed default Load Evaluator to handle multiple values; updated Ping routine to be 
##         more robust.
## 
## TO DO
##   - Rewrite for XA/XD 7.x!!
##   - Add unique user count
##   - Move per environment variable data to an XML file
##   - PVS server health check
##   - Incorporate Medvac??
## 
## You are free to use this script in your environment but please e-mail me any improvements.
################################################################################################
if ((Get-PSSnapin "Citrix.XenApp.Commands" -EA silentlycontinue) -eq $null) {
	try { Add-PSSnapin Citrix.XenApp.Commands -ErrorAction Stop }
	catch { write-error "Error loading XenApp Powershell snapin"; Return }
}
 
# Change the below variables to suit your environment
#==============================================================================================
# Default load evaluator assigned to servers. Can have multiple values in format "LE1", "LE2",
# if a match is made to ANY of the listed LEs SUCCESS is returned for the LE check.
$defaultLE       = "Servers"

# Default PVS vDisk assigned to servers
$defaultVDisk    = "XA6_Desktop_1"

# Relative path to the PVS vDisk write cache file
$PvsWriteCache   = "d$\.vdiskcache"
$PvsWriteCache2  = "d$\vdiskdif.vhdx"

# Maximum size of the local PVS write cache file
$PvsWriteMaxSize = 8gb # size in GB

# Servers in the excluded folders will not be included in the health check
$excludedFolders = @("Servers/Test","Servers/Turned Off")
 
# We always schedule reboots on XenApp farms, usually on a weekly basis. Set the maxUpTimeDays
# variable to the maximum number of days a XenApp server should be up for.
$maxUpTimeDays = 7

# E-mail report details
$emailFrom     = "XenAppFarmReport@acme.co.nz"
$emailTo       = "citrix.admins@acme.co.nz"
$smtpServer    = "mail.acme.co.nz"
$emailSubject  = ("XenApp Farm Report - " + (Get-Date -format R))

# Silo info
$allSiloInfo = @{}
$siloInfo    = @{}
# Uncomment the below to enable silo support
# Copy the below four line as many time as required - once for each silo to be supported.
#$siloInfo.name  = "Servers/Production"
#$siloInfo.LE    = "Productions Servers"
#$siloInfo.vDisk = "XA6_Desktop_1"
#$allSiloInfo.($siloInfo.name) = $siloInfo

# Only change this if you have changed the Session Reliability port from the default of 2598
$sessionReliabilityPort = "2598"

#==============================================================================================
 
$currentDir = Split-Path $MyInvocation.MyCommand.Path
$logfile    = Join-Path $currentDir ("XenAppServerHealthCheck.log")
$resultsHTM = Join-Path $currentDir ("XenAppServerHealthCheckResults.htm")
$errorsHTM  = Join-Path $currentDir ("XenAppServerHealthCheckErrors.htm")
 
$headerNames  = "FolderPath", "WorkerGroups", "ActiveSessions", "ServerLoad", "Ping", "Logons", "LoadEvaluator", "ICAPort", "CGPPort", "IMA", "CitrixPrint", "WMI", "XML", "Spooler", "Uptime", "WriteCacheSize", "vDisk"
$headerWidths = "6",          "6",            "4",              "4",          "4",    "6",      "6",             "4",       "6",                  "4",   "4",           "4",   "4",   "4",       "5",      "4",              "4"

#==============================================================================================
function LogMe() {
	Param(
		[parameter(Mandatory = $true, ValueFromPipeline = $true)] $logEntry,
		[switch]$display,
		[switch]$error,
		[switch]$warning,
		[switch]$progress
	)


	if ($error) {
		$logEntry = "[ERROR] $logEntry" ; Write-Host "$logEntry" -Foregroundcolor Red}
	elseif ($warning) {
		Write-Warning "$logEntry" ; $logEntry = "[WARNING] $logEntry"}
	elseif ($progress) {
		Write-Host "$logEntry" -Foregroundcolor Green}
	elseif ($display) {
		Write-Host "$logEntry" }
	 
	#$logEntry = ((Get-Date -uformat "%D %T") + " - " + $logEntry)
	$logEntry | Out-File $logFile -Append
}


#==============================================================================================
function Ping([string]$hostname, [int]$timeout = 1000, [int]$retries = 3) {
	$result = $true
	$ping = new-object System.Net.NetworkInformation.Ping #creates a ping object
	$i = 0
	do {
		$i++
		#write-host "Count: $i - Retries:$retries"
		
		try {
			#write-host "ping"
			$result = $ping.send($hostname, $timeout).Status.ToString()
		} catch {
			#Write-Host "error"
			continue
		}
		if ($result -eq "success") { return $true }
		
	} until ($i -eq $retries)
	return $false
}


#==============================================================================================
Function writeHtmlHeader
{
param($title, $fileName)
$date = ( Get-Date -format R)
$head = @"
<html>
<head>
<meta http-equiv='Content-Type' content='text/html; charset=iso-8859-1'>
<title>$title</title>
<STYLE TYPE="text/css">
<!--
td {
font-family: Tahoma;
font-size: 11px;
border-top: 1px solid #999999;
border-right: 1px solid #999999;
border-bottom: 1px solid #999999;
border-left: 1px solid #999999;
padding-top: 0px;
padding-right: 0px;
padding-bottom: 0px;
padding-left: 0px;
overflow: hidden;
}
body {
margin-left: 5px;
margin-top: 5px;
margin-right: 0px;
margin-bottom: 10px;
table {
table-layout:fixed; 
border: thin solid #000000;
}
-->
</style>
</head>
<body>
<table width='1200'>
<tr bgcolor='#CCCCCC'>
<td colspan='7' height='48' align='center' valign="middle">
<font face='tahoma' color='#003399' size='4'>
<!--<img src="http://servername/administration/icons/xenapp.png" height='42'/>-->
<strong>$title - $date</strong></font>
</td>
</tr>
</table>
<table width='1200'>
<tr bgcolor='#CCCCCC'>
<td width=50% height='48' align='center' valign="middle">
<font face='tahoma' color='#003399' size='4'>
<!--<img src="http://servername/administration/icons/active.png" height='32'/>-->
Active Sessions:  $TotalActiveSessions</font>
<td width=50% height='48' align='center' valign="middle">
<font face='tahoma' color='#003399' size='4'>
<!--<img src="http://servername/administration/icons/disconnected.png" height='32'/>-->
Disconnected Sessions:  $TotalDisconnectedSessions</font>
</td>
</tr>
</table>
"@
$head | Out-File $fileName
}

# ==============================================================================================
Function writeTableHeader
{
param($fileName)
$tableHeader = @"
<table width='1200'><tbody>
<tr bgcolor=#CCCCCC>
<td width='6%' align='center'><strong>ServerName</strong></td>
"@

$i = 0
while ($i -lt $headerNames.count) {
	$headerName = $headerNames[$i]
	$headerWidth = $headerWidths[$i]
	$tableHeader += "<td width='" + $headerWidth + "%' align='center'><strong>$headerName</strong></td>"
	$i++
}

$tableHeader += "</tr>"

$tableHeader | Out-File $fileName -append
}

# ==============================================================================================
Function writeData
{
	param($data, $fileName)
	
	$data.Keys | sort | foreach {
		$tableEntry += "<tr>"
		$computerName = $_
		$tableEntry += ("<td bgcolor='#CCCCCC' align=center><font color='#003399'>$computerName</font></td>")
		#$data.$_.Keys | foreach {
		$headerNames | foreach {
			#"$computerName : $_" | LogMe -display
			try {
				if ($data.$computerName.$_[0] -eq "SUCCESS") { $bgcolor = "#387C44"; $fontColor = "#FFFFFF" }
				elseif ($data.$computerName.$_[0] -eq "WARNING") { $bgcolor = "#FF7700"; $fontColor = "#FFFFFF" }
				elseif ($data.$computerName.$_[0] -eq "ERROR") { $bgcolor = "#FF0000"; $fontColor = "#FFFFFF" }
				else { $bgcolor = "#CCCCCC"; $fontColor = "#003399" }
				$testResult = $data.$computerName.$_[1]
			}
			catch {
				$bgcolor = "#CCCCCC"; $fontColor = "#003399"
				$testResult = ""
			}
			
			$tableEntry += ("<td bgcolor='" + $bgcolor + "' align=center><font color='" + $fontColor + "'>$testResult</font></td>")
		}
		
		$tableEntry += "</tr>"
	}
	
	$tableEntry | Out-File $fileName -append
}

 
# ==============================================================================================
Function writeHtmlFooter
{
param($fileName)
@"
</table>
<table width='1200'>
<tr bgcolor='#CCCCCC'>
<td colspan='7' height='25' align='left'>
<font face='courier' color='#003399' size='2'><strong>Default Load Evaluator  = $DefaultLE</strong></font>
<tr bgcolor='#CCCCCC'>
<td colspan='7' height='25' align='left'>
<font face='courier' color='#003399' size='2'><strong>Default VDISK Image         = $DefaultVDISK</strong></font>
</td>
</tr>
</table>
</body>
</html>
"@ | Out-File $FileName -append
}

Function Check-Port  
{
	param ([string]$hostname, [string]$port)
	try {
		#$socket = new-object System.Net.Sockets.TcpClient($ip, $_.IcaPortNumber) #creates a socket connection to see if the port is open
		$socket = new-object System.Net.Sockets.TcpClient($hostname, $Port) #creates a socket connection to see if the port is open
	} catch {
		$socket = $null
		"Socket connection failed" | LogMe -display -error
		return $false
	}

	if($socket -ne $null) {
		"Socket Connection Successful" | LogMe
		
		if ($port -eq "1494") {
			$stream   = $socket.GetStream() #gets the output of the response
			$buffer   = new-object System.Byte[] 1024
			$encoding = new-object System.Text.AsciiEncoding

			Start-Sleep -Milliseconds 500 #records data for half a second			
		
			while($stream.DataAvailable)
			{
				$read     = $stream.Read($buffer, 0, 1024)  
				$response = $encoding.GetString($buffer, 0, $read)
				#Write-Host "Response: " + $response
				if($response -like '*ICA*'){
					"ICA protocol responded" | LogMe
					return $true
				} 
			}
			
			"ICA did not response correctly" | LogMe -display -error
			return $false
		} else {
			return $true
		}
	   
	} else { "Socket connection failed" | LogMe -display -error; return $false }
}

# ==============================================================================================
# ==                                       MAIN SCRIPT                                        ==
# ==============================================================================================
"Checking server health..." | LogMe -display

rm $logfile -force -EA SilentlyContinue

# Data structure overview:
# Individual tests added to the tests hash table with the test name as the key and a two item array as the value.
# The array is called a testResult array where the first array item is the Status and the second array
# item is the Result. Valid values for the Status are: SUCCESS, WARNING, ERROR and $NULL.
# Each server that is tested is added to the allResults hash table with the computer name as the key and
# the tests hash table as the value.
# The following example retrieves the Logons status for server NZCTX01:
# $allResults.NZCTX01.Logons[0]

$allResults = @{}

# Get session list once to use throughout the script
$sessions = Get-XASession
 
Get-XAServer | % {

	$tests = @{}	
	$server = $_.ServerName
	
	# Check to see if the server is in an excluded folder path
	$folderPath = $_.FolderPath 
	#$excludedFolders | ? { $_ -like $folderPath } | { $server + " in excluded folder - skipping" | LogMe; return }
	if ($excludedFolders -contains $_.FolderPath) { $server + " in excluded folder - skipping" | LogMe; return }
	
	$server | LogMe -display -progress
    
    if ($allSiloInfo.$folderPath) {
        # Silo specific info is available
        if (($allSiloInfo.$folderPath).LE)    { $serverLE    = ($allSiloInfo.$folderPath).LE }
        if (($allSiloInfo.$folderPath).vDisk) { $serverVDisk = ($allSiloInfo.$folderPath).vDisk }
    } else {
        $serverLE    = $defaultLE
        $serverVDisk = $defaultVDisk
    }
	
	$tests.FolderPath   = $null, $_.FolderPath
	$tests.WorkerGroups = $null, (Get-XAWorkerGroup -ServerName $server | % {$_.WorkerGroupName})
	
	if ($_.CitrixVersion -ge 6.5) { $minXA65 = $true }
	else { $minXA65 = $false }

	# Check server logons
	if($_.LogOnsEnabled -eq $false){
		"Logons are disabled on this server" | LogMe -display -warning
		$tests.Logons = "WARNING", "Disabled"
	} else {
		$tests.Logons = "SUCCESS","Enabled"
	}
	
	# Report on active server sessions
	$activeServerSessions = [array]($sessions | ? {$_.State -eq "Active" -and $_.Protocol -eq "Ica" -and $_.ServerName -match $server})
	if ($activeServerSessions) { $totalActiveServerSessions = $activeServerSessions.count }
	# the  following line will return unique users rather than active sessions
	#if ($activeServerSessions) { $totalActiveServerSessions = ($activeServerSessions | Group-Object -property AccountName).count }
	else { $totalActiveServerSessions = 0 }
	$tests.ActiveSessions = $null, $totalActiveServerSessions
	
	# Check Load Evaluator
	$assignedLE = (Get-XALoadEvaluator -ServerName $_.ServerName).LoadEvaluatorName
	if ($serverLE -notcontains $assignedLE) {
		"Non-default Load Evaluator assigned" | LogMe -display -warning
		$tests.LoadEvaluator = "WARNING", $assignedLE
	} else {
		$tests.LoadEvaluator = "SUCCESS", $assignedLE
	}

	# Ping server 
	$result = Ping $server 100
	if ($result -ne "SUCCESS") { $tests.Ping = "ERROR", $result }
	else { $tests.Ping = "SUCCESS", $result 
	
		# Test ICA connectivity
		if (Check-Port $server $_.IcaPortNumber) { $tests.ICAPort = "SUCCESS", "Success" }
		else { $tests.ICAPort = "ERROR","No response" }
		
		# Test Session Reliability port
		if (Check-Port $server $sessionReliabilityPort) { $tests.CGPPort = "SUCCESS", "Success" }
		else { $tests.CGPPort = "ERROR", "No response" }
		
		# Check services
		$services = Get-Service -Computer $Server
		if (($services | ? {$_.Name -eq "IMAService"}).Status -Match "Running") {
			"IMA service running..." | LogMe
			$tests.IMA = "SUCCESS", "Success"
		} else {
			"IMA service stopped"  | LogMe -display -error
			$tests.IMA = "ERROR", "Error"
		}
			
		if (($services | ? {$_.Name -eq "Spooler"}).Status -Match "Running") {
			"SPOOLER service running..." | LogMe
			$tests.Spooler = "SUCCESS","Success"
		} else {
			"SPOOLER service stopped"  | LogMe -display -error
			$tests.Spooler = "ERROR","Error"
		}
			
		if (($services | ? {$_.Name -eq "cpsvc"}).Status -Match "Running") {
			"Citrix Print Manager service running..." | LogMe
			$tests.CitrixPrint = "SUCCESS","Success"
		} else {
			"Citrix Print Manager service stopped"  | LogMe -display -error
			$tests.CitrixPrint = "ERROR","Error"
		}
						
		if (($minXA65 -and $_.ElectionPreference -ne "WorkerMode") -or (!($minXA65))) {
			if (($services | ? {$_.Name -eq "ctxhttp"}).Status -Match "Running") {
				"XML service running..." | LogMe
				$tests.XML = "SUCCESS","Success"
			} else {
				"XML service stopped"  | LogMe -display -error
				$tests.XML = "ERROR","Error"
			}   
		} else { $tests.XML = "SUCCESS","N/A" }
		
		# If the IMA service is running, check the server load
		if ($tests.IMA[0] -eq "Success") {
			try {
				$CurrentServerLoad = Get-XAServerLoad -ServerName $server
			
				#$CurrentServerLoad.GetType().Name|LogMe -display -warning
				if( [int] $CurrentServerLoad.load -lt 7500) {
					  "Serverload is low" | LogMe
					  $tests.Serverload = "SUCCESS", ($CurrentServerload.load)
					}
				elseif([int] $CurrentServerLoad.load -lt 9000) {
					"Serverload is Medium" | LogMe -display -warning
					$tests.Serverload = "WARNING", ($CurrentServerload.load)
				}   	
				else {
					"Serverload is High" | LogMe -display -error
					$tests.Serverload = "ERROR", ($CurrentServerload.load)
				}   
			}
			catch {
				"Error determining Serverload" | LogMe -display -error
				$tests.Serverload = "ERROR", ($CurrentServerload.load)				
			}
			$CurrentServerLoad = 0
		}


		# Test WMI
		$tests.WMI = "ERROR","Error"
		try { $wmi=Get-WmiObject -class Win32_OperatingSystem -computer $_.ServerName } 
		catch {	$wmi = $null }

		# Perform WMI related checks
		if ($wmi -ne $null) {
			$tests.WMI = "SUCCESS", "Success"
			$LBTime=$wmi.ConvertToDateTime($wmi.Lastbootuptime)
			[TimeSpan]$uptime=New-TimeSpan $LBTime $(get-date)

			if ($uptime.days -gt $maxUpTimeDays){
				 "Server reboot warning, last reboot: {0:D}" -f $LBTime | LogMe -display -warning
				 $tests.Uptime = "WARNING", $uptime.days
			} else {
				 $tests.Uptime = "SUCCESS", $uptime.days
			}
			
		} else { "WMI connection failed - check WMI for corruption" | LogMe -display -error	}

		################ PVS SECTION ###############
		if (test-path \\$Server\c$\Personality.ini) {
			$PvsWriteCacheUNC = Join-Path "\\$Server" $PvsWriteCache 
			$CacheDiskexists  = Test-Path $PvsWriteCacheUNC

			if ($CacheDiskexists -eq $False) {
				$PvsWriteCacheUNC = Join-Path "\\$Server" $PvsWriteCache2
				$CacheDiskexists  = Test-Path $PvsWriteCacheUNC
			}


			if ($CacheDiskexists -eq $True)
			{
				$CacheDisk = [long] ((get-childitem $PvsWriteCacheUNC -force).length)
				$CacheDiskGB = "{0:n2}GB" -f($CacheDisk / 1GB)
				"PVS Cache file size: {0:n2}GB" -f($CacheDisk / 1GB) | LogMe
				#"PVS Cache max size: {0:n2}GB" -f($PvsWriteMaxSize / 1GB) | LogMe -display
				if($CacheDisk -lt ($PvsWriteMaxSize * 0.5))
				{
				   "WriteCache file size is low" | LogMe
				   $tests.WriteCacheSize = "SUCCESS", $CacheDiskGB
				}
				elseif($CacheDisk -lt ($PvsWriteMaxSize * 0.8))
				{
				   "WriteCache file size moderate" | LogMe -display -warning
				   $tests.WriteCacheSize = "WARNING", $CacheDiskGB
				}   
				else
				{
				   "WriteCache file size is high" | LogMe -display -error
				   $tests.WriteCacheSize = "ERORR", $CacheDiskGB
				}
			}              
		   
			$Cachedisk = 0
		   
			$VDISKImage = get-content \\$Server\c$\Personality.ini | Select-String "Diskname" | Out-String | % { $_.substring(12)}
			if($VDISKImage -Match $serverVDisk){
				"Default vDisk detected" | LogMe
				$tests.vDisk = "SUCCESS", $VDISKImage
			} else {
				"vDisk unknown"  | LogMe -display -error
				$tests.vDisk = "WARNING", $VDISKImage
			}   
		}
		else { $tests.WriteCacheSize = "SUCCESS", "N/A";  $tests.vDisk = "SUCCESS", "N/A" }
		############## END PVS SECTION #############
	}

	$allResults.$server = $tests
}

# Get farm session info
$ActiveSessions       = [array]($sessions | ? {$_.State -eq "Active" -and $_.Protocol -eq "Ica"})
$DisconnectedSessions = [array]($sessions | ? {$_.State -eq "Disconnected" -and $_.Protocol -eq "Ica"})

if ($ActiveSessions) { $TotalActiveSessions = $ActiveSessions.count }
# the  following line will return unique users rather than active sessions
# if ($activeSessions) { $totalActiveSessions = ($activeSessions | Group-Object -property AccountName).count }
else { $TotalActiveSessions = 0 }

if ($DisconnectedSessions) { $TotalDisconnectedSessions = $DisconnectedSessions.count }
else { $TotalDisconnectedSessions = 0 }

"Total Active Sessions: $TotalActiveSessions" | LogMe -display
"Total Disconnected Sessions: $TotalDisconnectedSessions" | LogMe -display

# Write all results to an html file
Write-Host ("Saving results to html report: " + $resultsHTM)
writeHtmlHeader "XenApp Farm Report" $resultsHTM
writeTableHeader $resultsHTM
$allResults | sort-object -property FolderPath | % { writeData $allResults $resultsHTM }
writeHtmlFooter $resultsHTM

# Write only the errors to an html file
#$allErrors = $allResults | where-object { $_.Ping -ne "success" -or $_.Logons -ne "enabled" -or $_.LoadEvaluator -ne "default" -or $_.ICAPort -ne "success" -or $_.IMA -ne "success" -or $_.XML -ne "success" -or $_.WMI -ne "success" -or $_.Uptime -Like "NOT OK*" }
#$allResults | % { $_.Ping -ne "success" -or $_.Logons -ne "enabled" -or $_.LoadEvaluator -ne "default" -or $_.ICAPort -ne "success" -or $_.IMA -ne "success" -or $_.XML -ne "success" -or $_.WMI -ne "success" -or $_.Uptime -Like "NOT OK*" }
#Write-Host ("Saving errors to html report: " + $errorsHTM)
#writeHtmlHeader "XenApp Farm Report Errors" $errorsHTM
#writeTableHeader $errorsHTM
#$allErrors | sort-object -property FolderPath | % { writeData $allErrors $errorsHTM }
#writeHtmlFooter $errorsHTM

$mailMessageParameters = @{
	From       = $emailFrom
	To         = $emailTo
	Subject    = $emailSubject
	SmtpServer = $smtpServer
	Body       = (gc $resultsHTM) | Out-String
	Attachment = $resultsHTM
}

Send-MailMessage @mailMessageParameters -BodyAsHtml
