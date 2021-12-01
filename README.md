# Windows_EventHEC
  
## this can create event loops! ##  
  
Use Windows Event Viewer to create XML queries. XML can be copied to event trigger.
  
These scripts can be used to trigger event forwarding from Windows Event system directly to a Splunk HEC endpoint. It does not require installing any 3rd party software. It does require Powershell 7 be installed. (PS7 handles events more efficiently, and older versions of Powershell are on the way out.)
  
1. Download files to a permanent location
2. Edit json settings file to fit your environment.
3. Create task
4. create trigger on task
5. create action on task
