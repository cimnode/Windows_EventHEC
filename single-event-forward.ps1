param(
	[string][Parameter(Mandatory=$True)] $eventChannel,
	[string][Parameter(Mandatory=$True)] $eventRecordID 
	)
	
. .\SendWinEventToHEC.ps1

ReadEventByID -eventChannel $eventChannel -eventRecordID $eventRecordID | WindowsEventsToHEC