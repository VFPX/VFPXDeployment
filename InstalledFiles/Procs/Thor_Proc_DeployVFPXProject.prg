* Parameter lcFolder is the home folder for the project
*   and defaults to the current folder if not supplied
Lparameters lcFolder

Local lcCurrFolder, lcStartFolder

* Create the BuildProcess subdirectory of the project folder if necessary.

lcStartFolder = Curdir()
lcFolder = Evl(lcFolder, lcStartFolder)
Cd (m.lcFolder) && Project Home
lcCurrFolder = Addbs(Addbs(m.lcFolder) + 'BuildProcess') && BuildProcess
If not Directory(lcCurrFolder)
	md (lcCurrFolder)
Endif

* If we don't have ProjectSettings.txt, copy it, VersionTemplate.txt,
* BuildMe.prg, and Thor_Update_Template.prg from the VFPXDeployment folder.

if not file(lcCurrFolder + 'ProjectSettings.txt')
	lcVFPXDeploymentFolder = _screen.cThorFolder + 'Tools\Apps\VFPX Deployment\'
	copy file (lcVFPXDeploymentFolder + 'ProjectSettings.txt') to ;
		(lcCurrFolder + 'ProjectSettings.txt')
	copy file (lcVFPXDeploymentFolder + 'VersionTemplate.txt') to ;
		(lcCurrFolder + 'VersionTemplate.txt')
	copy file (lcVFPXDeploymentFolder + 'BuildMe.prg') to ;
		(lcCurrFolder + 'BuildMe.prg')
	copy file (lcVFPXDeploymentFolder + 'Thor_Update_Template.prg') to ;
		(lcCurrFolder + 'Thor_Update_Template.prg')
	messagebox('Please edit ProjectSettings.txt and fill in the settings ' + ;
		'for this project. Also, edit InstalledFiles.txt and specify ' + ;
		'which files should be installed. Then run VFPX Deployment again.', ;
		16, 'Project Deployment')
	modify file (lcCurrFolder + 'ProjectSettings.txt') nowait
	modify file (lcCurrFolder + 'InstalledFiles.txt') nowait
	return
endif not file(lcCurrFolder + 'ProjectSettings.txt')

lcProjectName = GetWordNum(lcCurrFolder, GetWordCount(lcCurrFolder, '\') - 1, '\')
Deploy(lcProjectName, lcCurrFolder)

* Restore the former current directory.

Cd (m.lcStartFolder)

Return


* ================================================================================ 
* ================================================================================ 
* The work horse - put in separate Proc so that any the cd (lcStartFolder) is always run

Procedure Deploy(lcProjectName, lcCurrFolder)
	* Put the paths for files we may use into variables.

	lcProjectFile           = lcCurrFolder + 'ProjectSettings.txt'
	lcInstalledFilesListing = lcCurrFolder + 'InstalledFiles.txt'
	lcInstalledFilesFolder  = 'InstalledFiles'
	lcBuildProgram          = lcCurrFolder + 'BuildMe.prg'
	lcVersionTemplateFile   = lcCurrFolder + 'VersionTemplate.txt'
	lcUpdateTemplateFile    = lcCurrFolder + 'Thor_Update_Template.prg'

	* Get the current project settings into public variables. 

	lcProjectSettings = filetostr(lcProjectFile)
	public pcAppName, pcAppID, pcVersion, pdVersionDate, ;
		pcVersionDate, pcChangeLog, plContinue
	pdVersionDate         = date()
	pcVersion             = ''
	pcChangeLog           = ''
	plContinue            = .T.
	llPrompt              = .T.
	lcBin2PRGFolderSource = ''
	lcComponent           = 'Yes'
	lcCategory            = 'Applications'
	lcPJXFile             = ''
	lcAppFile             = ''
	lnSettings            = alines(laSettings, lcProjectSettings)
	for lnI = 1 to lnSettings
		lcLine  = laSettings[lnI]
		lnPos   = at('=', lcLine)
		lcName  = alltrim(left(lcLine, lnPos - 1))
		lcValue = alltrim(substr(lcLine, lnPos + 1))
		lcUName = upper(lcName)
		do case
			case lcUName = 'APPNAME'
				pcAppName = lcValue
			case lcUName = 'APPID'
				pcAppID = lcValue
			case lcUName = 'VERSION'
				pcVersion = lcValue
			case lcUName = 'VERSIONDATE'
				pdVersionDate = evaluate('{^' + lcValue + '}')
			case lcUName = 'PROMPT'
				llPrompt = upper(lcValue) = 'Y'
			case lcUName = 'CHANGELOG'
				pcChangeLog = lcValue
			case lcUName = 'BIN2PRGFOLDER'
				lcBin2PRGFolderSource = lcValue
			case lcUName = 'COMPONENT'
				lcComponent = lcValue
			case lcUName = 'CATEGORY'
				lcCategory = lcValue
			case lcUName = 'PJXFILE'
				lcPJXFile = lcValue
			case lcUName = 'APPFILE'
				lcAppFile = lcValue
		endcase
	next lnI

	* Ensure we have valid pcAppName and pcAppID values.

	if empty(pcAppName)
		messagebox('The appName setting was not specified.', 16, ;
			'Project Deployment')
		return
	endif empty(pcAppName)
	if empty(pcAppID)
		messagebox('The appID setting was not specified.', 16, ;
			'Project Deployment')
		return
	endif empty(pcAppID)
	if ' ' $ pcAppID
		messagebox('The appID setting cannot have spaces.', 16, ;
			'Project Deployment')
		return
	endif ' ' $ pcAppID

	* If we're supposed to build an APP or EXE, ensure we have both settings
	* and we're running VFP 9 and not VFP Advanced since the APP/EXE structure
	* is different.

	if (empty(lcPJXFile) and not empty(lcAppFile)) or ;
		(empty(lcAppFile) and not empty(lcPJXFile))
		messagebox('If you specify one of them, you have to specify both ' + ;
			'PJXFile and AppFile.', 16, 'Project Deployment')
		return
	endif (empty(lcPJXFile) ...
	if not empty(lcPJXFile) and val(version(4)) > 9
	    messagebox('You must run VFPX Deployment using VFP 9 not VFP Advanced.', ;
	        16, 'Project Deployment')
	    return
	endif not empty(lcPJXFile) ...

	* If setting Bin2PRGFolderSource is supplied, ensure folder exists
	* and also find FoxBin2PRG.EXE.

	lcBin2PRGFolder = ''
	If Not Empty(lcBin2PRGFolderSource)
		lcFoxBin2PRG = execscript(_screen.cThorDispatcher, 'Thor_Proc_GetFoxBin2PrgFolder') + ;
			'FoxBin2Prg.exe'
		If File(m.lcFoxBin2PRG)
			lcBin2PRGFolder = Fullpath(m.lcCurrFolder + '..\' + lcBin2PRGFolderSource)
			If Not Directory(m.lcBin2PRGFolder)
				Messagebox('Folder "' + lcBin2PRGFolderSource + '" not found.', 16,			;
					  'Project Deployment')
				Return
			Endif
		Else
			Messagebox('FoxBin2PRG.EXE not found.', 16,			;
				  'Project Deployment')
			Return
		Endif
	Endif Empty(pcAppName)
	
	* Get the names of the zip, Thor CFU version, and Thor updaters files and set pcVersionDate to
	* a string version of the release date.

	lcZipFile     = 'ThorUpdater\' + pcAppID + '.zip'
	lcVersionFile = 'ThorUpdater\' + pcAppID + 'Version.txt'
	lcUpdateFile  = lcCurrFolder + 'Thor_Update_' + pcAppID + '.prg'
	lcDate        = dtoc(pdVersionDate, 1)
	pcVersionDate = substr(lcDate, 1, 4) + '-' + substr(lcDate, 5, 2) + '-' + ;
		substr(lcDate, 7, 2)

	* Get the version number if it wasn't specified and we're supposed to.

	if empty(pcVersion) and llPrompt
		lcValue = inputbox('Version', 'Project Deployment', '')
		if empty(lcValue)
			return
		endif empty(lcValue)
		pcVersion      = lcValue
	endif empty(pcVersion) ...

	* Execute Build.prg if it exists. If it sets plContinue to .F., exit.

	if file(lcBuildProgram)
		do (lcBuildProgram)
		if not plContinue
			return
		endif not plContinue
	endif file(lcBuildProgram)

	*** JRN 2023-01-10 : Call FoxBin2PRG, if applicable
	If Not Empty(m.lcBin2PRGFolder)
		Do (m.lcFoxBin2PRG) With 'BIN2PRG', m.lcBin2PRGFolder + '\*.*'
	Endif
	
	* Ensure we have a version number (Build.prg may have set it).

	if empty(pcVersion)
		messagebox('The version setting was not specified.', 16, ;
			'Project Deployment')
		return
	endif empty(pcVersion)

	* Create an APP/EXE if we're supposed to.
	
	do case
		case empty(lcPJXFile)
		case upper(justext(lcAppFile)) = 'EXE'
			build exe (lcAppFile) from (lcPJXFile)
		otherwise
			build app (lcAppFile) from (lcPJXFile)
	endcase
	lcErrFile = forceext(lcAppFile, 'err')
	if not empty(lcPJXFile) and file(lcErrFile)
		messagebox('An error occurred building the project. Please see ' + ;
			'the ERR file for details.', 16, 'Project Deployment')
		modify file (lcErrFile) nowait
		return
	endif not empty(lcPJXFile) ...

	do case

	* If InstalledFiles.txt exists, copy the files listed in it to the
	* InstalledFiles folder (folders are created as necessary).

		case file(lcInstalledFilesListing)
			lcFiles = filetostr(lcInstalledFilesListing)
			lnFiles = alines(laFiles, lcFiles)
			for lnI = 1 to lnFiles
				lcSource = laFiles[lnI]
				lcTarget = addbs(lcInstalledFilesFolder) + lcSource
				lcFolder = justpath(lcTarget)
				if not directory(lcFolder)
					md (lcFolder)
				endif not directory(lcFolder)
				copy file (lcSource) to (lcTarget)
			next lnI

	* If the InstalledFiles folder doesn't exist, give a warning and exit.

		case not directory(lcInstalledFilesFolder)
			messagebox('Please either create InstalledFiles.txt in the ' + ;
				'BuildProcess folder with each file to be installed by Thor ' + ;
				'listed on a separate line, or create a subdirectory of ' + ;
				'the project folder named InstalledFiles and copy the ' + ;
				'files Thor should install to it.', ;
				16, 'Project Deployment')
			return
	endcase

	* Create the ThorUpdater folder if necessary.

	if not directory('ThorUpdater')
		md ThorUpdater
	endif not directory('ThorUpdater')

	* Update Version.txt.

	lcDate    = dtoc(pdVersionDate, 1)
	lcVersion = filetostr(lcVersionTemplateFile)
	lnJulian  = pdVersionDate - {^2000-01-01}
	lcJulian  = padl(lnJulian, 5, '0')
	lcChange  = iif(file(pcChangeLog), filetostr(pcChangeLog), '')
	lcVersion = strtran(lcVersion, '{APPNAME}',     pcAppName, -1, -1, 1)
	lcVersion = strtran(lcVersion, '{APPID}',       pcAppID,   -1, -1, 1)
	lcVersion = strtran(lcVersion, '{VERSIONDATE}', lcDate,    -1, -1, 1)
	lcVersion = strtran(lcVersion, '{VERSION}',     pcVersion, -1, -1, 1)
	lcVersion = strtran(lcVersion, '{JULIAN}',      lcJulian,  -1, -1, 1)
	lcVersion = strtran(lcVersion, '{CHANGELOG}',   lcChange,  -1, -1, 1)
	lcVersion = strtran(lcVersion, '{COMPONENT}',   lcComponent, -1, -1, 1)
	lcVersion = strtran(lcVersion, '{CATEGORY}',    lcCategory,  -1, -1, 1)
	lcVersion = textmerge(lcVersion)
	for lnI = occurs('@@@', lcVersion) to 1 step -1
		lcRemove  = strextract(lcVersion, '@@@', '\\\', lnI, 4)
		lcVersion = strtran(lcVersion, lcRemove)
	next lnI
	strtofile(lcVersion, lcVersionFile)

	* Update Thor_Update program.

	if file(lcUpdateTemplateFile) and not file(lcUpdateFile)
		lcContent = filetostr(lcUpdateTemplateFile)
		lcContent = strtran(lcContent, '{APPNAME}', pcAppName, -1, -1, 1)
		lcContent = strtran(lcContent, '{APPID}',   pcAppID,   -1, -1, 1)
		strtofile(lcContent, lcUpdateFile)
	endif file(lcUpdateTemplateFile) ...

	* Zip the source files.

	ExecScript(_Screen.cThorDispatcher, 'Thor_Proc_ZipFolder', lcInstalledFilesFolder, lcZipFile)

	* Add AppID.zip and AppIDVersion.txt to the repository.
	
	lcCommand = 'git add ' + lcZipFile + ' -f'
	run &lcCommand
	lcCommand = 'git add ' + lcVersionFile
	run &lcCommand

	MessageBox('Deployment for ' + lcProjectName + ' complete', 64, 'All done', 5000)

EndProc 
