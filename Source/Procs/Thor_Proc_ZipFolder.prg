lparameters;
 tcInstalledFilesFolder,;
  tcZipFile

local;
 llReturn  AS Boolen,;
 lcCommand as string

* Execute the PowerShell command to create the zip file. Although it's the
* obvious choice, we don't use VFPCompression.fll to do this because it has a
* bug that prevents it from creating a valid zip file under some conditions.

lcCommand = "cmd /c %SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" +		;
	" Compress-Archive" +															;
	" -Path '" + m.tcInstalledFilesFolder + "\*'" +									;
	" -DestinationPath '" + m.tcZipFile + "'"
erase(m.tcZipFile)

llReturn = Execscript(_Screen.cThorDispatcher, 'Thor_Proc_RunExtApp', m.lcCommand,.F.,.T.)
Return m.llReturn

*run &lcCommand
