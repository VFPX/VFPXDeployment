* Parameter lcFolder is the home folder for the project
*   and defaults to the current folder if not supplied
Lparameters lcFolder
return
Local lcCurrFolder, lcStartFolder

* Get the project folder.

lcStartFolder = Curdir()
lcFolder = Evl(lcFolder, lcStartFolder)
Cd (m.lcFolder) && Project Home

* Bug out if NoVFPXDeployment.txt exists.

if file('NoVFPXDeployment.txt')
	messagebox('VFPX Project Deployment will not run because NoVFPXDeployment.txt exists.', ;
		16, 'VFPX Project Deployment')
	return
endif file('NoVFPXDeployment.txt')

* Create the BuildProcess subdirectory of the project folder if necessary.

lcCurrFolder = Addbs(Addbs(m.lcFolder) + 'BuildProcess') && BuildProcess
If not Directory(lcCurrFolder)
*SF 20230512 we better check if this exists a different Thor
*this is not fool-proof, since there are many ways to do Thor
*but a very common one
	if Directory(Addbs(m.lcFolder) + 'ThorUpdater')
		messagebox('There is allready a Thor folder. Stoped.', ;
			16, 'VFPX Project Deployment')
		return
	endif
	md (lcCurrFolder)
Endif

* If we don't have ProjectSettings.txt, copy it, VersionTemplate.txt, and
* BuildMe.prg, AfterBuild.prg from the VFPXDeployment folder.

lcVFPXDeploymentFolder = _screen.cThorFolder + 'Tools\Apps\VFPXDeployment\'

if not file(lcCurrFolder + 'ProjectSettings.txt')
	copy file (lcVFPXDeploymentFolder + 'ProjectSettings.txt') to ;
		(lcCurrFolder + 'ProjectSettings.txt')
	copy file (lcVFPXDeploymentFolder + 'VersionTemplate.txt') to ;
		(lcCurrFolder + 'VersionTemplate.txt')
	copy file (lcVFPXDeploymentFolder + 'BuildMe.prg') to ;
		(lcCurrFolder + 'BuildMe.prg')
	copy file (lcVFPXDeploymentFolder + 'AfterBuild.prg') to ;
		(lcCurrFolder + 'AfterBuild.prg')
	messagebox('Please edit ProjectSettings.txt and fill in the settings ' + ;
		'for this project. Also, edit InstalledFiles.txt and specify ' + ;
		'which files should be installed. Then run VFPX Project Deployment again.', ;
		16, 'VFPX Project Deployment')
	modify file (lcCurrFolder + 'ProjectSettings.txt') nowait
	modify file (lcCurrFolder + 'InstalledFiles.txt') nowait
	return
endif not file(lcCurrFolder + 'ProjectSettings.txt')

lcProjectName = GetWordNum(lcCurrFolder, GetWordCount(lcCurrFolder, '\') - 1, '\')
Deploy(lcVFPXDeploymentFolder, lcProjectName, lcCurrFolder)

* Restore the former current directory.

Cd (m.lcStartFolder)

Return


* ================================================================================ 
* ================================================================================ 
* The work horse - put in separate Proc so that any the cd (lcStartFolder) is always run

Procedure Deploy(tcVFPXDeploymentFolder,lcProjectName, lcCurrFolder)
	* Put the paths for files we may use into variables.

	lcProjectFile           = lcCurrFolder + 'ProjectSettings.txt'
	lcInstalledFilesListing = lcCurrFolder + 'InstalledFiles.txt'
	lcInstalledFilesFolder  = 'InstalledFiles'
	lcBuildProgram          = lcCurrFolder + 'BuildMe.prg'
	lcAfterBuildProgram     = lcCurrFolder + 'AfterBuild.prg'
	lcVersionTemplateFile   = lcCurrFolder + 'VersionTemplate.txt'
	lcUpdateTemplateFile    = _screen.cThorFolder + ;
		'Tools\Apps\VFPXDeployment\Thor_Update_Template.txt'

	* Get the current project settings into public variables. 

	lcProjectSettings = filetostr(lcProjectFile)
	public pcAppName, pcAppID, pcVersion, pdVersionDate, ;
		pcVersionDate, pcChangeLog, plContinue
*SF 20230512: add new flags
	public pcFullVersion, plRun_Bin2Prg, plRun_git

	pdVersionDate         = date()
	pcVersion             = ''
	pcChangeLog           = ''
	plContinue            = .T.
*SF 20230512: add new flags
	pcFullVersion         = ''		&& For autoset README.MD. Full version info. Either pcVersion or returned from BuilMe.prg
	plRun_Bin2Prg         = .T.		&& Run FoxBin2Prg; from ProjectSettings.txt
	plRun_git             = .T.		&& Run git; from ProjectSettings.txt
*/SF 20230512
	llPrompt              = .T.
	lcBin2PRGFolderSource = ''
	lcComponent           = 'Yes'
	lcCategory            = 'Applications'
	lcPJXFile             = ''
	llRecompile           = .F.
	lcAppFile             = ''
	lcRepositoryRoot      = 'https://github.com/VFPX/'
	lcRepository          = ''
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
			case lcUName = 'RECOMPILE'
				llRecompile = upper(lcValue) = 'Y'
			case lcUName = 'APPFILE'
				lcAppFile = lcValue
			case lcUName = 'REPOSITORY'
				lcRepository = lcValue
			case lcUName = 'INSTALLEDFILESFOLDER'
				lcInstalledFilesFolder = lcValue
*SF 20230512: new flags
			case lcUName = 'RUNBIN2PRG'
				plRun_Bin2Prg = upper(lcValue) = 'Y'
			case lcUName = 'RUNGIT'
				plRun_git = upper(lcValue) = 'Y'
*/SF 20230512
		endcase
	next lnI

*SF 20230512, get pjx version
	if UPPER(pcVersion)=='PJX'
		pcVersion = ''
		if empty(lcPJXFile)
*use the active pjx, since no pjx is defined
			if TYPE("_VFP.ActiveProject")='O'
				pcVersion = _VFP.ActiveProject.VersionNumber
			endif
		else
*use pjx defined
*bit more work
*see if the project is open
			for lnProject = 1 to _VFP.Projects.Count
				if upper(fullpath(lcPJXFile))==upper(_VFP.Projects(lnProject).Name)
					pcVersion = _VFP.Projects(lnProject).VersionNumber
					exit
				endif
			endfor
			if empty(pcVersion);
					and file(fullpath(lcPJXFile))
				MODIFY PROJECT (fullpath(lcPJXFile)) NOWAIT NOSHOW NOPROJECTHOOK
				pcVersion = _VFP.Projects(lnProject).VersionNumber
				_VFP.ActiveProject.Close
			endif
		endif
		if empty(pcVersion)
				messagebox('No project to get version number from found.', 16, ;
				'VFPX Project Deployment')
				return
		endif
	endif
	* Ensure we have valid pcAppName and pcAppID values.

	if empty(pcAppName)
		messagebox('The appName setting was not specified.', 16, ;
			'VFPX Project Deployment')
		return
	endif empty(pcAppName)
	if empty(pcAppID)
		messagebox('The appID setting was not specified.', 16, ;
			'VFPX Project Deployment')
		return
	endif empty(pcAppID)
	if ' ' $ pcAppID or '	' $ pcAppID
		messagebox('The appID setting cannot have spaces or tabs.', 16, ;
			'VFPX Project Deployment')
		return
	endif ' ' $ pcAppID

	* If we're supposed to build an APP or EXE, ensure we have both settings
	* and we're running VFP 9 and not VFP Advanced since the APP/EXE structure
	* is different. If AppFile is omitted, use the same folder and name as the
	* PJX file.

	if not empty(lcPJXFile) and empty(lcAppFile)
		lcAppFile = forceext(lcPJXFile, 'app')
	endif not empty(lcPJXFile) ...
	if (empty(lcPJXFile) and not empty(lcAppFile)) or ;
		(empty(lcAppFile) and not empty(lcPJXFile))
		messagebox('If you specify one of them, you have to specify both ' + ;
			'PJXFile and AppFile.', 16, 'VFPX Project Deployment')
		return
	endif (empty(lcPJXFile) ...
	if not empty(lcPJXFile) and val(version(4)) > 9
	    messagebox('You must run VFPX Project Deployment using VFP 9 not VFP Advanced.', ;
	        16, 'VFPX Project Deployment')
	    return
	endif not empty(lcPJXFile) ...

	* If Bin2PRGFolderSource or PJXFile was supplied, find FoxBin2PRG.EXE.

	lcBin2PRGFolder = ''
	lcFoxBin2PRG    = ''
	If Not Empty(lcBin2PRGFolderSource) or not empty(lcPJXFile)
		lcFoxBin2PRG = execscript(_screen.cThorDispatcher, 'Thor_Proc_GetFoxBin2PrgFolder') + ;
			'FoxBin2Prg.exe'
		do case
			case not file(m.lcFoxBin2PRG)
				Messagebox('FoxBin2PRG.EXE not found.', 16, ;
					  'VFPX Project Deployment')
				Return
			case not empty(lcBin2PRGFolderSource)
				lnBin2PRGFolders = alines(laBin2PRGFolders, lcBin2PRGFolderSource, 4, ',')
				for lnI = 1 to lnBin2PRGFolders
					lcFolder = laBin2PRGFolders[lnI]
					laBin2PRGFolders[lnI] = Fullpath(m.lcCurrFolder + '..\' + lcFolder)
					If Not Directory(laBin2PRGFolders[lnI])
						Messagebox('Folder "' + lcFolder + '" not found.', 16,	;
						  'VFPX Project Deployment')
						Return
					Endif
				next lnI
		endcase
	endif
	
	* Get the names of the zip, Thor CFU version, and Thor updaters files and set pcVersionDate to
	* a string version of the release date.

	lcZipFile     = 'ThorUpdater\' + pcAppID + '.zip'
	lcVersionFile = 'ThorUpdater\' + pcAppID + 'Version.txt'
	lcUpdateFile  = lcCurrFolder + 'Thor_Update_' + pcAppID + '.prg'
	lcDate        = dtoc(pdVersionDate, 1)
	pcVersionDate = substr(lcDate, 1, 4) + '-' + substr(lcDate, 5, 2) + '-' + ;
		substr(lcDate, 7, 2)

* Get the repository to use if it wasn't specified.
	
	if empty(lcRepository)
		lcRepository = lcRepositoryRoot + pcAppID
	endif empty(lcRepository)

	* Get the version number if it wasn't specified and we're supposed to.

	if empty(pcVersion) and llPrompt
		lcValue = inputbox('Version', 'VFPX Project Deployment', '')
		if empty(lcValue)
			return
		endif empty(lcValue)
		pcVersion = lcValue
	endif empty(pcVersion) ...

	* Execute Build.prg if it exists. If it sets plContinue to .F., exit.

	pcFullVersion = pcVersion

	if file(lcBuildProgram)
		do (lcBuildProgram)
		if not plContinue
			return
		endif not plContinue
	endif file(lcBuildProgram)

	SetDocumentation (addbs(justpath(justpath(lcCurrFolder))), tcVFPXDeploymentFolder, lcRepository)

	*** JRN 2023-01-10 : Call FoxBin2PRG, if applicable
*SF 20230512: flag to disable FoxBin2PRG
	if plRun_Bin2Prg AND not empty(lcFoxBin2PRG)
		if not empty(lcPJXFile)
			Do (m.lcFoxBin2PRG) With fullpath(lcPJXFile), '*'
		endif not empty(lcPJXFile)
		If Not Empty(m.lcBin2PRGFolderSource)
			*** JRN 2023-01-29 : BIN2PRG for folder and sub-folders
			for lnI = 1 to lnBin2PRGFolders
				lcFolder = laBin2PRGFolders[lnI]
				Do (m.lcFoxBin2PRG) With 'BIN2PRG', m.lcFolder && + '\*.*'
			next lnI
		Endif
	endif plRun_Bin2Prg AND not empty(lcFoxBin2PRG)
	
	* Ensure we have a version number (Build.prg may have set it).

	if empty(pcVersion)
		messagebox('The version setting was not specified.', 16, ;
			'VFPX Project Deployment')
		return
	endif empty(pcVersion)

	* Create an APP/EXE if we're supposed to.
	
	lcRecompile = iif(llRecompile, 'recompile', '')
	do case
		case empty(lcPJXFile)
		case upper(justext(lcAppFile)) = 'EXE'
			build exe (lcAppFile) from (lcPJXFile) &lcRecompile
		otherwise
			build app (lcAppFile) from (lcPJXFile) &lcRecompile
	endcase
	lcErrFile = forceext(lcAppFile, 'err')
	if not empty(lcPJXFile) and file(lcErrFile)
		messagebox('An error occurred building the project. Please see ' + ;
			'the ERR file for details.', 16, 'VFPX Project Deployment')
		modify file (lcErrFile) nowait
		return
	endif not empty(lcPJXFile) ...

	do case

	* If InstalledFiles.txt exists, copy the files listed in it to the
	* InstalledFiles folder (folders are created as necessary).

		case file(lcInstalledFilesListing)
			lcFiles = filetostr(lcInstalledFilesListing)
			lnFiles = alines(laFiles, lcFiles, 1 + 4)
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
				16, 'VFPX Project Deployment')
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
	lcVersion = strtran(lcVersion, '{APPNAME}',        pcAppName,   -1, -1, 1)
	lcVersion = strtran(lcVersion, '{APPID}',          pcAppID,     -1, -1, 1)
	lcVersion = strtran(lcVersion, '{VERSIONDATE}',    lcDate,      -1, -1, 1)
	lcVersion = strtran(lcVersion, '{CVERSIONDATE}',   STUFF(STUFF(lcDate, 7, 0, '-'), 5, 0, '-'),      -1, -1, 1)
	lcVersion = strtran(lcVersion, '{VERSION}',        pcVersion,   -1, -1, 1)
	lcVersion = strtran(lcVersion, '{JULIAN}',         lcJulian,    -1, -1, 1)
	lcVersion = strtran(lcVersion, '{CHANGELOG}',      lcChange,    -1, -1, 1)
	lcVersion = strtran(lcVersion, '{COMPONENT}',      lcComponent, -1, -1, 1)
	lcVersion = strtran(lcVersion, '{CATEGORY}',       lcCategory,  -1, -1, 1)
	lcVersion = textmerge(lcVersion)
	for lnI = occurs('@@@', lcVersion) to 1 step -1
		lcRemove  = strextract(lcVersion, '@@@', '\\\', lnI, 4)
		lcVersion = strtran(lcVersion, lcRemove)
	next lnI
	
	strtofile(lcVersion, lcVersionFile)
	
	* check proposed version file for errors
	If CheckVersionFile(lcVersionFile) = .F.
		Return
	EndIf 
	erase (forceext(lcVersionFile, 'fxp'))
	
	* Update Thor_Update program.

	if file(lcUpdateTemplateFile) and not file(lcUpdateFile)
		lcDate    = 'date(' + transform(year(date())) + ', ' + ;
			transform(month(date())) + ', ' + transform(day(date())) + ')'
		lcContent = filetostr(lcUpdateTemplateFile)
		lcContent = strtran(lcContent, '{APPNAME}',    pcAppName, ;
			-1, -1, 1)
		lcContent = strtran(lcContent, '{APPID}',      pcAppID, ;
			-1, -1, 1)
		lcContent = strtran(lcContent, '{CURRDATE}',   lcDate, ;
			-1, -1, 1)
		lcContent = strtran(lcContent, '{REPOSITORY}', lcRepository, ;
			-1, -1, 1)
		lcContent = strtran(lcContent, '{COMPONENT}',  lcComponent, ;
			-1, -1, 1)
		strtofile(lcContent, lcUpdateFile)
	endif file(lcUpdateTemplateFile) ...

	* Zip the source files.

	ExecScript(_Screen.cThorDispatcher, 'Thor_Proc_ZipFolder', lcInstalledFilesFolder, lcZipFile)

	* Add AppID.zip and AppIDVersion.txt to the repository.
	
*SF 20230512: flag to disable git
	if plRun_git
		lcCommand = 'git add ' + lcZipFile + ' -f'
		run &lcCommand
		lcCommand = 'git add ' + lcVersionFile
		run &lcCommand

* Add the BuildProcess files to the repository.

		for lnI = 1 to adir(laFiles, 'BuildProcess\*.*', '', 1)
			lcFile = laFiles[lnI, 1]
			if lower(justext(lcFile)) <> 'fxp'
				lcCommand = 'git add BuildProcess\' + lcFile
				run &lcCommand
			endif lower(justext(lcFile)) <> 'fxp'
		next lnI
	endif plRun_git

	if file(lcAfterBuildProgram)
		do (lcAfterBuildProgram)
	endif file(lcAfterBuildProgram)


	MessageBox('Deployment for ' + lcProjectName + ' complete', 64, 'All done', 5000)

EndProc 

Procedure SetDocumentation (tcCurrFolder, tcVFPXDeploymentFolder, tcRepository)
*check for several VFPX defaults:
set step on
	lcVersionDateD = STUFF(STUFF(dtoc(pdVersionDate, 1), 7, 0, '-'), 5, 0, '-')

	if not file(tcCurrFolder + 'README.md')
		copy file (tcVFPXDeploymentFolder + 'VFPXTemplate\README.md') to ;
			README.md

*alter
		lcText = filetostr('README.md')
		lcText = strtran(lcText,'{APPNAME}',pcAppName)
*remove comment
		lcText = stuff(lcText,1,at('-->',lcText) + 2,'')
		lcText = ReplacePlaceholders (lcText, lcVersionDateD)
		strtofile(lcText, 'README.md')
	else  not file(tcCurrFolder + 'README.md')
		lcText = filetostr('README.md')
		lcText = ReplacePlaceholders (lcText, lcVersionDateD)
		strtofile(lcText, 'README.md')
	endif not file(tcCurrFolder + 'README.md')

	if not file(tcCurrFolder + '.gitignore')
		copy file (tcVFPXDeploymentFolder + 'VFPXTemplate\C.gitignore') to ;
			.gitignore

*add head
		lcText = filetostr('.gitignore')
		lcText = strtran(lcText,chr(10),chr(10)+"#" + pcAppName +chr(10),1,1)
		strtofile(lcText, '.gitignore')
	endif not file(tcCurrFolder + '.gitignore')

	if not file(tcCurrFolder + '.gitattributes')
		copy file (tcVFPXDeploymentFolder + 'VFPXTemplate\.gitattributes') to ;
			.gitattributes

*add head
		lcText = filetostr('.gitattributes')
		lcText = strtran(lcText,chr(10),chr(10)+"#" + pcAppName +chr(10),1,1)
		strtofile(lcText, '.gitattributes')
	endif not file(tcCurrFolder + '.gitattributes')

	if not directory(tcCurrFolder + '.github')
		mkdir .github
		copy file (tcVFPXDeploymentFolder + 'VFPXTemplate\.github\*.*') to ;
			.github\*.*
	
		mkdir .github\ISSUE_TEMPLATE
		copy file (tcVFPXDeploymentFolder + 'VFPXTemplate\.github\ISSUE_TEMPLATE\*.*') to ;
			.github\ISSUE_TEMPLATE\*.*

*alter CONTRIBUTING.md
		if file('.github\CONTRIBUTING.md')
			lcText = filetostr('.github\CONTRIBUTING.md')
*remove comment
			lcText = stuff(lcText,1,at('-->',lcText) + 2,'')
*replace
			lcText = strtran(lcText,'{APPNAME}',pcAppName)
			lcText = strtran(lcText,'{REPOSITORY}',tcRepository)
			lcText = strtran(lcText,'{CVERSIONDATE}',lcVersionDateD)
			strtofile(lcText, '.github\CONTRIBUTING.md')
		endif file('.github\CONTRIBUTING.md')
	endif not directory(tcCurrFolder + '.github')

	if not directory(tcCurrFolder + 'docs')
		mkdir docs
		copy file (tcVFPXDeploymentFolder + 'VFPXTemplate\docs\*.*') to ;
			docs\*.*

*alter documentation.md
		if file('docs\documentation.md')
			lcText = filetostr('docs\documentation.md')
*remove comment
			lcText = stuff(lcText,1,at('-->',lcText) + 2,'')
*replace
			lcText = strtran(lcText,'{APPNAME}',pcAppName)
			lcText = strtran(lcText,'{CVERSIONDATE}',lcVersionDateD)
			strtofile(lcText, 'docs\documentation.md')
		endif file('docs\documentation.md')
	endif not directory(tcCurrFolder + 'docs')

	if not directory(tcCurrFolder + 'images')
		mkdir images
		copy file (tcVFPXDeploymentFolder + 'VFPXTemplate\images\*.*') to ;
			images\*.*
	
	endif not directory(tcCurrFolder + 'images')

EndProc 

Procedure ReplacePlaceholders (tcText, tcVersionDateD)

	for lnOccurence = 1 to occurs('<!--VERNO-->', upper(tcText))
	 lnStart = atc('<!--VerNo-->', tcText, lnOccurence)
	 lnLen   = atc('<!--/VerNo-->', SUBSTR(tcText,lnStart))
*	 tcText  = stuff(tcText, lnStart, lnLen, '<!--VerNo-->' + pcFullVersion)
     if lnlen>0 
	 	tcText  = stuff(tcText, lnStart, lnLen - 1, '<!--VERNO-->' + pcFullVersion)
     endif lnlen>0 
	next

	for lnOccurence = 1 to occurs('<!--DEPLOYMENTDATE-->', upper(tcText))
	 lnStart = atc('<!--DeploymentDate-->', tcText, lnOccurence)
	 lnLen   = atc('<!--/DeploymentDate-->', SUBSTR(tcText,lnStart))
*	 tcText  = stuff(tcText, lnStart, lnLen, '<!--DeploymentDate-->' + tcVersionDateD)
     if lnlen>0 
		 tcText  = stuff(tcText, lnStart, lnLen - 1, '<!--DeploymentDate-->' + tcVersionDateD)
     endif lnlen>0 
	next

	return tcText
endproc

#Define CRLF chr[13] + chr[10] 

Procedure CheckVersionFile(lcVersionFile)
	Local lcErrorMsg, llSuccess, loException, loUpdater

	loUpdater  = Execscript (_Screen.cThorDispatcher, 'Thor_Proc_GetUpdaterObject2')
	Try
		Do (m.lcVersionFile) With m.loUpdater
		llSuccess = .T.
	Catch To m.loException
		llSuccess = .F.
	Endtry

	If m.llSuccess = .F.
		lcErrorMsg = 'Error in Version file:' 		+ CRLF + 			;
			'Msg:   ' + m.loException.Message 		+ CRLF +			;
			'Code:  ' + m.loException.LineContents
		Messagebox(m.lcErrorMsg, 16, 'ABORTING')
	Endif

	Return m.llSuccess

Endproc
