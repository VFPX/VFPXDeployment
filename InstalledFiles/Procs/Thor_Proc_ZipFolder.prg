Lparameters tcInstalledFilesFolder, tcZipFile

Local lcCommand

* Execute the PowerShell command to create the zip file. Although it's the
* obvious choice, we don't use VFPCompression.fll to do this because it has a
* bug that prevents it from creating a valid zip file under some conditions.

lcCommand = '%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe ' +		;
	'Compress-Archive ' +															;
	'-Path ' + m.tcInstalledFilesFolder + '\* ' +									;
	'-DestinationPath ' + m.tcZipFile
Erase (lcZipFile)
Run &lcCommand
