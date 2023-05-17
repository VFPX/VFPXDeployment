#define CRLF chr(13) + chr(10)

* Parameter lcFolder is the home folder for the project
*   and defaults to the current folder if not supplied
lparameters;
	tcFolder

local;
	lcCurrFolder        as string,;
	lcProjectName       as string,;
	lcStartFolder       as string,;
	lcVFPXDeploymentFolder as string

* Get the project folder.
lcStartFolder = curdir()
tcFolder      = evl(m.tcFolder, m.lcStartFolder)
cd (m.tcFolder) && Project Home

* Bug out if NoVFPXDeployment.txt exists.

if file('NoVFPXDeployment.txt') then
	messagebox('VFPX Project Deployment will not run because NoVFPXDeployment.txt exists.', ;
		 16, 'VFPX Project Deployment')
	return
endif &&file('NoVFPXDeployment.txt')

* Create the BuildProcess subdirectory of the project folder if necessary.

lcCurrFolder = addbs(addbs(m.tcFolder) + 'BuildProcess') && BuildProcess
if not directory(m.lcCurrFolder) then
*SF 20230512 we better check if this exists a different Thor
*this is not fool-proof, since there are many ways to do Thor
*but a very common one
	if directory(addbs(m.tcFolder) + 'ThorUpdater') then
		messagebox('There is allready a Thor folder.' + CRLF + CRLF + 'Stoped.', ;
			 16, 'VFPX Project Deployment')
		return
	endif &&directory(addbs(m.tcFolder) + 'ThorUpdater')
	md (m.lcCurrFolder)
endif &&not directory(m.lcCurrFolder)

* If we don't have ProjectSettings.txt, copy it, VersionTemplate.txt, and
* BuildMe.prg, AfterBuild.prg from the VFPXDeployment folder.

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
Deploy(m.lcVFPXDeploymentFolder, m.lcProjectName, m.lcCurrFolder)

* Restore the former current directory.

cd (m.lcStartFolder)

return


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
		lcVersionTemplateFile as string,;
		lcZipFile            as string,;
		llInculde_VFPX       as boolean,;
		llPrompt             as boolean,;
		llRecompile          as boolean,;
		lnBin2PRGFolders     as number,;
		lnFiles              as number,;
		lnI                  as number,;
		lnJulian             as number,;
		lnPos                as number,;
		lnProject            as number,;
		lnSettings           as number

	local array;
		laBin2PRGFolders(1),;
		laFiles(1,1),;
		laSettings(1)

	lcProjectFile           = m.tcCurrFolder + 'ProjectSettings.txt'
	lcInstalledFilesListing = m.tcCurrFolder + 'InstalledFiles.txt'
	lcInstalledFilesFolder  = 'InstalledFiles'
	lcBuildProgram          = m.tcCurrFolder + 'BuildMe.prg'
	lcAfterBuildProgram     = m.tcCurrFolder + 'AfterBuild.prg'
	lcVersionTemplateFile   = m.tcCurrFolder + 'VersionTemplate.txt'
	lcUpdateTemplateFile    = _screen.cThorFolder + ;
		'Tools\Apps\VFPXDeployment\Thor_Update_Template.txt'

* Get the current project settings into public variables.

	lcProjectSettings = filetostr(m.lcProjectFile)
	public;
		pcAppName     as string,;
		pcAppID       as string,;
		pcVersion     as string,;
		pdVersionDate as date,;
		pcVersionDate as string,;
		pcChangeLog   as string,;
		plContinue    as boolean
*SF 20230512: add new flags
	public;
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
	llInculde_VFPX        = .f.
	lnSettings            = alines(laSettings, m.lcProjectSettings)
	for lnI = 1 to m.lnSettings
		lcLine  = laSettings[m.lnI]
		lnPos   = at('=', m.lcLine)
		lcName  = alltrim(left(m.lcLine, m.lnPos - 1))
		lcValue = alltrim(substr(m.lcLine, m.lnPos + 1))
		lcUName = upper(m.lcName)
		do case
			case m.lcUName = 'APPNAME'
				pcAppName = m.lcValue
			case m.lcUName = 'APPID'
				pcAppID = m.lcValue
			case m.lcUName = 'VERSION'
				pcVersion = m.lcValue
			case m.lcUName = 'VERSIONDATE'
				pdVersionDate = evaluate('{^' + m.lcValue + '}')
			case m.lcUName = 'PROMPT'
				llPrompt = upper(m.lcValue) = 'Y'
			case m.lcUName = 'CHANGELOG'
				pcChangeLog = m.lcValue
			case m.lcUName = 'BIN2PRGFOLDER'
				lcBin2PRGFolderSource = m.lcValue
			case m.lcUName = 'COMPONENT'
				lcComponent = m.lcValue
			case m.lcUName = 'CATEGORY'
				lcCategory = m.lcValue
			case m.lcUName = 'PJXFILE'
				lcPJXFile = m.lcValue
			case m.lcUName = 'RECOMPILE'
				llRecompile = upper(m.lcValue) = 'Y'
			case m.lcUName = 'APPFILE'
				lcAppFile = m.lcValue
			case m.lcUName = 'REPOSITORY'
				pcRepository = m.lcValue
			case m.lcUName = 'INSTALLEDFILESFOLDER'
				lcInstalledFilesFolder = m.lcValue
*SF 20230512: new flags
			case m.lcUName = 'RUNBIN2PRG'
				plRun_Bin2Prg = upper(m.lcValue) = 'Y'
			case m.lcUName = 'RUNGIT'
				plRun_git = upper(m.lcValue) = 'Y'
			case m.lcUName = 'INCULDE_VFPX'
				llInculde_VFPX = upper(m.lcValue) = 'Y'
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
			messagebox('No project to get version number from found.', 16, ;
				 'VFPX Project Deployment')
			ReleaseThis()
			return

		endif &&empty(m.pcVersion)
	endif &&upper(m.pcVersion)=='PJX'
* Ensure we have valid pcAppName and pcAppID values.

	if empty(m.pcAppName) then
		messagebox('The appName setting was not specified.', 16, ;
			 'VFPX Project Deployment')
		ReleaseThis()
		return
	endif &&empty(m.pcAppName)

	if empty(m.pcAppID) then
		messagebox('The appID setting was not specified.', 16, ;
			 'VFPX Project Deployment')
		ReleaseThis()
		return
	endif &&empty(m.pcAppID)

	if ' ' $ m.pcAppID or '	' $ m.pcAppID then
		messagebox('The appID setting cannot have spaces or tabs.', 16, ;
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
					laBin2PRGFolders[m.lnI] = fullpath(m.tcCurrFolder + '..\' + m.lcFolder)
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
	lcVersionFile = 'ThorUpdater\' + m.pcAppID + 'Version.txt'
	lcUpdateFile  = m.tcCurrFolder + 'Thor_Update_' + m.pcAppID + '.prg'
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
	if !file(m.lcInstalledFilesListing) and !directory(m.lcInstalledFilesFolder) then
* If no InstalledFiles.txt exists, and no InstalledFiles folder, break
		messagebox('Please either create InstalledFiles.txt in the ' + ;
			 'BuildProcess folder with each file to be installed by Thor ' + ;
			 'listed on a separate line, or create a subdirectory of ' + ;
			 'the project folder named InstalledFiles and copy the ' + ;
			 'files Thor should install to it.', ;
			 16, 'VFPX Project Deployment')
		ReleaseThis()
		return

	endif &&!file(m.lcInstalledFilesListing) and !directory(m.lcInstalledFilesFolder)

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

	SetDocumentation (addbs(justpath(justpath(m.tcCurrFolder))), m.tcVFPXDeploymentFolder, m.llInculde_VFPX)

*SF 20230514 the test is moved to a place above, so no processing is done

	if file(m.lcInstalledFilesListing) then
* If InstalledFiles.txt exists, copy the files listed in it to the
* InstalledFiles folder (folders are created as necessary).
		lcFiles = filetostr(m.lcInstalledFilesListing)
		lnFiles = alines(laFiles, m.lcFiles, 1 + 4)
		for lnI = 1 to m.lnFiles
			lcSource = laFiles[m.lnI]
			lcTarget = addbs(m.lcInstalledFilesFolder) + m.lcSource
			lcFolder = justpath(m.lcTarget)
			if not directory(m.lcFolder) then
				md (m.lcFolder)

			endif &&not directory(m.lcFolder)
			copy file (m.lcSource) to (m.lcTarget)

		next &&lnI
	endif &&file(m.lcInstalledFilesListing)

* Create the ThorUpdater folder if necessary.

	if not directory('ThorUpdater') then
		md ThorUpdater
	endif &&not directory('ThorUpdater')

* Update Version.txt.
	lcVersion = filetostr(m.lcVersionTemplateFile)
	lcVersion = ReplacePlaceholders_Once(m.lcVersion)

	lcChange  = iif(file(m.pcChangeLog), filetostr(m.pcChangeLog), '')
	lcVersion = strtran(m.lcVersion, '{CHANGELOG}', m.lcChange,     -1, -1, 1)
	lcVersion = strtran(m.lcVersion, '{COMPONENT}', m.lcComponent,  -1, -1, 1)
	lcVersion = strtran(m.lcVersion, '{CATEGORY}',  m.lcCategory,   -1, -1, 1)

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

		lcContent = ReplacePlaceholders_Once(m.lcVersion)

		lcContent = strtran(m.lcContent, '{COMPONENT}', m.lcComponent, ;
			 -1, -1, 1)
		strtofile(m.lcContent, m.lcUpdateFile)

	endif &&file(m.lcUpdateTemplateFile) and not file(m.lcUpdateFile)

* Zip the source files.

	execscript(_screen.cThorDispatcher, 'Thor_Proc_ZipFolder', m.lcInstalledFilesFolder, m.lcZipFile)

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

* Execute AfterBuild.prg if it exists.

	if file(m.lcAfterBuildProgram) then
		do (m.lcAfterBuildProgram)
	endif &&file(m.lcAfterBuildProgram)

	ReleaseThis()

	messagebox('Deployment for ' + m.tcProjectName + ' complete.' +  CRLF +  CRLF + 'All done', 64, 'VFPX Project Deployment', 5000)

endproc &&Deploy

procedure SetDocumentation
	lparameters;
		tcCurrFolder,;
		tcVFPXDeploymentFolder,;
		tlInculde_VFPX

*check for several VFPX defaults:
	local;
		lcText as string,;
		lnFile as number

	local array;
		laFiles(1, 1)

	if not file(m.tcCurrFolder + 'README.md') then
		if m.tlInculde_VFPX then
			lcText = filetostr(m.tcVFPXDeploymentFolder + 'VFPXTemplate\R_README.md')
			lcText = ReplacePlaceholders_Once(m.lcText)
			lcText = ReplacePlaceholders_Run (m.lcText)
			strtofile(m.lcText, 'README.md')

		endif &&m.tlInculde_VFPX
	else  &&not file(m.tcCurrFolder + 'README.md')
		if file(m.tcCurrFolder + 'README.md') then
			lcText = filetostr('README.md')
			lcText = ReplacePlaceholders_Run (m.lcText)
			strtofile(m.lcText, 'README.md')

		endif &&file(m.tcCurrFolder + 'README.md')
	endif &&not file(m.tcCurrFolder + 'README.md')

	if m.tlInculde_VFPX then
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
				lcText = FILETOSTR('.github\ISSUE_TEMPLATE\' + laFiles(m.lnFile, 1))
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

endproc &&SetDocumentation

procedure ReplacePlaceholders_Once
	lparameters;
		tcText

	local;
		lcRemove as string,;
		lcText as string,;
		lnI   as number

	tcText = strtran(m.tcText, '{APPNAME}',     m.pcAppName,    -1, -1, 1)
	tcText = strtran(m.tcText, '{APPID}',       m.pcAppID,      -1, -1, 1)
	lcText = strtran(m.tcText, '{CURRDATE}',    m.pcThisDate,   -1, -1, 1)
	tcText = strtran(m.tcText, '{VERSIONDATE}', m.pcDate,       -1, -1, 1)
	tcText = strtran(m.tcText, '{CVERSIONDATE}',m.pcVersionDate,-1, -1, 1)
	tcText = strtran(m.tcText, '{VERSION}',     m.pcVersion,    -1, -1, 1)
	tcText = strtran(m.tcText, '{JULIAN}',      m.pcJulian,     -1, -1, 1)
	tcText = strtran(m.tcText, '{REPOSITORY}',  m.pcRepository, -1, -1, 1)
	tcText = strtran(m.tcText, '{CHANGELOG_F}', m.pcChangeLog, -1, -1, 1)
	tcText = textmerge(m.tcText)

	for lnI = occurs('@@@', m.tcText) to 1 step -1
		lcRemove = strextract(m.tcText, '@@@', '\\\', m.lnI, 4)
		tcText   = strtran(m.tcText, m.lcRemove)

	next &&lnI

	return m.tcText
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
