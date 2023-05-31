#define CRLF chr(13) + chr(10)

lparameters;
	tcFolder

* Parameter tcFolder is the home folder for the project
* If no folder is given, this procedure assumes to run stand-alone

if !empty(tcFolder) and directory(tcFolder) then
	do main with m.tcFolder
else  &&!empty(tcFolder) AND directory(tcFolder)
	local;
		lcProjectFolder as string

	addproperty(_screen, 'VFPX_DeployStartFolder', fullpath("", ""))

* ================================================================================

	lcProjectFolder	 = GetProject_Folder(_screen.VFPX_DeployStartFolder)

	if directory(m.lcProjectFolder) then

		do main with m.lcProjectFolder
	endif &&directory(m.lcProjectFolder)
* ================================================================================

	cd (_screen.VFPX_DeployStartFolder)
	removeproperty(_screen, 'VFPX_DeployStartFolder')
endif &&!empty(tcFolder) AND directory(tcFolder)

procedure main (tcFolder)

	local;
		lcCurrFolder        as string,;
		lcProjectName       as string,;
		lcVFPXDeploymentFolder as string

* Get the project folder.
	if empty(m.tcFolder) then
		messagebox('Parameter tcFolder could not be empty in Main.', ;
			16, 'VFPX Project Deployment')
		return
	endif &&EMPTY(m.tcFolder)

	cd (m.tcFolder) && Project Home

* Bug out if NoVFPXDeployment.txt exists.

	if file(addbs(m.tcFolder) + 'NoVFPXDeployment.txt') then
		messagebox('VFPX Project Deployment will not run because NoVFPXDeployment.txt exists.', ;
			16, 'VFPX Project Deployment')
		return
	endif &&file(addbs(m.tcFolder) + 'NoVFPXDeployment.txt')

* Create the BuildProcess subdirectory of the project folder if necessary.

	lcCurrFolder = addbs(addbs(m.tcFolder) + 'BuildProcess') && BuildProcess
	if not directory(m.lcCurrFolder) then
*SF 20230512 we better check if a different Thor exists
* this is not fool-proof, since there are many ways to do Thor
* but a very common one
		if directory(addbs(m.tcFolder) + 'ThorUpdater') then
			messagebox('There is already a Thor folder.' + CRLF + CRLF + 'Stoped.' + CRLF + CRLF + 'You need to carefully create the setup manually.', ;
				16, 'VFPX Project Deployment')
			return
		endif &&directory(addbs(m.tcFolder) + 'ThorUpdater')
		md (m.lcCurrFolder)
	endif &&not directory(m.lcCurrFolder)

* If we don't have ProjectSettings.txt, copy it, VersionTemplate.txt, and
* BuildMe.prg, AfterBuild.prg from the VFPXDeployment folder.
* Stop process to let the user set up the tool

	lcVFPXDeploymentFolder = _screen.cThorFolder + 'Tools\Apps\VFPXDeployment\'

	if not file(m.lcCurrFolder + 'ProjectSettings.txt') then
		copy file (m.lcVFPXDeploymentFolder + 'ProjectSettings.txt') to ;
			(m.lcCurrFolder + 'ProjectSettings.txt')
		copy file (m.lcVFPXDeploymentFolder + 'VersionTemplate.txt') to ;
			(m.lcCurrFolder + 'VersionTemplate.txt')
		copy file (m.lcVFPXDeploymentFolder + 'BuildMe.prg') to ;
			(m.lcCurrFolder + 'BuildMe.prg')
		copy file (m.lcVFPXDeploymentFolder + 'AfterBuild.prg') to ;
			(m.lcCurrFolder + 'AfterBuild.prg')
		messagebox('Please edit ProjectSettings.txt and fill in the settings ' + ;
			'for this project.' + CRLF + ;
			'Also, edit InstalledFiles.txt and specify ' + ;
			'which files should be installed.' + CRLF +  CRLF +;
			'Then run VFPX Project Deployment again.', ;
			16, 'VFPX Project Deployment')
		modify file (m.lcCurrFolder + 'ProjectSettings.txt') nowait
		modify file (m.lcCurrFolder + 'InstalledFiles.txt') nowait
		return
	endif &&not file(m.lcCurrFolder + 'ProjectSettings.txt')

	lcProjectName = getwordnum(m.lcCurrFolder, getwordcount(m.lcCurrFolder, '\') - 1, '\')

	Deploy(m.lcVFPXDeploymentFolder, m.lcProjectName, addbs(m.tcFolder))

* Restore the former current directory.

	removeproperty(_screen, 'VFPX_Deploy_StartFolder')

	return

endproc &&Main

* ================================================================================
* ================================================================================
* The work horse - put in separate Proc so that any the cd (lcStartFolder) is always run

procedure Deploy
	lparameters;
		tcVFPXDeploymentFolder,;
		tcProjectName,;
		tcCurrFolder


* Put the paths for files we may use into variables.

	local;
		lcAfterBuildProgram  as string,;
		lcAppFile            as string,;
		lcBin2PRGFolder      as string,;
		lcBin2PRGFolderSource as string,;
		lcBuildProgram       as string,;
		lcCategory           as string,;
		lcChange             as string,;
		lcCommand            as string,;
		lcComponent          as string,;
		lcContent            as string,;
		lcErrFile            as string,;
		lcFile               as string,;
		lcFiles              as string,;
		lcFolder             as string,;
		lcFoxBin2PRG         as string,;
		lcInstalledFilesFolder as string,;
		lcInstalledFilesListing as string,;
		lcSubstituteListing  as string,;
		lcLine               as string,;
		lcName               as string,;
		lcPJXFile            as string,;
		lcProjectFile        as string,;
		lcProjectSettings    as string,;
		lcRecompile          as string,;
		lcRepositoryRoot     as string,;
		lcSource             as string,;
		lcTarget             as string,;
		lcUName              as string,;
		lcUpdateFile         as string,;
		lcUpdateTemplateFile as string,;
		lcValue              as string,;
		lcVersion            as string,;
		lcVersionFile        as string,;
		lcVersionFileR       as string,;
		lcVersionTemplateFile as string,;
		lcZipFile            as string,;
		llInclude_VFPX       as boolean,;
		llInclude_Thor       as boolean,;
		llPrompt             as boolean,;
		llRecompile          as boolean,;
		llClear_InstalledFiles as boolean,;
		lnBin2PRGFolders     as number,;
		lnFiles              as number,;
		lnI                  as number,;
		lnJulian             as number,;
		lnPos                as number,;
		lnProject            as number,;
		lnSettings           as number
	local lnWords


	local array;
		laBin2PRGFolders(1),;
		laFiles(1,1),;
		laWords(1,1),;
		laSettings(1)

	lcProjectFile           = m.tcCurrFolder + 'BuildProcess\ProjectSettings.txt'
	lcInstalledFilesListing = m.tcCurrFolder + 'BuildProcess\InstalledFiles.txt'
	lcSubstituteListing     = m.tcCurrFolder + 'BuildProcess\Substitute.txt'
	lcInstalledFilesFolder  = 'InstalledFiles'
	lcBuildProgram          = m.tcCurrFolder + 'BuildProcess\BuildMe.prg'
	lcAfterBuildProgram     = m.tcCurrFolder + 'BuildProcess\AfterBuild.prg'
	lcVersionTemplateFile   = m.tcCurrFolder + 'BuildProcess\VersionTemplate.txt'
	lcUpdateTemplateFile    = _screen.cThorFolder + ;
		'Tools\Apps\VFPXDeployment\Thor_Update_Template.txt'

* Get the current project settings into public variables.

	lcProjectSettings = filetostr(m.lcProjectFile)

* Release the PUBLICS in ReleaseThis procedure
	public;
		pcAppName     as string,;
		pcAppID       as string,;
		pcVersion     as string,;
		pdVersionDate as date,;
		pcVersionDate as string,;
		pcChangeLog   as string,;
		plContinue    as boolean,;
		pcFullVersion as string,;
		pcDate        as string,;
		pcJulian      as string,;
		pcThisDate    as string,;
		pcRepository  as string,;
		plRun_Bin2Prg as boolean,;
		plRun_git     as boolean

	pdVersionDate = date()
	pcVersion     = ''
	pcChangeLog   = ''
	plContinue    = .t.
*SF 20230512: add new flags
	pcFullVersion = ''		&& For autoset README.MD. Full version info. Either pcVersion or returned from BuilMe.prg
	plRun_Bin2Prg = .t.		&& Run FoxBin2Prg; from ProjectSettings.txt
	plRun_git     = .t.		&& Run git; from ProjectSettings.txt
*/SF 20230512
	llPrompt              = .t.
	lcBin2PRGFolderSource = ''
	lcComponent           = 'Yes'
	lcCategory            = 'Applications'
	lcPJXFile             = ''
	llRecompile           = .f.
	lcAppFile             = ''
	lcRepositoryRoot      = 'https://github.com/VFPX/'
	pcRepository          = ''
	llInclude_VFPX        = .f.
	llInclude_Thor        = .t.
	lnSettings            = alines(laSettings, m.lcProjectSettings)

	for lnI = 1 to m.lnSettings
		lcLine  = laSettings[m.lnI]
		lnPos   = at('=', m.lcLine)
		lcName  = alltrim(left(m.lcLine, m.lnPos - 1))
		lcValue = alltrim(substr(m.lcLine, m.lnPos + 1))
		lcUName = upper(m.lcName)
		do case
			case m.lcUName == 'APPNAME'
				pcAppName = m.lcValue
			case m.lcUName == 'APPID'
				pcAppID = m.lcValue
			case m.lcUName == 'VERSION'
				pcVersion = m.lcValue
			case m.lcUName == 'VERSIONDATE'
				pdVersionDate = evaluate('{^' + m.lcValue + '}')
			case m.lcUName == 'PROMPT'
				llPrompt = upper(m.lcValue) = 'Y'
			case m.lcUName == 'CHANGELOG'
				pcChangeLog = m.lcValue
			case m.lcUName == 'BIN2PRGFOLDER'
				lcBin2PRGFolderSource = m.lcValue
			case m.lcUName == 'COMPONENT'
				lcComponent = m.lcValue
			case m.lcUName == 'CATEGORY'
				lcCategory = m.lcValue
			case m.lcUName == 'PJXFILE'
				lcPJXFile = m.lcValue
			case m.lcUName == 'RECOMPILE'
				llRecompile = upper(m.lcValue) = 'Y'
			case m.lcUName == 'APPFILE'
				lcAppFile = m.lcValue
			case m.lcUName == 'REPOSITORY'
				pcRepository = m.lcValue
			case m.lcUName == 'INSTALLEDFILESFOLDER'
				lcInstalledFilesFolder = m.lcValue
*SF 20230512: new flags
			case m.lcUName == 'CLEAR_INSTALLEDFILES'
				llClear_InstalledFiles = upper(m.lcValue) = 'Y'
			case m.lcUName == 'RUNBIN2PRG'
				plRun_Bin2Prg = upper(m.lcValue) = 'Y'
			case m.lcUName == 'RUNGIT'
				plRun_git = upper(m.lcValue) = 'Y'
			case m.lcUName == 'INCLUDE_VFPX'
				llInclude_VFPX = upper(m.lcValue) = 'Y'
			case m.lcUName == 'INCLUDE_THOR'
				llInclude_Thor = upper(m.lcValue) = 'Y'
			case m.lcUName == 'VERSIONFILE_REMOTE'
				lcVersionFileR = m.lcValue
*/SF 20230512
		endcase
	next &&lnI

*SF 20230512, get pjx version
	if upper(m.pcVersion)=='PJX' then
		pcVersion = ''
		if empty(m.lcPJXFile) then
*use the active pjx, since no pjx is defined
			if type("_VFP.ActiveProject")='O' then
				pcVersion = _vfp.activeproject.versionnumber

			endif &&type("_VFP.ActiveProject")='O'
		else  &&empty(m.lcPJXFile)
*use pjx defined
*bit more work
*see if the project is open
			for lnProject = 1 to _vfp.projects.count
				if upper(fullpath(m.lcPJXFile))==upper(_vfp.projects(m.lnProject).name) then
					pcVersion = _vfp.projects(m.lnProject).versionnumber
					exit

				endif &&upper(fullpath(m.lcPJXFile))==upper(_vfp.projects(m.lnProject).name)
			endfor &&lnProject

			if empty(m.pcVersion);
					and file(fullpath(m.lcPJXFile)) then
				modify project (fullpath(m.lcPJXFile)) nowait noshow noprojecthook
				pcVersion = _vfp.projects(m.lnProject).versionnumber
				_vfp.activeproject.close

			endif &&empty(m.pcVersion) and file(fullpath(m.lcPJXFile))
		endif &&empty(m.lcPJXFile)

		if empty(m.pcVersion) then
			messagebox('No project found to read version number.', 16, ;
				'VFPX Project Deployment')
			ReleaseThis()
			return

		endif &&empty(m.pcVersion)
	endif &&upper(m.pcVersion)=='PJX'
* Ensure we have valid pcAppName and pcAppID values.

	if empty(m.pcAppName) then
		messagebox('The AppName setting was not specified.', 16, ;
			'VFPX Project Deployment')
		ReleaseThis()
		return
	endif &&empty(m.pcAppName)

	if empty(m.pcAppID) then
		messagebox('The AppID setting was not specified.', 16, ;
			'VFPX Project Deployment')
		ReleaseThis()
		return
	endif &&empty(m.pcAppID)

	if ' ' $ m.pcAppID or '	' $ m.pcAppID then
		messagebox('The AppID setting cannot have spaces or tabs.', 16, ;
			'VFPX Project Deployment')
		ReleaseThis()
		return
	endif &&' ' $ m.pcAppID or '	' $ m.pcAppID

* If we're supposed to build an APP or EXE, ensure we have both settings
* and we're running VFP 9 and not VFP Advanced since the APP/EXE structure
* is different. If AppFile is omitted, use the same folder and name as the
* PJX file.

	if not empty(m.lcPJXFile) and empty(m.lcAppFile) then
		lcAppFile = forceext(m.lcPJXFile, 'app')
	endif &&not empty(m.lcPJXFile) and empty(m.lcAppFile)

	if (empty(m.lcPJXFile) and not empty(m.lcAppFile)) or ;
			(empty(m.lcAppFile) and not empty(m.lcPJXFile)) then
		messagebox('If you specify one of them, you have to specify both ' + ;
			'PJXFile and AppFile.', 16, 'VFPX Project Deployment')
		ReleaseThis()
		return
	endif &&(empty(m.lcPJXFile) and not empty(m.lcAppFile)) or (empty(m.lcAppFile) and not empty(m.lcPJXFile))

	if not empty(m.lcPJXFile) and val(version(4)) > 9 then
		messagebox('You must run VFPX Project Deployment using VFP 9 not VFP Advanced.', ;
			16, 'VFPX Project Deployment')
		ReleaseThis()
		return
	endif &&not empty(m.lcPJXFile) and val(version(4)) > 9

	if empty(m.lcVersionFileR) then
		lcVersionFileR = m.pcAppID + 'Version.txt'
	endif &&EMPTY(lcVersionFileR)

* If Bin2PRGFolderSource or PJXFile was supplied, find FoxBin2PRG.EXE.

	lcBin2PRGFolder = ''
	lcFoxBin2PRG    = ''
	if m.plRun_Bin2Prg and (not empty(m.lcBin2PRGFolderSource) or not empty(m.lcPJXFile)) then
		lcFoxBin2PRG = execscript(_screen.cThorDispatcher, 'Thor_Proc_GetFoxBin2PrgFolder') + ;
			'FoxBin2Prg.exe'

		do case
			case not file(m.lcFoxBin2PRG)
				messagebox('FoxBin2PRG.EXE not found.', 16, ;
					'VFPX Project Deployment')
				ReleaseThis()
				return
* &&not file(m.lcFoxBin2PRG)

			case not empty(m.lcBin2PRGFolderSource)
				lnBin2PRGFolders = alines(laBin2PRGFolders, m.lcBin2PRGFolderSource, 4, ',')
				for lnI = 1 to m.lnBin2PRGFolders
					lcFolder                = laBin2PRGFolders[m.lnI]
					laBin2PRGFolders[m.lnI] = fullpath(m.tcCurrFolder + m.lcFolder)
					if not directory(laBin2PRGFolders[m.lnI]) then
						messagebox('Folder "' + m.lcFolder + '" not found.', 16,	;
							'VFPX Project Deployment')
						ReleaseThis()
						return

					endif &&not directory(laBin2PRGFolders[m.lnI])
				next &&lnI
* &&not empty(m.lcBin2PRGFolderSource)

		endcase
	endif &&m.plRun_Bin2Prg and (not empty(m.lcBin2PRGFolderSource) or not empty(m.lcPJXFile))

* Get the names of the zip, Thor CFU version, and Thor updaters files and set pcVersionDate to
* a string version of the release date.

	lcZipFile     = 'ThorUpdater\' + m.pcAppID + '.zip'
	lcVersionFile = 'ThorUpdater\' + m.lcVersionFileR
	lcUpdateFile  = m.tcCurrFolder + 'BuildProcess\Thor_Update_' + m.pcAppID + '.prg'
	pcDate        = dtoc(m.pdVersionDate, 1)
	pcVersionDate = stuff(stuff(m.pcDate, 7, 0, '-'), 5, 0, '-')

	lnJulian = m.pdVersionDate - {^2000-01-01}
	pcJulian = padl(m.lnJulian, 5, '0')

	pcThisDate = 'date(' + transform(year(date())) + ', ' + ;
		transform(month(date())) + ', ' + transform(day(date())) + ')'

* Get the repository to use if it wasn't specified.

	if empty(m.pcRepository) then
		pcRepository = m.lcRepositoryRoot + m.pcAppID
	endif &&empty(m.pcRepository)

* Get the version number if it wasn't specified and we're supposed to.

	if empty(m.pcVersion) and m.llPrompt then
		lcValue = inputbox('Version', 'VFPX Project Deployment', '')
		if empty(m.lcValue) then
			ReleaseThis()
			return
		endif &&empty(m.lcValue)
		pcVersion = m.lcValue

	endif &&empty(m.pcVersion) and m.llPrompt

*SF 20230514 the test for the copy process here, we don't need to proceed if this is not here
	if (!file(m.lcInstalledFilesListing) and !directory(m.lcInstalledFilesFolder));
			or (file(m.lcInstalledFilesListing)) and empty(filetostr(m.lcInstalledFilesListing)) then
* If no InstalledFiles.txt exists, and no InstalledFiles folder, break
		messagebox('Please either create InstalledFiles.txt in the ' + ;
			'BuildProcess folder with each file to be installed by Thor ' + ;
			'listed on a separate line, or create a subdirectory of ' + ;
			'the project folder named InstalledFiles and copy the ' + ;
			'files Thor should install to it.', ;
			16, 'VFPX Project Deployment')
		ReleaseThis()
		return

	endif &&(!file(m.lcInstalledFilesListing) and !directory(m.lcInstalledFilesFolder)) or ...

	pcFullVersion = m.pcVersion

* Execute BuildMe.prg if it exists. If it sets plContinue to .F., exit.

	if file(m.lcBuildProgram) then
		do (m.lcBuildProgram)
		if not m.plContinue
			ReleaseThis()
			return

		endif &&not m.plContinue
	endif &&file(m.lcBuildProgram)

	if empty(m.pcVersion) then
		messagebox('The version setting was not specified.', 16, ;
			'VFPX Project Deployment')
		ReleaseThis()
		return
	endif &&empty(m.pcVersion)

*** JRN 2023-01-10 : Call FoxBin2PRG, if applicable
*SF 20230512: flag to disable FoxBin2PRG
	if m.plRun_Bin2Prg and not empty(m.lcFoxBin2PRG) then
		if not empty(m.lcPJXFile)
			do (m.lcFoxBin2PRG) with fullpath(m.lcPJXFile), '*'
		endif &&not empty(m.lcPJXFile)

		if not empty(m.lcBin2PRGFolderSource) then
*** JRN 2023-01-29 : BIN2PRG for folder and sub-folders
			for lnI = 1 to m.lnBin2PRGFolders
				lcFolder = laBin2PRGFolders[m.lnI]
				do (m.lcFoxBin2PRG) with 'BIN2PRG', m.lcFolder && + '\*.*'

			next &&lnI
		endif &&not empty(m.lcBin2PRGFolderSource)
	endif &&m.plRun_Bin2Prg and not empty(m.lcFoxBin2PRG)

* Ensure we have a version number (Build.prg may have set it).

* Create an APP/EXE if we're supposed to.

	lcRecompile = iif(m.llRecompile, 'recompile', '')
	do case
		case empty(m.lcPJXFile)
		case upper(justext(m.lcAppFile)) = 'EXE'
			build exe (m.lcAppFile) from (m.lcPJXFile) &lcRecompile
		otherwise
			build app (m.lcAppFile) from (m.lcPJXFile) &lcRecompile
	endcase

	lcErrFile = forceext(m.lcAppFile, 'err')

	if not empty(m.lcPJXFile) and file(m.lcErrFile) then
		messagebox('An error occurred building the project.' + CRLF +;
			' Please see the ERR file for details.', 16, 'VFPX Project Deployment')
		modify file (m.lcErrFile) nowait
		ReleaseThis()
		return

	endif &&not empty(m.lcPJXFile) and file(m.lcErrFile)

	SetDocumentation (m.tcCurrFolder, m.tcVFPXDeploymentFolder, m.llInclude_VFPX, m.lcSubstituteListing)

*SF 20230514 the test is moved to a place above, so no processing is done
	if m.llInclude_Thor then
		if file(m.lcInstalledFilesListing) then
			if m.llClear_InstalledFiles then
				loFSO = createobject("Scripting.FileSystemObject")
				loFSO.DeleteFolder(fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder), .t.)
			endif &&m.llClear_InstalledFiles
* If InstalledFiles.txt exists, copy the files listed in it to the
* InstalledFiles folder (folders are created as necessary).
			lcFiles = filetostr(m.lcInstalledFilesListing)
			lnFiles = alines(laFiles, m.lcFiles, 1 + 4)
*include
			for lnI = 1 to m.lnFiles
				lnWords  = alines(laWords, strtran(laFiles[m.lnI], '||', 0h00), 1 + 2, 0h00)
				lcSource = laWords[1]
				lcTarget = iif(m.lnWords=1, laWords[1],  laWords[2])
				if inlist(left(ltrim(m.lcSource), 1), '#', '!') then
					loop
				endif &&inlist(left(ltrim(m.lcSource), 1), '#', '!')
				if empty(m.lcSource) then
*not the toplevel folder (aka project root)
					loop
				endif &&empty(m.lcSource)
				if m.lcTarget == '\' then
*special: Folder .\InstalledFiles for substructure
					lcTarget = ''
				endif &&m.lcTarget == '\' then

				if right(m.lcSource, 1) == '\' then
* just with subfolders
					ScanDir_InstFiles(m.tcCurrFolder + m.lcSource, addbs(fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + m.lcTarget, .F.)
				else
* just file / skeleton
					Copy_InstallFile(m.tcCurrFolder + m.lcSource, addbs(fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + m.lcTarget)
				endif

			next &&lnI
*exclude (iow remove after copy)
			for lnI = 1 to m.lnFiles
				if !left(ltrim(laFiles[m.lnI]), 1) == '!' then
					loop
				endif &&!left(ltrim(laFiles[m.lnI]), 1) == '!'
				lcSource = SUBSTR(laFiles[m.lnI], 2)
				if empty(m.lcSource) then
*not the toplevel folder (aka project root)
					loop
				endif &&empty(m.lcSource)

* only pattern through all folders in lcInstalledFilesFolder
				ScanDir_InstFiles(ADDBS(fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)), m.lcSource, .T.)

			next &&lnI
		endif &&file(m.lcInstalledFilesListing)

		if not file(addbs(fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + '.gitignore')
*ignore all in staging folder
			strtofile('#.gitignore by VFPX Deployment' + CRLF + '*.*' , addbs(fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + '.gitignore')
		endif &&not file(addbs(fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + '.gitignore')

* Create the ThorUpdater folder if necessary.

		if not directory('ThorUpdater') then
			md ThorUpdater
		endif &&not directory('ThorUpdater')

* Update Version.txt.
		lcVersion = filetostr(m.lcVersionTemplateFile)

		lcChange  = iif(file(m.pcChangeLog), filetostr(m.pcChangeLog), '')
		lcVersion = strtran(m.lcVersion, '{CHANGELOG}', m.lcChange,     -1, -1, 1)
		lcVersion = strtran(m.lcVersion, '{COMPONENT}', m.lcComponent,  -1, -1, 1)
		lcVersion = strtran(m.lcVersion, '{CATEGORY}',  m.lcCategory,   -1, -1, 1)

		lcVersion = ReplacePlaceholders_Once(m.lcVersion)

		strtofile(m.lcVersion, m.lcVersionFile)

* check proposed version file for errors
		if CheckVersionFile(m.lcVersionFile) = .f. then
			ReleaseThis()
			return

		endif &&CheckVersionFile(m.lcVersionFile) = .f.
		erase (forceext(m.lcVersionFile, 'fxp'))

* Update Thor_Update program.

		if file(m.lcUpdateTemplateFile) and not file(m.lcUpdateFile) then

			lcContent = filetostr(m.lcUpdateTemplateFile)

			lcContent = ReplacePlaceholders_Once(m.lcContent)

			lcContent = strtran(m.lcContent, '{COMPONENT}', m.lcComponent, ;
				-1, -1, 1)
			lcContent = strtran(m.lcContent, '{VERSIONFILE}', m.lcVersionFileR, ;
				-1, -1, 1)
			strtofile(m.lcContent, m.lcUpdateFile)

		endif &&file(m.lcUpdateTemplateFile) and not file(m.lcUpdateFile)

* Zip the source files.
		lcContent = ''
		if file(addbs(fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + '.gitignore')
*ignore all in staging folder
			lcContent = filetostr(addbs(fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + '.gitignore')
			delete file (addbs(fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + '.gitignore')
		endif &&file(addbs(fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + '.gitignore')

		execscript(_screen.cThorDispatcher, 'Thor_Proc_ZipFolder', m.lcInstalledFilesFolder, m.lcZipFile)

		if not empty(m.lcContent)
*ignore all in staging folder
			strtofile(m.lcContent, addbs(fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + '.gitignore')
		endif &&not empty(m.lcContent)

* Add AppID.zip and AppIDVersion.txt to the repository.

*SF 20230512: flag to disable git
		if m.plRun_git then
			lcCommand = 'git add ' + m.lcZipFile + ' -f'
			run &lcCommand
			lcCommand = 'git add ' + m.lcVersionFile
			run &lcCommand

* Add the BuildProcess files to the repository.

			for lnI = 1 to adir(laFiles, 'BuildProcess\*.*', '', 1)
				lcFile = laFiles[m.lnI, 1]
				if lower(justext(m.lcFile)) <> 'fxp' then
					lcCommand = 'git add BuildProcess\' + m.lcFile
					run &lcCommand

				endif &&lower(justext(m.lcFile)) <> 'fxp'
			next &&lnI
		endif &&plRun_git
	endif &&m.llInclude_Thor

* Execute AfterBuild.prg if it exists.

*preserve tcProjectName
	addproperty(_screen, 'VFPX_Deploy_ProjectName', m.tcProjectName)

	if file(m.lcAfterBuildProgram) then
		do (m.lcAfterBuildProgram)
	endif &&file(m.lcAfterBuildProgram)

	ReleaseThis()

	messagebox('Deployment for ' + _screen.VFPX_Deploy_ProjectName + ' complete.' +  CRLF +  CRLF + 'All done', 64, 'VFPX Project Deployment', 5000)

	removeproperty(_screen, 'VFPX_Deploy_ProjectName')

endproc &&Deploy

procedure SetDocumentation
	lparameters;
		tcCurrFolder,;
		tcVFPXDeploymentFolder,;
		tlInclude_VFPX,;
		tcSubstituteListing

*check for several VFPX defaults:
	local;
		lcText as string,;
		lnFile as number
	local lcFiles,lcSource,lnFiles,lnI


	local array;
		laFiles(1, 1)

	if not file(m.tcCurrFolder + 'README.md') then
		if m.tlInclude_VFPX then
			lcText = filetostr(m.tcVFPXDeploymentFolder + 'VFPXTemplate\R_README.md')
			lcText = ReplacePlaceholders_Once(m.lcText)
			lcText = ReplacePlaceholders_Run (m.lcText)
			strtofile(m.lcText, 'README.md')

		endif &&m.tlInclude_VFPX
	else  &&not file(m.tcCurrFolder + 'README.md')
		if file(m.tcCurrFolder + 'README.md') then
			lcText = filetostr('README.md')
			lcText = ReplacePlaceholders_Run (m.lcText)
			strtofile(m.lcText, 'README.md')

		endif &&file(m.tcCurrFolder + 'README.md')
	endif &&not file(m.tcCurrFolder + 'README.md')

	if m.tlInclude_VFPX then
		if not file(m.tcCurrFolder + 'BuildProcess\README.md') then
			lcText = filetostr(m.tcVFPXDeploymentFolder + 'VFPXTemplate\B_README.md')
			lcText = ReplacePlaceholders_Once(m.lcText)
			lcText = ReplacePlaceholders_Run (m.lcText)
			strtofile(m.lcText, 'BuildProcess\README.md')
		endif &&not file(m.tcCurrFolder + 'BuildProcess\README.md')

		if not file(m.tcCurrFolder + 'BuildProcess\.gitignore') then
			lcText = filetostr(m.tcVFPXDeploymentFolder + 'VFPXTemplate\B.gitignore')
			lcText = ReplacePlaceholders_Once(m.lcText)
			strtofile(m.lcText, 'BuildProcess\.gitignore')
		endif &&not file(m.tcCurrFolder + 'BuildProcess\README.md')

		if not file(m.tcCurrFolder + 'ThorUpdater\README.md') then
			lcText = filetostr(m.tcVFPXDeploymentFolder + 'VFPXTemplate\T_README.md')
			lcText = ReplacePlaceholders_Once(m.lcText)
			lcText = ReplacePlaceholders_Run (m.lcText)
			strtofile(m.lcText, 'ThorUpdater\README.md')
		endif &&not file(m.tcCurrFolder + 'ThorUpdater\README.md')

		if not file(m.tcCurrFolder + 'ThorUpdater\.gitignore') then
			lcText = filetostr(m.tcVFPXDeploymentFolder + 'VFPXTemplate\T.gitignore')
			lcText = ReplacePlaceholders_Once(m.lcText)
			strtofile(m.lcText, 'ThorUpdater\.gitignore')
		endif &&not file(m.tcCurrFolder + 'ThorUpdater\README.md')

		if not file(m.tcCurrFolder + '.gitignore') then
			lcText = filetostr(m.tcVFPXDeploymentFolder + 'VFPXTemplate\C.gitignore')
			lcText = ReplacePlaceholders_Once(m.lcText)
			strtofile(m.lcText, '.gitignore')
		endif &&not file(m.tcCurrFolder + '.gitignore')

		if not file(m.tcCurrFolder + '.gitattributes') then
			lcText = filetostr(m.tcVFPXDeploymentFolder + 'VFPXTemplate\R.gitattributes')
			lcText = ReplacePlaceholders_Once(m.lcText)
			strtofile(m.lcText, '.gitattributes')
		endif &&not file(m.tcCurrFolder + '.gitattributes')

		if not directory(m.tcCurrFolder + '.github') then
			mkdir .github
			copy file (m.tcVFPXDeploymentFolder + 'VFPXTemplate\.github\*.*') to ;
				.github\*.*

			for lnFile = 1 to adir(laFiles,'.github\*.*')
				lcText = filetostr('.github\' + laFiles(m.lnFile, 1))
				lcText = ReplacePlaceholders_Once(m.lcText)
				strtofile(m.lcText, '.github\' + forceext(laFiles(m.lnFile, 1),lower(justext(laFiles(m.lnFile, 1)))))

			endfor &&lnFile

			mkdir .github\ISSUE_TEMPLATE
			copy file (m.tcVFPXDeploymentFolder + 'VFPXTemplate\.github\ISSUE_TEMPLATE\*.*') to ;
				.github\ISSUE_TEMPLATE\*.*

			for lnFile = 1 to adir(laFiles,'.github\ISSUE_TEMPLATE\*.*')
				lcText = filetostr('.github\ISSUE_TEMPLATE\' + laFiles(m.lnFile, 1))
				lcText = ReplacePlaceholders_Once(m.lcText)
				strtofile(m.lcText, '.github\ISSUE_TEMPLATE\' + lower(laFiles(m.lnFile, 1)))

			endfor &&lnFile

		endif &&not directory(m.tcCurrFolder + '.github')

		if not directory(m.tcCurrFolder + 'docs') then
			mkdir docs
			copy file (m.tcVFPXDeploymentFolder + 'VFPXTemplate\docs\*.*') to ;
				docs\*.*

			for lnFile = 1 to adir(laFiles,'docs\*.*')
				lcText = filetostr('docs\' + laFiles(m.lnFile, 1))
				lcText = ReplacePlaceholders_Once(m.lcText)
				strtofile(m.lcText, 'docs\' + laFiles(m.lnFile, 1))

			endfor &&lnFile
		endif &&not directory(m.tcCurrFolder + 'docs')

		if not directory(m.tcCurrFolder + 'docs\images') then
			mkdir docs\images
			copy file (m.tcVFPXDeploymentFolder + 'VFPXTemplate\docs\images\*.*') to ;
				docs\images\*.*
		endif &&not directory(m.tcCurrFolder + 'docs\images')
	endif


	if file(m.tcSubstituteListing) then
* If InstalledFiles.txt exists, copy the files listed in it to the
* InstalledFiles folder (folders are created as necessary).
		lcFiles = filetostr(m.tcSubstituteListing)
		lnFiles = alines(laFiles, m.lcFiles, 1 + 4)
*process includes
		for lnI = 1 to m.lnFiles
			lcSource = laFiles[m.lnI]
			if left(ltrim(m.lcSource), 1) == '#' then
				loop
			endif &&(left(ltrim(m.lcSource), 1) == '#'
			if right(m.lcSource, 1) == '\' then
* just with subfolders
				ScanDir_Templates(m.tcCurrFolder + m.lcSource)
			else
* just file / skeleton
				lcText = filetostr(m.tcCurrFolder + laFiles[m.lnI])
				lcText = ReplacePlaceholders_Run (m.lcText)
				strtofile(m.lcText,m.tcCurrFolder + laFiles[m.lnI])
			endif

		next &&lnI
	endif &&file(m.lcInstalledFilesListing)
endproc &&SetDocumentation

procedure ReplacePlaceholders_Once
	lparameters;
		tcText

	local;
		lcRemove as string,;
		lcText   as string,;
		lnI      as number

	lcText = strtran(m.tcText, '{APPNAME}',     m.pcAppName,    -1, -1, 1)
	lcText = strtran(m.lcText, '{APPID}',       m.pcAppID,      -1, -1, 1)
	lcText = strtran(m.lcText, '{CURRDATE}',    m.pcThisDate,   -1, -1, 1)
	lcText = strtran(m.lcText, '{VERSIONDATE}', m.pcDate,       -1, -1, 1)
	lcText = strtran(m.lcText, '{CVERSIONDATE}',m.pcVersionDate,-1, -1, 1)
	lcText = strtran(m.lcText, '{VERSION}',     m.pcVersion,    -1, -1, 1)
	lcText = strtran(m.lcText, '{JULIAN}',      m.pcJulian,     -1, -1, 1)
	lcText = strtran(m.lcText, '{REPOSITORY}',  m.pcRepository, -1, -1, 1)
	lcText = strtran(m.lcText, '{CHANGELOG_F}', m.pcChangeLog, -1, -1, 1)
	lcText = textmerge(m.lcText)

	for lnI = occurs('@@@', m.lcText) to 1 step -1
		lcRemove = strextract(m.lcText, '@@@', '\\\', m.lnI, 4)
		lcText   = strtran(m.lcText, m.lcRemove)

	next &&lnI

	return m.lcText
endproc &&ReplacePlaceholders_Once

procedure ReplacePlaceholders_Run
	lparameters;
		tcText

	local;
		lnLen    as number,;
		lnOccurence as number,;
		lnStart  as number

	for lnOccurence = 1 to occurs('<!--VERNO-->', upper(m.tcText))
		lnStart = atc('<!--VerNo-->', m.tcText, m.lnOccurence)
		lnLen   = atc('<!--/VerNo-->', substr(m.tcText,m.lnStart))
*	 tcText  = stuff(tcText, lnStart, lnLen, '<!--VerNo-->' + pcFullVersion)
		if m.lnLen>0 then
			tcText  = stuff(m.tcText, m.lnStart, m.lnLen - 1, '<!--VERNO-->' + pcFullVersion)

		endif &&m.lnLen>0
	next &&lnOccurence

	for lnOccurence = 1 to occurs('<!--DEPLOYMENTDATE-->', upper(m.tcText))
		lnStart = atc('<!--DeploymentDate-->', m.tcText, m.lnOccurence)
		lnLen   = atc('<!--/DeploymentDate-->', substr(m.tcText,m.lnStart))
*	 tcText  = stuff(tcText, lnStart, lnLen, '<!--DeploymentDate-->' + tcVersionDateD)
		if m.lnLen>0 then
			tcText  = stuff(m.tcText, m.lnStart, m.lnLen - 1, '<!--DeploymentDate-->' + pcVersionDate)

		endif &&m.lnLen>0
	next &&lnOccurence

	return m.tcText
endproc &&ReplacePlaceholders_Run

procedure CheckVersionFile
	lparameters;
		tcVersionFile

	local;
		lcErrorMsg as string,;
		llSuccess as boolean,;
		loException as object,;
		loUpdater as object

	loUpdater  = execscript (_screen.cThorDispatcher, 'Thor_Proc_GetUpdaterObject2')
	try
			do (m.tcVersionFile) with m.loUpdater
			llSuccess = .t.
		catch to m.loException
			llSuccess = .f.
	endtry

	if !m.llSuccess then
		lcErrorMsg = 'Error in Version file:' 		+ CRLF + 			;
			'Msg:   ' + m.loException.message 		+ CRLF +			;
			'Code:  ' + m.loException.linecontents
		messagebox(m.lcErrorMsg + CRLF +  CRLF + 'ABORTING', 16, 'VFPX Project Deployment')
	endif &&!m.llSuccess

	return m.llSuccess

endproc &&CheckVersionFile

procedure ScanDir_Templates
	lparameters;
		tcSource
	local;
		lcOldDir,;
		lcText,;
		lnLoop1

	local array;
		laDir(1)

	lcOldDir = fullpath("", "")
	cd (m.tcSource)
	for lnLoop1 = 1 to adir(m.laDir, '', 'D')
		if inlist(laDir(m.lnLoop1, 1), '.', '..') then
			loop
		endif &&INLIST(laDir(m.lnLoop1,1), '.', '..')

		ScanDir_ScanDir_Templates(addbs(m.tcSource + laDir(m.lnLoop1, 1)))
	endfor &&lnLoop1

	for lnLoop1  = 1 to adir(laFiles, m.tcSource + '*.*', '', 1)
		lcText = filetostr(m.tcSource + laFiles[m.lnI])
		lcText = ReplacePlaceholders_Run (m.lcText)
		strtofile(m.lcText,m.tcSource + laFiles[m.lnI])
	endfor &&lnLoop1

	cd (m.lcOldDir)

endproc &&ScanDir_Templates

procedure ScanDir_InstFiles
	lparameters;
		tcSourceDir,;
		tcTargetDir,;
		tlExclude


	local;
		lcOldDir,;
		lnLoop1

	local array;
		laDir(1)

	lcOldDir = fullpath("", "")
	cd (m.tcSourceDir)
	for lnLoop1 = 1 to adir(m.laDir, '', 'D')
		if inlist(laDir(m.lnLoop1, 1), '.', '..') then
			loop
		endif &&INLIST(laDir(m.lnLoop1,1), '.', '..')
	IF m.tlExclude THEN
*tcTargetDir is the pattern, just keep it
		ScanDir_InstFiles(addbs(m.tcSourceDir + laDir(m.lnLoop1, 1)), m.tcTargetDir, m.tlExclude)
	ELSE  &&m.tlExclude
		ScanDir_InstFiles(addbs(m.tcSourceDir + laDir(m.lnLoop1, 1)), addbs(m.tcTargetDir + laDir(m.lnLoop1, 1)), m.tlExclude)
	ENDIF &&m.tlExclude 

	endfor &&lnLoop1
	IF m.tlExclude THEN
*just delete pattern
		DELETE FILE (m.tcTargetDir)
	ELSE  &&m.tlExclude
		Copy_InstallFile(addbs(m.tcSourceDir) + '*.*', addbs(m.tcTargetDir) + '*.*')
	ENDIF &&m.tlExclude 
	cd (m.lcOldDir)

endproc &&ScanDir_InstFiles

procedure Copy_InstallFile
	lparameters;
		tcSource,;
		tcTarget

	local;
		lcFolder

	local array;
		laDir(1)

	lcFolder = justpath(m.tcTarget)
	if not directory(m.lcFolder) then
		md (m.lcFolder)
	endif &&not directory(m.tcFolder)

	if !empty(adir(m.laDir, m.tcSource)) then
		copy file (m.tcSource) to (m.tcTarget)
	endif &&!empty(ADIR(m.laDir, m.tcSource))

endproc &&Copy_InstallFile

procedure ReleaseThis
	release;
		pcAppName,;
		pcAppID,;
		pcVersion,;
		pdVersionDate,;
		pcVersionDate,;
		pcChangeLog,;
		plContinue,;
		pcFullVersion,;
		plRun_Bin2Prg,;
		plRun_git,;
		pcDate,;
		pcJulian,;
		pcThisDate,;
		pcRepository

endproc &&ReleaseThis

procedure GetProject_Folder
	lparameters;
		tcPreviousFolder

	local;
		lcFolder   as string,;
		lcValidFolder as string

* try if active folder is in a git repository
	lcValidFolder = Validate_TopLevel(fullpath('',''))
	if not empty(m.lcValidFolder) then
		return m.lcValidFolder
	endif &&not empty(m.lcValidFolder)

* SF 20230512, try active project next
*in case we have a structure where we sit in a base with many scatterd projects
*we try if the Active Project is the one
	if type("_VFP.ActiveProject")='O' then
		lcValidFolder = justpath(_vfp.activeproject.name)
		if not empty(m.lcValidFolder) and  messagebox('Run for active project' + chr(13) + chr(10) + chr(13) + chr(10) + '"' + ;
				_vfp.activeproject.name + '" ?', 36, 'VFPX Project Deployment') = 6 then
			return m.lcValidFolder

		endif &&Not Empty(m.lcValidFolder) AND Messagebox('Run for active project' + Chr(13) + Chr(10) + Chr(13) + Chr(10) ...
	endif &&type("_VFP.ActiveProject")='O'

*try to get a folder
	do while .t.
		lcFolder = getdir(m.tcPreviousFolder, 'Project Home Folder', 'Home Path')
		if empty(m.lcFolder) then
			return ''
		endif &&empty(m.lcFolder)

		lcValidFolder = Validate_TopLevel(m.lcFolder)
		if empty(m.lcValidFolder) then
			messagebox('Top level folder not found, not a git repository.', 16, 'VFPX Project Deployment')
		else &&empty(m.lcValidFolder)
			return m.lcValidFolder
		endif &&empty(m.lcValidFolder)

	enddo &&.t.

endproc &&GetProject_Folder

procedure Validate_TopLevel
	lparameters;
		tcFolder

* SF 20230512
*we test if this folder is a git folder and return the git base folder
*no need to search the base folder, git will tell this
* (and not embarrassingly testing for ".git" folder)
	local;
		lcCommand as string,;
		lcOldFolder as string

	lcOldFolder = fullpath('','')
	cd (m.tcFolder)
	delete file git_x.tmp    && in case

*if git is not installed, we get an empty or no file
	lcCommand = 'git rev-parse --show-toplevel>git_x.tmp'
	run &lcCommand

	if file('git_x.tmp') then
*the result is either the git base folder or empty for no git repo
		tcFolder = chrtran(filetostr('git_x.tmp'), '/' + chr(13) + chr(10), '\')
		delete file git_x.tmp
	else &&file('git_x.tmp')
* no file, no git
		tcFolder = ''
	endif &&file('git_x.tmp')

	cd (m.lcOldFolder)
	return m.tcFolder

endproc &&Validate_TopLevel
