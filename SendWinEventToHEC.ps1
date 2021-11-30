## REQUIRES version 7 or greater of Powershell

# Handle whatever events are handed it in Windows internal format. (such as from the Get-Event function below)
function WindowsEventsToHEC{ 
	param(
		[string] $SplunkURL, 
		[string] $SplunkHECToken,
		[string] $SplunkIndex,
		[parameter(Mandatory=$TRUE,ValueFromPipeline=$TRUE)] $WindowsEventData 
		)

	$HECBatchSize = 50

	# Get settings in file if they exist.
	$ScriptFilePath = Split-Path $script:MyInvocation.MyCommand.Path
	$ScriptFilePath += "\SplunkSettings.json"
	if (Test-Path -Path $ScriptFilePath -PathType Leaf) {
		$SplunkSettingsObject = Get-Content $ScriptFilePath | ConvertFrom-Json
		if( (-not $SplunkURL) -and $SplunkSettingsObject.SplunkURL ){$SplunkURL = $SplunkSettingsObject.SplunkURL } 
		if( (-not $SplunkHECToken) -and $SplunkSettingsObject.SplunkHECToken ){ $SplunkHECToken = $SplunkSettingsObject.SplunkHECToken}
		if( (-not $SplunkIndex) -and $SplunkSettingsObject.SplunkIndex ){$SplunkIndex = $SplunkSettingsObject.SplunkIndex}
	}

	if( (-not $SplunkURL) -or (-not $SplunkHECToken)){$(throw "SplunkHECToken and SplunkURL are mandatory, please provide a value on command invocation or from settings file.") }


	# Process the event logs handed to function and begin forwarding. Batches should be sent in groups of 50.
	$i = 0
	foreach( $eventObject in $WindowsEventData )
	{
		write-host $i
		# May see some errors here about maxdepth, but it appears to be circular reference of no value.
		$eventData = Select-Object -InputObject $eventObject  -Property * | ConvertTo-Json -Compress -Depth 10 -WarningAction SilentlyContinue
		 
		$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
		$headers.Add("Authorization", 'Splunk ' + $SplunkHECToken)
	
		$body += '{"event":'+ $eventData  +', "index":"'+$SplunkIndex+'","host":"' + $eventObject.MachineName + '","sourcetype":"WindowsEvent","source":"'+ $eventObject.LogName + '","time":"'+ $(Get-Date -Date $eventObject.TimeCreated -UFormat %s) + '"}'
		
		if( ($i -eq  $HECBatchSize) -or ($i -eq ($WindowsEventData.Count - 1)))
		{
			$response = Invoke-RestMethod -Uri $SplunkURL  -Method Post -Headers $headers -Body $body -SkipCertificateCheck
			"Code:'" + $response.code + "' text:'"+ $response.text + "' batch size:" + ($i + 1) 
			$i = 0
			$body = ''
		}
		$i++
	}
}

# Outputs event to pipeline. 
function ReadEventByID
{
param(
	[string][Parameter(Mandatory=$True)] $eventChannel,
	[string][Parameter(Mandatory=$True)] $eventRecordID 
	)
	
	Get-WinEvent -LogName $eventChannel -FilterXPath "<QueryList><Query Id='0' Path='$eventChannel'><Select Path='$eventChannel'>*[System[(EventRecordID=$eventRecordID)]]</Select></Query></QueryList>"
}