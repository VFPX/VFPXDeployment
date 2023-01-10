*******************************************************************************
* Deploy.prg does the deployment steps necessary to update the files needed by
* Thor Check For Updates (CFU). This PRG is expected to be in a subdirectory of
* the project root folder named BuildProcess. Other files that need to be in
* this subdirectory are:

* - InstalledFiles.txt: contain the paths for the files to be installed by Thor
* 	CFU, one file per line. Paths relative to the root of the project folder
*	should be used. Alternatively, manually create a subdirectory of the
*	project root folder named InstalledFiles and copy the necessary files into
*	that folder (only the files to be installed; no extra stuff allowed).

* - ProjectSettings.txt: contains the project settings (for backward
*		compatibility, the file can also be named Project.txt):
*
*		appName      = descriptive name of the project (required)
*		appID        = project name (usually the descriptive name but must be
*						URL-friendly--no spaces or other illegal URL
*						characters; required)
*		version      = version number (optional; see below)
*		versionDate  = release date as YYYY-MM-DD (optional; see below)
*		prompt       = Y to prompt for version if it isn't specified; N to not
*						prompt. Not required if version is specified
*		changeLog    = path for a file containing changes (optional; see below)
*		Bin2PRGFolder = path to the source code folder to which FoxBin2PRG is to 
*						 be applied (optional, ignored if not supplied)
*
*	For example:
*
*		appName      = Project Explorer
*		appID        = ProjectExplorer
*		version      = 1.0
*		versionDate  = 2023-01-07
*		changeLog    = Change Log.md
*
*	These values are store in public variables:
*
*		pcAppName: the appName setting
*		pcAppID: the appID setting
*		pcVersion: the version number
*		pdVersionDate: the release date
*		pcVersionDate: the release date as a string (YYYY-MM-DD)
*		pcChangeLog: the path for the change log
*		plContinue: .T. to continue the deployment process or .F. to stop
*
*	Note that only appName and appID are required. For the other settings:
*
*		- version: you can either edit Project.txt and update version before
*			running Deploy.prg or omit it from Project.txt, in which case
*			you'll be prompted for a value if the prompt setting is Y or
*			omitted. If the prompt setting is N, that means your Build.prg
*			(see below) will update the pcVersion variable with the version
*			number (for example, by reading from an INI file or source code).
*		- versionDate: you can either edit Project.txt and update versionDate
*			before running Deploy.prg or omit it from Project.txt, in which
*			case today's date is used.

* - VersionTemplate.txt: contains the template for the Thor CFU version file.
*	Although it has a TXT extension, it actually contains VFP code. It must
*	accept a single parameter, which is a Thor CFU updater object. The code
*	will typically set properties of that object to do whatever is necessary.
*	This template file should have placeholders for project settings:
*
*		- {VERSION}: substituted with the value of pcVersion
*		- {VERSIONDATE}: substituted with the value of pdVersionDate
*		- {APPNAME}: substituted with the value of pcAppName
*		- {APPID}: substituted with the value of pcAppID
*		- {JULIAN}: substituted with the value of pdVersionDate as a numeric
*			value: the Julian date since 2000-01-01 (some projects use that as
*			a minor version number)
*		- {CHANGELOG}: substituted with the contents of the file specified in
*			pcChangeLog
*
*	For backward compatibility, the file can also be named Version.txt.

* - BuildMe.prg: an optional program that performs any build tasks necessary
*	for the project, such as building an APP, updating version numbers in code
*	or include files, etc. This program can use the public variables discussed
*	above.
*******************************************************************************

* Start by making sure the current folder is the root for the project (one
* level up from the location of this PRG).


* Parameter lcFolder is the home folder for the project OR the BuildProcess sub-folder
*   and defaults to the current folder if not supplied
Lparameters lcFolder

Local lcCurrFolder, lcStartFolder

lcStartFolder = Curdir()
lcFolder = Evl(lcFolder, lcStartFolder)
If Directory(Addbs(m.lcFolder) + 'BuildProcess')
	lcCurrFolder = Addbs(Addbs(m.lcFolder) + 'BuildProcess') && BuildProcess
	Cd (m.lcFolder) && Project Home
Else
	lcCurrFolder = Addbs(lcFolder) && BuildProcess
	Cd (lcCurrFolder + '\..') && Project Home
Endif

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

	* Give a warning and exit if ProjectSettings.txt or VersionTemplate.txt (or
	* older names for backward compatibility) don't exist.

	if not file(lcProjectFile)
		lcProjectFile = lcCurrFolder + 'Project.txt'
		if not file(lcProjectFile)
			messagebox('Please create ProjectSettings.txt in the BuildProcess ' + ;
				'folder.', 16, 'Project Deployment')
			return
		endif not file(lcProjectFile)
	endif not file(lcProjectFile)
	if not file(lcVersionTemplateFile)
		lcVersionTemplateFile = lcCurrFolder + 'Version.txt'
		if not file(lcVersionTemplateFile)
			messagebox('Please create VersionTemplate.txt in the BuildProcess ' + ;
				'folder.', 16, 'Project Deployment')
			return
		endif not file(lcVersionTemplateFile)
	endif not file(lcVersionTemplateFile)

	* Get the current project settings into public variables. 

	lcProjectSettings = filetostr(lcProjectFile)
	public pcAppName, pcAppID, pcVersion, pdVersionDate, ;
		pcVersionDate, pcChangeLog, plContinue
	pdVersionDate  = date()
	pcVersion      = ''
	pcChangeLog    = ''
	plContinue     = .T.
	llPrompt       = .T.
	lcBin2PRGFolder = ''
	lnSettings     = alines(laSettings, lcProjectSettings)	
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
				pcVersion      = lcValue
			case lcUName = 'VERSIONDATE'
				pdVersionDate = evaluate('{^' + lcValue + '}')
			case lcUName = 'PROMPT'
				llPrompt = upper(lcValue) = 'Y'
			case lcUName = 'CHANGELOG'
				pcChangeLog = lcValue
			case lcUName = 'BIN2PRGFOLDER'
				lcBin2PRGFolderSource = lcValue
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

	* If setting Bin2PRGFolder is supplied, ensure folder exists
	*   and also FoxBin2PRG.EXE

	If Not Empty(lcBin2PRGFolderSource)
		lcFoxBin2PRG = _Screen.cThorFolder + 'Tools\Components\FoxBIN2PRG\FoxBIN2PRG.EXE'
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
	
	* Get the names of the zip and Thor CFU version files and set pcVersionDate to
	* a string version of the release date.

	lcZipFile     = 'ThorUpdater\' + pcAppID + '.zip'
	lcVersionFile = 'ThorUpdater\' + pcAppID + 'Version.txt'
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
				'listed on a separate line, or create folder named ' + ;
				'InstalledFiles with the files Thor should install.', ;
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
	lcVersion = strtran(lcVersion, '{APPNAME}',      pcAppName, -1, -1, 1)
	lcVersion = strtran(lcVersion, '{APPID}',        pcAppID,   -1, -1, 1)
	lcVersion = strtran(lcVersion, '{VERSIONDATE}',  lcDate,    -1, -1, 1)
	lcVersion = strtran(lcVersion, '{VERSION}',      pcVersion, -1, -1, 1)
	lcVersion = strtran(lcVersion, '{JULIAN}',       lcJulian,  -1, -1, 1)
	lcVersion = strtran(lcVersion, '{CHANGELOG}',    lcChange,  -1, -1, 1)
	strtofile(lcVersion, lcVersionFile)

	ExecScript(_Screen.cThorDispatcher, 'Thor_Proc_ZipFolder', lcInstalledFilesFolder, lcZipFile)

	MessageBox('Deployment for ' + lcProjectName + ' complete', 64, 'All done', 5000)

EndProc 
