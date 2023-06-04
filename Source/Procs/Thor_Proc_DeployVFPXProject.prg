#Define CRLF Chr(13) + Chr(10)

Lparameters;
	tcFolder

* Parameter tcFolder is the home folder for the project
* If no folder is given, this program assumes to run stand-alone

Local;
	lcProjectFolder As String

If !Empty(m.tcFolder) And Directory(m.tcFolder) Then
	Do Main With m.tcFolder
Else  &&!Empty(m.tcFolder) And Directory(m.tcFolder)
*Try .. EndTry bei IntelliScript
*!*	LOCAL;
*!*	 llError     AS BOOLEAN,;
*!*	 loException AS EXCEPTION

	If !Pemstatus(_Screen,'cThorDispatcher',5) Then
		Messagebox('Thor must running to run VFPX Deployment.' , ;
			16, 'VFPX Project Deployment')
		Return .F.
	Endif &&!PEMSTATUS(_Screen,'cThorDispatcher',5)

	AddProperty(_Screen, 'VFPX_DeployStartFolder', Fullpath("", ""))

* ================================================================================

	lcProjectFolder	 = GetProject_Folder(_Screen.VFPX_DeployStartFolder)

	If Directory(m.lcProjectFolder) Then

		Do Main With m.lcProjectFolder
	Endif &&Directory(m.lcProjectFolder)
* ================================================================================

	Cd (_Screen.VFPX_DeployStartFolder)
	Removeproperty(_Screen, 'VFPX_DeployStartFolder')
Endif &&!Empty(m.tcFolder) And Directory(m.tcFolder)

* ================================================================================
* ================================================================================
* Wrapping, just to allow stand alone work with a quick'n'dirty call
Procedure Main
	Lparameters;
		tcFolder

	Local;
		lcCurrFolder        As String,;
		lcProjectName       As String,;
		lcVFPXDeploymentFolder As String

* Get the project folder.
	If Empty(m.tcFolder) Then
		Messagebox('Parameter tcFolder could not be empty in Main.', ;
			16, 'VFPX Project Deployment')
		Return
	Endif &&Empty(m.tcFolder)

	Cd (m.tcFolder) && Project Home

* Bug out if NoVFPXDeployment.txt exists.

	If File(Addbs(m.tcFolder) + 'NoVFPXDeployment.txt') Then
		Messagebox('VFPX Project Deployment will not run because NoVFPXDeployment.txt exists.', ;
			16, 'VFPX Project Deployment')
		Return
	Endif &&File(Addbs(m.tcFolder) + 'NoVFPXDeployment.txt')

* Create the BuildProcess subdirectory of the project folder if necessary.

	lcCurrFolder = Addbs(Addbs(m.tcFolder) + 'BuildProcess') && BuildProcess
	If Not Directory(m.lcCurrFolder) Then
*SF 20230512 we better check if a different Thor exists
* this is not fool-proof, since there are many ways to do Thor
* but a very common one
		If Directory(Addbs(m.tcFolder) + 'ThorUpdater') Then
			Messagebox('There is already a Thor folder.' + CRLF + CRLF + 'Stoped.' + CRLF + CRLF + 'You need to carefully create the setup manually.', ;
				16, 'VFPX Project Deployment')
			Return
		Endif &&Directory(Addbs(m.tcFolder) + 'ThorUpdater')
		Md (m.lcCurrFolder)
	Endif &&Not Directory(m.lcCurrFolder)

* If we don't have ProjectSettings.txt, copy it, VersionTemplate.txt, and
* BuildMe.prg, AfterBuild.prg from the VFPXDeployment folder.
* Stop process to let the user set up the tool

	lcVFPXDeploymentFolder = _Screen.cThorFolder + 'Tools\Apps\VFPXDeployment\'

	If Not File(m.lcCurrFolder + 'ProjectSettings.txt') Then
		Copy File (m.lcVFPXDeploymentFolder + 'ProjectSettings.txt') To ;
			(m.lcCurrFolder + 'ProjectSettings.txt')
		Copy File (m.lcVFPXDeploymentFolder + 'VersionTemplate.txt') To ;
			(m.lcCurrFolder + 'VersionTemplate.txt')
		Copy File (m.lcVFPXDeploymentFolder + 'BuildMe.prg') To ;
			(m.lcCurrFolder + 'BuildMe.prg')
		Copy File (m.lcVFPXDeploymentFolder + 'AfterBuild.prg') To ;
			(m.lcCurrFolder + 'AfterBuild.prg')
		Messagebox('Please edit ProjectSettings.txt and fill in the settings ' + ;
			'for this project.' + CRLF + ;
			'Also, edit InstalledFiles.txt and specify ' + ;
			'which files should be installed.' + CRLF +  CRLF +;
			'Then run VFPX Project Deployment again.', ;
			16, 'VFPX Project Deployment')
		Modify File (m.lcCurrFolder + 'ProjectSettings.txt') Nowait
		Modify File (m.lcCurrFolder + 'InstalledFiles.txt') Nowait
		Return
	Endif &&Not File(m.lcCurrFolder + 'ProjectSettings.txt')

	lcProjectName = Getwordnum(m.lcCurrFolder, Getwordcount(m.lcCurrFolder, '\') - 1, '\')

	Deploy(m.lcVFPXDeploymentFolder, m.lcProjectName, Addbs(m.tcFolder))

* Restore the former current directory.

	Removeproperty(_Screen, 'VFPX_Deploy_StartFolder')

	Return

Endproc &&Main

* ================================================================================
* ================================================================================
* The work horse - put in separate Proc so that any the CD (lcStartFolder) is always run

Procedure Deploy
	Lparameters;
		tcVFPXDeploymentFolder,;
		tcProjectName,;
		tcCurrFolder


* Put the paths for files we may use into variables.

	Local;
		lcAfterBuildProgram  As String,;
		lcAppFile            As String,;
		lcBin2PRGFolder      As String,;
		lcBin2PRGFolderSource As String,;
		lcBuildProgram       As String,;
		lcCategory           As String,;
		lcChange             As String,;
		lcCommand            As String,;
		lcComponent          As String,;
		lcContent            As String,;
		lcErrFile            As String,;
		lcFile               As String,;
		lcFiles              As String,;
		lcFolder             As String,;
		lcFoxBin2PRG         As String,;
		lcInstalledFilesFolder As String,;
		lcInstalledFilesListing As String,;
		lcLine               As String,;
		lcName               As String,;
		lcPJXFile            As String,;
		lcProjectFile        As String,;
		lcProjectSettings    As String,;
		lcRecompile          As String,;
		lcRepositoryRoot     As String,;
		lcSource             As String,;
		lcSubstituteListing  As String,;
		lcTarget             As String,;
		lcUName              As String,;
		lcUpdateFile         As String,;
		lcUpdateTemplateFile As String,;
		lcValue              As String,;
		lcVersion            As String,;
		lcVersionFile        As String,;
		lcVersionFileR       As String,;
		lcVersionTemplateFile As String,;
		lcZipFile            As String,;
		llClear_InstalledFiles As Boolean,;
		llInclude_Thor       As Boolean,;
		llInclude_VFPX       As Boolean,;
		llPrompt             As Boolean,;
		llRecompile          As Boolean,;
		lnBin2PRGFolders     As Number,;
		lnFiles              As Number,;
		lnI                  As Number,;
		lnJulian             As Number,;
		lnPos                As Number,;
		lnProject            As Number,;
		lnSettings           As Number,;
		lnWords              As Number,;
		loFSO                As "Scripting.FileSystemObject"

	Local Array;
		laBin2PRGFolders(1),;
		laFiles(1,1),;
		laSettings(1),;
		laWords(1,1),;
		laPlaceholders(1,1)

	lcProjectFile           = m.tcCurrFolder + 'BuildProcess\ProjectSettings.txt'
	lcInstalledFilesListing = m.tcCurrFolder + 'BuildProcess\InstalledFiles.txt'
	lcSubstituteListing     = m.tcCurrFolder + 'BuildProcess\Substitute.txt'
	lcInstalledFilesFolder  = 'InstalledFiles'
	lcBuildProgram          = m.tcCurrFolder + 'BuildProcess\BuildMe.prg'
	lcAfterBuildProgram     = m.tcCurrFolder + 'BuildProcess\AfterBuild.prg'
	lcVersionTemplateFile   = m.tcCurrFolder + 'BuildProcess\VersionTemplate.txt'
	lcUpdateTemplateFile    = _Screen.cThorFolder + ;
		'Tools\Apps\VFPXDeployment\Thor_Update_Template.txt'

* Get the current project settings into public variables.

	lcProjectSettings = Filetostr(m.lcProjectFile)

* Release the PUBLICS in ReleaseThis procedure
	Public;
		pcAppName     As String,;
		pcAppID       As String,;
		pcVersion     As String,;
		pdVersionDate As Date,;
		pcVersionDate As String,;
		pcChangeLog   As String,;
		plContinue    As Boolean,;
		pcFullVersion As String,;
		pcDate        As String,;
		pcJulian      As String,;
		pcThisDate    As String,;
		pcRepository  As String,;
		plRun_Bin2Prg As Boolean,;
		plRun_git     As Boolean

	pdVersionDate = Date()
	pcVersion     = ''
	pcChangeLog   = ''
	plContinue    = .T.
*SF 20230512: add new flags
	pcFullVersion = ''		&& For autoset README.MD. Full version info. Either pcVersion or returned from BuilMe.prg
	plRun_Bin2Prg = .T.		&& Run FoxBin2Prg; from ProjectSettings.txt
	plRun_git     = .T.		&& Run git; from ProjectSettings.txt
*/SF 20230512
	llPrompt              = .T.
	lcBin2PRGFolderSource = ''
	lcComponent           = 'Yes'
	lcCategory            = 'Applications'
	lcPJXFile             = ''
	llRecompile           = .F.
	lcAppFile             = ''
	lcRepositoryRoot      = 'https://github.com/VFPX/'
	pcRepository          = ''
	llInclude_VFPX        = .F.
	llInclude_Thor        = .T.
	lnSettings            = Alines(laSettings, m.lcProjectSettings)

	For lnI = 1 To m.lnSettings
		lcLine  = laSettings[m.lnI]
		lnPos   = At('=', m.lcLine)
		lcName  = Alltrim(Left(m.lcLine, m.lnPos - 1))
		lcValue = Alltrim(Substr(m.lcLine, m.lnPos + 1))
		lcUName = Upper(m.lcName)
		Do Case
			Case m.lcUName == 'APPNAME'
				pcAppName = m.lcValue
			Case m.lcUName == 'APPID'
				pcAppID = m.lcValue
			Case m.lcUName == 'VERSION'
				pcVersion = m.lcValue
			Case m.lcUName == 'VERSIONDATE'
				pdVersionDate = Evaluate('{^' + m.lcValue + '}')
			Case m.lcUName == 'PROMPT'
				llPrompt = Upper(m.lcValue) = 'Y'
			Case m.lcUName == 'CHANGELOG'
				pcChangeLog = m.lcValue
			Case m.lcUName == 'BIN2PRGFOLDER'
				lcBin2PRGFolderSource = m.lcValue
			Case m.lcUName == 'COMPONENT'
				lcComponent = m.lcValue
			Case m.lcUName == 'CATEGORY'
				lcCategory = m.lcValue
			Case m.lcUName == 'PJXFILE'
				lcPJXFile = m.lcValue
			Case m.lcUName == 'RECOMPILE'
				llRecompile = Upper(m.lcValue) = 'Y'
			Case m.lcUName == 'APPFILE'
				lcAppFile = m.lcValue
			Case m.lcUName == 'REPOSITORY'
				pcRepository = m.lcValue
			Case m.lcUName == 'INSTALLEDFILESFOLDER'
				lcInstalledFilesFolder = m.lcValue
*SF 20230512: new flags
			Case m.lcUName == 'CLEAR_INSTALLEDFILES'
				llClear_InstalledFiles = Upper(m.lcValue) = 'Y'
			Case m.lcUName == 'RUNBIN2PRG'
				plRun_Bin2Prg = Upper(m.lcValue) = 'Y'
			Case m.lcUName == 'RUNGIT'
				plRun_git = Upper(m.lcValue) = 'Y'
			Case m.lcUName == 'INCLUDE_VFPX'
				llInclude_VFPX = Upper(m.lcValue) = 'Y'
			Case m.lcUName == 'INCLUDE_THOR'
				llInclude_Thor = Upper(m.lcValue) = 'Y'
			Case m.lcUName == 'VERSIONFILE_REMOTE'
				lcVersionFileR = m.lcValue
*/SF 20230512
		Endcase
	Next &&lnI

*SF 20230512, get pjx version
	If Upper(m.pcVersion)=='PJX' Then
		pcVersion = ''
		If Empty(m.lcPJXFile) Then
*use the active pjx, since no pjx is defined
			If Type("_VFP.ActiveProject")='O' Then
				pcVersion = _vfp.ActiveProject.VersionNumber

			Endif &&Type("_VFP.ActiveProject")='O'
		Else  &&Empty(m.lcPJXFile)
*use pjx defined
*bit more work
*see if the project is open
			For lnProject = 1 To _vfp.Projects.Count
				If Upper(Fullpath(m.lcPJXFile))==Upper(_vfp.Projects(m.lnProject).Name) Then
					pcVersion = _vfp.Projects(m.lnProject).VersionNumber
					Exit

				Endif &&Upper(Fullpath(m.lcPJXFile))==Upper(_vfp.Projects(m.lnProject).Name)
			Endfor &&lnProject

			If Empty(m.pcVersion);
					And File(Fullpath(m.lcPJXFile)) Then
				Modify Project (Fullpath(m.lcPJXFile)) Nowait Noshow Noprojecthook
				pcVersion = _vfp.Projects(m.lnProject).VersionNumber
				_vfp.ActiveProject.Close

			Endif &&Empty(m.pcVersion) And File(Fullpath(m.lcPJXFile))
		Endif &&Empty(m.lcPJXFile)

		If Empty(m.pcVersion) Then
			Messagebox('No project found to read version number.', 16, ;
				'VFPX Project Deployment')
			ReleaseThis()
			Return

		Endif &&Empty(m.pcVersion)
	Endif &&Upper(m.pcVersion)=='PJX'
* Ensure we have valid pcAppName and pcAppID values.

	If Empty(m.pcAppName) Then
		Messagebox('The AppName setting was not specified.', 16, ;
			'VFPX Project Deployment')
		ReleaseThis()
		Return
	Endif &&Empty(m.pcAppName)

	If Empty(m.pcAppID) Then
		Messagebox('The AppID setting was not specified.', 16, ;
			'VFPX Project Deployment')
		ReleaseThis()
		Return
	Endif &&Empty(m.pcAppID)

	If ' ' $ m.pcAppID Or '	' $ m.pcAppID Then
		Messagebox('The AppID setting cannot have spaces or tabs.', 16, ;
			'VFPX Project Deployment')
		ReleaseThis()
		Return
	Endif &&' ' $ m.pcAppID Or '	' $ m.pcAppID

* If we're supposed to build an APP or EXE, ensure we have both settings
* and we're running VFP 9 and not VFP Advanced since the APP/EXE structure
* is different. If AppFile is omitted, use the same folder and name as the
* PJX file.

	If Not Empty(m.lcPJXFile) And Empty(m.lcAppFile) Then
		lcAppFile = Forceext(m.lcPJXFile, 'app')
	Endif &&Not Empty(m.lcPJXFile) And Empty(m.lcAppFile)

	If (Empty(m.lcPJXFile) And Not Empty(m.lcAppFile)) Or ;
			(Empty(m.lcAppFile) And Not Empty(m.lcPJXFile)) Then
		Messagebox('If you specify one of them, you have to specify both ' + ;
			'PJXFile and AppFile.', 16, 'VFPX Project Deployment')
		ReleaseThis()
		Return
	Endif &&(Empty(m.lcPJXFile) And Not Empty(m.lcAppFile)) Or (Empty(m.lcAppFile) And Not Empty(m.lcPJXFile))

	If Not Empty(m.lcPJXFile) And Val(Version(4)) > 9 Then
		Messagebox('You must run VFPX Project Deployment using VFP 9 not VFP Advanced.', ;
			16, 'VFPX Project Deployment')
		ReleaseThis()
		Return
	Endif &&Not Empty(m.lcPJXFile) And Val(Version(4)) > 9

	If Empty(m.lcVersionFileR) Then
		lcVersionFileR = m.pcAppID + 'Version.txt'
	Endif &&Empty(m.lcVersionFileR)

* If Bin2PRGFolderSource or PJXFile was supplied, find FoxBin2PRG.EXE.

	lcBin2PRGFolder = ''
	lcFoxBin2PRG    = ''
	If m.plRun_Bin2Prg And (Not Empty(m.lcBin2PRGFolderSource) Or Not Empty(m.lcPJXFile)) Then
		lcFoxBin2PRG = Execscript(_Screen.cThorDispatcher, 'Thor_Proc_GetFoxBin2PrgFolder') + ;
			'FoxBin2Prg.exe'

		Do Case
			Case Not File(m.lcFoxBin2PRG)
				Messagebox('FoxBin2PRG.EXE not found.', 16, ;
					'VFPX Project Deployment')
				ReleaseThis()
				Return
* &&not file(m.lcFoxBin2PRG)

			Case Not Empty(m.lcBin2PRGFolderSource)
				lnBin2PRGFolders = Alines(laBin2PRGFolders, m.lcBin2PRGFolderSource, 4, ',')
				For lnI = 1 To m.lnBin2PRGFolders
					lcFolder                = laBin2PRGFolders[m.lnI]
					laBin2PRGFolders[m.lnI] = Fullpath(m.tcCurrFolder + m.lcFolder)
					If Not Directory(laBin2PRGFolders[m.lnI]) Then
						Messagebox('Folder "' + m.lcFolder + '" not found.', 16,	;
							'VFPX Project Deployment')
						ReleaseThis()
						Return

					Endif &&Not Directory(laBin2PRGFolders[m.lnI])
				Next &&lnI
* &&not empty(m.lcBin2PRGFolderSource)

		Endcase
	Endif &&m.plRun_Bin2Prg And (Not Empty(m.lcBin2PRGFolderSource) Or Not Empty(m.lcPJXFile))

* Get the names of the zip, Thor CFU version, and Thor updaters files and set pcVersionDate to
* a string version of the release date.

	lcZipFile     = 'ThorUpdater\' + m.pcAppID + '.zip'
	lcVersionFile = 'ThorUpdater\' + m.lcVersionFileR
	lcUpdateFile  = m.tcCurrFolder + 'BuildProcess\Thor_Update_' + m.pcAppID + '.prg'
	pcDate        = Dtoc(m.pdVersionDate, 1)
	pcVersionDate = Stuff(Stuff(m.pcDate, 7, 0, '-'), 5, 0, '-')

	lnJulian = m.pdVersionDate - {^2000-01-01}
	pcJulian = Padl(m.lnJulian, 5, '0')

	pcThisDate = 'date(' + Transform(Year(Date())) + ', ' + ;
		Transform(Month(Date())) + ', ' + Transform(Day(Date())) + ')'

* Get the repository to use if it wasn't specified.

	If Empty(m.pcRepository) Then
		pcRepository = m.lcRepositoryRoot + m.pcAppID
	Endif &&Empty(m.pcRepository)

* Get the version number if it wasn't specified and we're supposed to.

	If Empty(m.pcVersion) And m.llPrompt Then
		lcValue = Inputbox('Version', 'VFPX Project Deployment', '')
		If Empty(m.lcValue) Then
			ReleaseThis()
			Return
		Endif &&Empty(m.lcValue)
		pcVersion = m.lcValue

	Endif &&Empty(m.pcVersion) And m.llPrompt

*SF 20230514 the test for the copy process here, we don't need to proceed if this is not here
	If (!File(m.lcInstalledFilesListing) And !Directory(m.lcInstalledFilesFolder));
			Or (File(m.lcInstalledFilesListing)) And Empty(Filetostr(m.lcInstalledFilesListing)) Then
* If no InstalledFiles.txt exists, and no InstalledFiles folder, break
		Messagebox('Please either create InstalledFiles.txt in the ' + ;
			'BuildProcess folder with each file to be installed by Thor ' + ;
			'listed on a separate line, or create a subdirectory of ' + ;
			'the project folder named InstalledFiles and copy the ' + ;
			'files Thor should install to it.', ;
			16, 'VFPX Project Deployment')
		ReleaseThis()
		Return

	Endif &&(!File(m.lcInstalledFilesListing) And !Directory(m.lcInstalledFilesFolder)) Or ...

	pcFullVersion = m.pcVersion

* Execute BuildMe.prg if it exists. If it sets plContinue to .F., exit.

	If File(m.lcBuildProgram) Then
		Do (m.lcBuildProgram)
		If Not m.plContinue
			ReleaseThis()
			Return

		Endif &&Not m.plContinue
	Endif &&File(m.lcBuildProgram)

	If Empty(m.pcVersion) Then
		Messagebox('The version setting was not specified.', 16, ;
			'VFPX Project Deployment')
		ReleaseThis()
		Return
	Endif &&Empty(m.pcVersion)

*** JRN 2023-01-10 : Call FoxBin2PRG, if applicable
*SF 20230512: flag to disable FoxBin2PRG
	If m.plRun_Bin2Prg And Not Empty(m.lcFoxBin2PRG) Then
		If Not Empty(m.lcPJXFile)
			Do (m.lcFoxBin2PRG) With Fullpath(m.lcPJXFile), '*'
		Endif &&Not Empty(m.lcPJXFile)

		If Not Empty(m.lcBin2PRGFolderSource) Then
*** JRN 2023-01-29 : BIN2PRG for folder and sub-folders
			For lnI = 1 To m.lnBin2PRGFolders
				lcFolder = laBin2PRGFolders[m.lnI]
				Do (m.lcFoxBin2PRG) With 'BIN2PRG', m.lcFolder && + '\*.*'

			Next &&lnI
		Endif &&Not Empty(m.lcBin2PRGFolderSource)
	Endif &&m.plRun_Bin2Prg And Not Empty(m.lcFoxBin2PRG)

* Ensure we have a version number (Build.prg may have set it).

* Create an APP/EXE if we're supposed to.

	lcRecompile = Iif(m.llRecompile, 'recompile', '')
	Do Case
		Case Empty(m.lcPJXFile)
		Case Upper(Justext(m.lcAppFile)) = 'EXE'
			Build Exe (m.lcAppFile) From (m.lcPJXFile) &lcRecompile
		Otherwise
			Build App (m.lcAppFile) From (m.lcPJXFile) &lcRecompile
	Endcase

	lcErrFile = Forceext(m.lcAppFile, 'err')

	If Not Empty(m.lcPJXFile) And File(m.lcErrFile) Then
		Messagebox('An error occurred building the project.' + CRLF +;
			' Please see the ERR file for details.', 16, 'VFPX Project Deployment')
		Modify File (m.lcErrFile) Nowait
		ReleaseThis()
		Return

	Endif &&Not Empty(m.lcPJXFile) And File(m.lcErrFile)

*get Placeholders
	ACreate_Placeholders(@laPlaceholders)

	SetDocumentation (m.tcCurrFolder, m.tcVFPXDeploymentFolder, m.llInclude_VFPX, m.lcSubstituteListing, @laPlaceholders)

*SF 20230514 the test is moved to a place above, so no processing is done
	If m.llInclude_Thor Then
		If File(m.lcInstalledFilesListing) Then
			If m.llClear_InstalledFiles Then
				loFSO = Createobject("Scripting.FileSystemObject")
				loFSO.DeleteFolder(Fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder), .T.)
			Endif &&m.llClear_InstalledFiles
* If InstalledFiles.txt exists, copy the files listed in it to the
* InstalledFiles folder (folders are created as necessary).
			lcFiles = Filetostr(m.lcInstalledFilesListing)
			lnFiles = Alines(laFiles, m.lcFiles, 1 + 4)
*include
			For lnI = 1 To m.lnFiles
				lnWords  = Alines(laWords, Strtran(laFiles[m.lnI], '||', 0h00), 1 + 2, 0h00)
				lcSource = laWords[1]
				lcTarget = Iif(m.lnWords=1, laWords[1],  laWords[2])
				If Inlist(Left(Ltrim(m.lcSource), 1), '#', '!') Then
					Loop
				Endif &&Inlist(Left(Ltrim(m.lcSource), 1), '#', '!')
				If Empty(m.lcSource) Then
*not the toplevel folder (aka project root)
					Loop
				Endif &&Empty(m.lcSource)
				If m.lcTarget == '\' Then
*special: Folder .\InstalledFiles for substructure
					lcTarget = ''
				Endif &&m.lcTarget == '\' Then

				If Right(m.lcSource, 1) == '\' Then
* just with subfolders
					ScanDir_InstFiles(m.tcCurrFolder + m.lcSource, Addbs(Fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + m.lcTarget, .F.)
				Else
* just file / skeleton
					Copy_InstallFile(m.tcCurrFolder + m.lcSource, Addbs(Fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + m.lcTarget)
				Endif

			Next &&lnI
*exclude (iow remove after copy)
			For lnI = 1 To m.lnFiles
				If !Left(Ltrim(laFiles[m.lnI]), 1) == '!' Then
					Loop
				Endif &&!Left(Ltrim(laFiles[m.lnI]), 1) == '!'
				lcSource = Substr(laFiles[m.lnI], 2)
				If Empty(m.lcSource) Then
*not the toplevel folder (aka project root)
					Loop
				Endif &&Empty(m.lcSource)

* only pattern through all folders in lcInstalledFilesFolder
				ScanDir_InstFiles(Addbs(Fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)), m.lcSource, .T.)

			Next &&lnI
		Endif &&File(m.lcInstalledFilesListing)

		If Not File(Addbs(Fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + '.gitignore')
*ignore all in staging folder
			Strtofile('#.gitignore by VFPX Deployment' + CRLF + '*.*' , Addbs(Fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + '.gitignore')
		Endif &&Not File(Addbs(Fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + '.gitignore')

* Create the ThorUpdater folder if necessary.

		If Not Directory('ThorUpdater') Then
			Md ThorUpdater
		Endif &&Not Directory('ThorUpdater')

* Update Version.txt.
		lcVersion = Filetostr(m.lcVersionTemplateFile)

		lcChange  = Iif(File(m.pcChangeLog), Filetostr(m.pcChangeLog), '')
		lcVersion = Strtran(m.lcVersion, '{CHANGELOG}', m.lcChange,     -1, -1, 1)
		lcVersion = Strtran(m.lcVersion, '{COMPONENT}', m.lcComponent,  -1, -1, 1)
		lcVersion = Strtran(m.lcVersion, '{CATEGORY}',  m.lcCategory,   -1, -1, 1)

		lcVersion = ReplacePlaceholders_Once(@laPlaceholders,m.lcVersion)

		Strtofile(m.lcVersion, m.lcVersionFile)

* check proposed version file for errors
		If CheckVersionFile(m.lcVersionFile) = .F. Then
			ReleaseThis()
			Return

		Endif &&CheckVersionFile(m.lcVersionFile) = .F.
		Erase (Forceext(m.lcVersionFile, 'fxp'))

* Update Thor_Update program.

		If File(m.lcUpdateTemplateFile) And Not File(m.lcUpdateFile) Then

			lcContent = Filetostr(m.lcUpdateTemplateFile)

			lcContent = ReplacePlaceholders_Once(@laPlaceholders,m.lcContent)

			lcContent = Strtran(m.lcContent, '{COMPONENT}', m.lcComponent, ;
				-1, -1, 1)
			lcContent = Strtran(m.lcContent, '{VERSIONFILE}', m.lcVersionFileR, ;
				-1, -1, 1)
			Strtofile(m.lcContent, m.lcUpdateFile)

		Endif &&File(m.lcUpdateTemplateFile) And Not File(m.lcUpdateFile)

* Zip the source files.
		lcContent = ''
		If File(Addbs(Fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + '.gitignore')
*ignore all in staging folder
			lcContent = Filetostr(Addbs(Fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + '.gitignore')
			Delete File (Addbs(Fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + '.gitignore')
		Endif &&File(Addbs(Fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + '.gitignore')

		Execscript(_Screen.cThorDispatcher, 'Thor_Proc_ZipFolder', m.lcInstalledFilesFolder, m.lcZipFile)

		If Not Empty(m.lcContent)
*ignore all in staging folder
			Strtofile(m.lcContent, Addbs(Fullpath(m.lcInstalledFilesFolder, m.tcCurrFolder)) + '.gitignore')
		Endif &&Not Empty(m.lcContent)

* Add AppID.zip and AppIDVersion.txt to the repository.

*SF 20230512: flag to disable git
		If m.plRun_git Then
			lcCommand = 'git add ' + m.lcZipFile + ' -f'
			Run &lcCommand
			lcCommand = 'git add ' + m.lcVersionFile
			Run &lcCommand

* Add the BuildProcess files to the repository.

			For lnI = 1 To Adir(laFiles, 'BuildProcess\*.*', '', 1)
				lcFile = laFiles[m.lnI, 1]
				If Lower(Justext(m.lcFile)) <> 'fxp' Then
					lcCommand = 'git add BuildProcess\' + m.lcFile
					Run &lcCommand

				Endif &&Lower(Justext(m.lcFile)) <> 'fxp'
			Next &&lnI
		Endif &&m.plRun_git
	Endif &&m.llInclude_Thor

* Execute AfterBuild.prg if it exists.

*preserve tcProjectName
	AddProperty(_Screen, 'VFPX_Deploy_ProjectName', m.tcProjectName)

	If File(m.lcAfterBuildProgram) Then
		Do (m.lcAfterBuildProgram)
	Endif &&File(m.lcAfterBuildProgram)

	ReleaseThis()

	Messagebox('Deployment for ' + _Screen.VFPX_Deploy_ProjectName + ' complete.' +  CRLF +  CRLF + 'All done', 64, 'VFPX Project Deployment', 5000)

	Removeproperty(_Screen, 'VFPX_Deploy_ProjectName')

Endproc &&Deploy

* ================================================================================
* ================================================================================
* Create the basic structure for VFPX / github documentation
Procedure SetDocumentation
	Lparameters;
		tcCurrFolder,;
		tcVFPXDeploymentFolder,;
		tlInclude_VFPX,;
		tcSubstituteListing,;
		taPlaceholders

	External Array;
		taPlaceholders

*check for several VFPX defaults:
	Local;
		lcFiles As String,;
		lcSource As String,;
		lcText As String,;
		lnFile As Number,;
		lnFiles As Number,;
		lnI   As Number

	Local Array;
		laFiles(1, 1)

	If Not File(m.tcCurrFolder + 'README.md') Then
		If m.tlInclude_VFPX Then
			lcText = Filetostr(m.tcVFPXDeploymentFolder + 'VFPXTemplate\R_README.md')
			lcText = ReplacePlaceholders_Once(@taPlaceholders,m.lcText)
			lcText = ReplacePlaceholders_Run (@taPlaceholders,m.lcText)
			Strtofile(m.lcText, 'README.md')

		Endif &&m.tlInclude_VFPX
	Else  &&Not File(m.tcCurrFolder + 'README.md')
		If File(m.tcCurrFolder + 'README.md') Then
			lcText = Filetostr('README.md')
			lcText = ReplacePlaceholders_Run (@taPlaceholders,m.lcText)
			Strtofile(m.lcText, 'README.md')

		Endif &&File(m.tcCurrFolder + 'README.md')
	Endif &&Not File(m.tcCurrFolder + 'README.md')

	If m.tlInclude_VFPX Then
		If Not File(m.tcCurrFolder + 'BuildProcess\README.md') Then
			lcText = Filetostr(m.tcVFPXDeploymentFolder + 'VFPXTemplate\B_README.md')
			lcText = ReplacePlaceholders_Once(@taPlaceholders,m.lcText)
			lcText = ReplacePlaceholders_Run (@taPlaceholders,m.lcText)
			Strtofile(m.lcText, 'BuildProcess\README.md')
		Endif &&Not File(m.tcCurrFolder + 'BuildProcess\README.md')

		If Not File(m.tcCurrFolder + 'BuildProcess\.gitignore') Then
			lcText = Filetostr(m.tcVFPXDeploymentFolder + 'VFPXTemplate\B.gitignore')
			lcText = ReplacePlaceholders_Once(@taPlaceholders,m.lcText)
			Strtofile(m.lcText, 'BuildProcess\.gitignore')
		Endif &&Not File(m.tcCurrFolder + 'BuildProcess\README.md')

		If Not File(m.tcCurrFolder + 'ThorUpdater\README.md') Then
			lcText = Filetostr(m.tcVFPXDeploymentFolder + 'VFPXTemplate\T_README.md')
			lcText = ReplacePlaceholders_Once(@taPlaceholders,m.lcText)
			lcText = ReplacePlaceholders_Run (@taPlaceholders,m.lcText)
			Strtofile(m.lcText, 'ThorUpdater\README.md')
		Endif &&Not File(m.tcCurrFolder + 'ThorUpdater\README.md')

		If Not File(m.tcCurrFolder + 'ThorUpdater\.gitignore') Then
			lcText = Filetostr(m.tcVFPXDeploymentFolder + 'VFPXTemplate\T.gitignore')
			lcText = ReplacePlaceholders_Once(@taPlaceholders,m.lcText)
			Strtofile(m.lcText, 'ThorUpdater\.gitignore')
		Endif &&Not File(m.tcCurrFolder + 'ThorUpdater\README.md')

		If Not File(m.tcCurrFolder + '.gitignore') Then
			lcText = Filetostr(m.tcVFPXDeploymentFolder + 'VFPXTemplate\C.gitignore')
			lcText = ReplacePlaceholders_Once(@taPlaceholders,m.lcText)
			Strtofile(m.lcText, '.gitignore')
		Endif &&Not File(m.tcCurrFolder + '.gitignore')

		If Not File(m.tcCurrFolder + '.gitattributes') Then
			lcText = Filetostr(m.tcVFPXDeploymentFolder + 'VFPXTemplate\R.gitattributes')
			lcText = ReplacePlaceholders_Once(@taPlaceholders,m.lcText)
			Strtofile(m.lcText, '.gitattributes')
		Endif &&Not File(m.tcCurrFolder + '.gitattributes')

		If Not Directory(m.tcCurrFolder + '.github') Then
			Mkdir .github
			Copy File (m.tcVFPXDeploymentFolder + 'VFPXTemplate\.github\*.*') To ;
				.github\*.*

			For lnFile = 1 To Adir(laFiles,'.github\*.*')
				lcText = Filetostr('.github\' + laFiles(m.lnFile, 1))
				lcText = ReplacePlaceholders_Once(@taPlaceholders,m.lcText)
				Strtofile(m.lcText, '.github\' + Forceext(laFiles(m.lnFile, 1),Lower(Justext(laFiles(m.lnFile, 1)))))

			Endfor &&lnFile

			Mkdir .github\ISSUE_TEMPLATE
			Copy File (m.tcVFPXDeploymentFolder + 'VFPXTemplate\.github\ISSUE_TEMPLATE\*.*') To ;
				.github\ISSUE_TEMPLATE\*.*

			For lnFile = 1 To Adir(laFiles,'.github\ISSUE_TEMPLATE\*.*')
				lcText = Filetostr('.github\ISSUE_TEMPLATE\' + laFiles(m.lnFile, 1))
				lcText = ReplacePlaceholders_Once(@taPlaceholders,m.lcText)
				Strtofile(m.lcText, '.github\ISSUE_TEMPLATE\' + Lower(laFiles(m.lnFile, 1)))

			Endfor &&lnFile

		Endif &&Not Directory(m.tcCurrFolder + '.github')

		If Not Directory(m.tcCurrFolder + 'docs') Then
			Mkdir docs
			Copy File (m.tcVFPXDeploymentFolder + 'VFPXTemplate\docs\*.*') To ;
				docs\*.*

			For lnFile = 1 To Adir(laFiles,'docs\*.*')
				lcText = Filetostr('docs\' + laFiles(m.lnFile, 1))
				lcText = ReplacePlaceholders_Once(@taPlaceholders,m.lcText)
				Strtofile(m.lcText, 'docs\' + laFiles(m.lnFile, 1))

			Endfor &&lnFile
		Endif &&Not Directory(m.tcCurrFolder + 'docs')

		If Not Directory(m.tcCurrFolder + 'docs\images') Then
			Mkdir docs\images
			Copy File (m.tcVFPXDeploymentFolder + 'VFPXTemplate\docs\images\*.*') To ;
				docs\images\*.*
		Endif &&Not Directory(m.tcCurrFolder + 'docs\images')
	Endif


	If File(m.tcSubstituteListing) Then
* If InstalledFiles.txt exists, copy the files listed in it to the
* InstalledFiles folder (folders are created as necessary).
		lcFiles = Filetostr(m.tcSubstituteListing)
		lnFiles = Alines(laFiles, m.lcFiles, 1 + 4)
*process includes
		For lnI = 1 To m.lnFiles
			lcSource = laFiles[m.lnI]
			If Left(Ltrim(m.lcSource), 1) == '#' Then
				Loop
			Endif &&(Left(Ltrim(m.lcSource), 1) == '#'
			If Right(m.lcSource, 1) == '\' Then
* just with subfolders
				ScanDir_Templates(m.tcCurrFolder + m.lcSource)
			Else
* just file / skeleton
				lcText = Filetostr(m.tcCurrFolder + laFiles[m.lnI])
				lcText = ReplacePlaceholders_Run (@taPlaceholders,m.lcText)
				Strtofile(m.lcText,m.tcCurrFolder + laFiles[m.lnI])
			Endif

		Next &&lnI
	Endif &&File(m.lcInstalledFilesListing)
Endproc &&SetDocumentation


* ================================================================================
* ================================================================================
* Create an array with placeholders and there values to substitude
Procedure ACreate_Placeholders
	Lparameters;
		taPlaceholders

	External Array;
		taPlaceholders
	Dimension;
		taPlaceholders(10, 3)

	taPlaceholders( 1, 1) = 'APPNAME'
	taPlaceholders( 2, 1) = 'APPID'
	taPlaceholders( 3, 1) = 'CURRDATE'
	taPlaceholders( 4, 1) = 'VERSIONDATE'
	taPlaceholders( 5, 1) = 'CVERSIONDATE'	&&DeploymentDate in old *_Run proc
	taPlaceholders( 6, 1) = 'VERSION'
	taPlaceholders( 7, 1) = 'JULIAN'
	taPlaceholders( 8, 1) = 'REPOSITORY'
	taPlaceholders( 9, 1) = 'VERNO'
	taPlaceholders(10, 1) = 'CHANGELOG_F'

	taPlaceholders( 1, 2) = m.pcAppName
	taPlaceholders( 2, 2) = m.pcAppID
	taPlaceholders( 3, 2) = m.pcThisDate
	taPlaceholders( 4, 2) = m.pcDate
	taPlaceholders( 5, 2) = m.pcVersionDate
	taPlaceholders( 6, 2) = m.pcVersion
	taPlaceholders( 7, 2) = m.pcJulian
	taPlaceholders( 8, 2) = m.pcRepository
	taPlaceholders( 9, 2) = m.pcFullVersion
	taPlaceholders(10, 2) = m.pcChangeLog
Endproc &&ACreate_Placeholders

* ================================================================================
* ================================================================================
* Substitude placeholder with values. This could only be done once
Procedure ReplacePlaceholders_Once
	Lparameters;
		taPlaceholders,;
		tcText

	External Array;
		taPlaceholders

	Local;
		lcRemove      As String,;
		lcText        As String,;
		tnPlaceholder As Integer,;
		lnI           As Number

	lcText = m.tcText

	For tnPlaceholder = 1 To Alen(taPlaceholders,1)
		lcText = Strtran(m.lcText, '{' + taPlaceholders(m.tnPlaceholder, 1) + '}', taPlaceholders(m.tnPlaceholder, 2), -1, -1, 1)
	Endfor &&tnPlaceholder
	lcText = Textmerge(m.lcText)

	For lnI = Occurs('@@@', m.lcText) To 1 Step -1
		lcRemove = Strextract(m.lcText, '@@@', '\\\', m.lnI, 4)
		lcText   = Strtran(m.lcText, m.lcRemove)

	Next &&lnI

	Return m.lcText
Endproc &&ReplacePlaceholders_Once

* ================================================================================
* ================================================================================
* Substitude marked sections. This could be repeated over and over
Procedure ReplacePlaceholders_Run
	Lparameters;
		taPlaceholders,;
		tcText

	External Array;
		taPlaceholders

	Local;
		tnPlaceholder As Integer,;
		lnLen         As Number,;
		lnOccurence   As Number,;
		lnStart       As Number

	tcText  = Strtran(m.tcText, '<!--DEPLOYMENTDATE-->' , '<!--CVERSIONDATE-->' , 1, -1, 1)
	tcText  = Strtran(m.tcText, '<!--/DEPLOYMENTDATE-->', '<!--/CVERSIONDATE-->', 1, -1, 1)

	For tnPlaceholder = 1 To Alen(taPlaceholders,1)
		lcStart = '<!--' + taPlaceholders(m.tnPlaceholder, 1) + '-->'
		lcEnd   = '<!--/' + taPlaceholders(m.tnPlaceholder, 1) + '-->'
		For lnOccurence = 1 To Occurs(m.lcStart, Upper(m.tcText))
			lnStart = Atc(m.lcStart, m.tcText, m.lnOccurence)
			lnLen   = Atc(m.lcEnd, Substr(m.tcText,m.lnStart))
*	 tcText  = stuff(tcText, lnStart, lnLen, '<!--VerNo-->' + pcFullVersion)
			If m.lnLen>0 Then
				tcText  = Stuff(m.tcText, m.lnStart, m.lnLen - 1, m.lcStart + taPlaceholders(m.tnPlaceholder, 2))

			Endif &&m.lnLen>0
		Next &&lnOccurence

	Endfor &&tnPlaceholder
*!*		For lnOccurence = 1 To Occurs('<!--DEPLOYMENTDATE-->', Upper(m.tcText))
*!*			lnStart = Atc('<!--DeploymentDate-->', m.tcText, m.lnOccurence)
*!*			lnLen   = Atc('<!--/DeploymentDate-->', Substr(m.tcText,m.lnStart))
*!*	*	 tcText  = stuff(tcText, lnStart, lnLen, '<!--DeploymentDate-->' + tcVersionDateD)
*!*			If m.lnLen>0 Then
*!*				tcText  = Stuff(m.tcText, m.lnStart, m.lnLen - 1, '<!--DeploymentDate-->' + pcVersionDate)

*!*			Endif &&m.lnLen>0
*!*		Next &&lnOccurence

	Return m.tcText
Endproc &&ReplacePlaceholders_Run

* ================================================================================
* ================================================================================
* Substitude
* run through a folder structure, and substitude marked sections on each file
Procedure ScanDir_Templates
	Lparameters;
		tcSource
	Local;
		lcOldDir As String,;
		lcText As String,;
		lnLoop1 As Number

	Local Array;
		laDir(1),;
		laFiles(1)

	lcOldDir = Fullpath("", "")
	Cd (m.tcSource)
	For lnLoop1 = 1 To Adir(m.laDir, '', 'D')
		If Inlist(laDir(m.lnLoop1, 1), '.', '..') Then
			Loop
		Endif &&Inlist(laDir(m.lnLoop1,1), '.', '..')

		ScanDir_ScanDir_Templates(Addbs(m.tcSource + laDir(m.lnLoop1, 1)))
	Endfor &&lnLoop1

	For lnLoop1  = 1 To Adir(laFiles, m.tcSource + '*.*', '', 1)
		lcText = Filetostr(m.tcSource + laFiles[m.lnI])
		lcText = ReplacePlaceholders_Run (m.lcText)
		Strtofile(m.lcText,m.tcSource + laFiles[m.lnI])
	Endfor &&lnLoop1

	Cd (m.lcOldDir)

Endproc &&ScanDir_Templates

* ================================================================================
* ================================================================================
* Create stage folder
* run through a folder structure, copy all files to a target
* optional: run through a folder structure (stage) and remove files
Procedure ScanDir_InstFiles
	Lparameters;
		tcSourceDir,;
		tcTargetDir,;
		tlExclude


	Local;
		lcOldDir As String,;
		lnLoop1 As Number

	Local Array;
		laDir(1)

	lcOldDir = Fullpath("", "")
	Cd (m.tcSourceDir)
	For lnLoop1 = 1 To Adir(m.laDir, '', 'D')
		If Inlist(laDir(m.lnLoop1, 1), '.', '..') Then
			Loop
		Endif &&Inlist(laDir(m.lnLoop1,1), '.', '..')
		If m.tlExclude Then
*tcTargetDir is the pattern, just keep it
			ScanDir_InstFiles(Addbs(m.tcSourceDir + laDir(m.lnLoop1, 1)), m.tcTargetDir, m.tlExclude)
		Else  &&m.tlExclude
			ScanDir_InstFiles(Addbs(m.tcSourceDir + laDir(m.lnLoop1, 1)), Addbs(m.tcTargetDir + laDir(m.lnLoop1, 1)), m.tlExclude)
		Endif &&m.tlExclude

	Endfor &&lnLoop1
	If m.tlExclude Then
*just delete pattern
		Delete File (m.tcTargetDir)
	Else  &&m.tlExclude
		Copy_InstallFile(Addbs(m.tcSourceDir) + '*.*', Addbs(m.tcTargetDir) + '*.*')
	Endif &&m.tlExclude
	Cd (m.lcOldDir)

Endproc &&ScanDir_InstFiles

* ================================================================================
* ================================================================================
* Create stage folder
* in stage folder, check for a given folder (or the stage itself), create if missing
* copy files to the stage given by a pattern
Procedure Copy_InstallFile
	Lparameters;
		tcSource,;
		tcTarget

	Local;
		lcFolder As String

	Local Array;
		laDir(1)

	lcFolder = Justpath(m.tcTarget)
	If Not Directory(m.lcFolder) Then
		Md (m.lcFolder)
	Endif &&Not Directory(m.tcFolder)

	If !Empty(Adir(m.laDir, m.tcSource)) Then
		Copy File (m.tcSource) To (m.tcTarget)
	Endif &&!Empty(Adir(m.laDir, m.tcSource))

Endproc &&Copy_InstallFile

* ================================================================================
* ================================================================================
* Release public vars used internally
Procedure ReleaseThis
	Release;
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

Endproc &&ReleaseThis

**********************************************************************************
*                                                                                *
* Thor independend                                                               *
*                                                                                *
**********************************************************************************

* ================================================================================
* ================================================================================
* Search for project to work with (used for stand alone version)
* Search a pattern of folders to figure out if those folders are within a repository; if true, get toplevel folder
*
* Note: A similar procedure in Thor_Tool_DeployVFPXProject.prg is used for Thor operation
Procedure GetProject_Folder
	Lparameters;
		tcPreviousFolder

	Local;
		lcFolder   As String,;
		lcValidFolder As String

* try if active folder is in a git repository
	lcValidFolder = Validate_TopLevel(Fullpath('',''))
	If Not Empty(m.lcValidFolder) Then
		Return m.lcValidFolder
	Endif &&Not Empty(m.lcValidFolder)

* SF 20230512, try active project next
*in case we have a structure where we sit in a base with many scatterd projects
*we try if the Active Project is the one
	If Type("_VFP.ActiveProject")='O' Then
		lcValidFolder = Justpath(_vfp.ActiveProject.Name)
		If Not Empty(m.lcValidFolder) And  Messagebox('Run for active project' + CRLF + CRLF + '"' + ;
				_vfp.ActiveProject.Name + '" ?', 36, 'VFPX Project Deployment') = 6 Then
			Return m.lcValidFolder

		Endif &&Not Empty(m.lcValidFolder) And Messagebox('Run for active project' + CRLF + CRLF  ...
	Endif &&Type("_VFP.ActiveProject")='O'

*try to get a folder
	Do While .T.
		lcFolder = Getdir(m.tcPreviousFolder, 'Project Home Folder', 'Home Path')
		If Empty(m.lcFolder) Then
			Return ''
		Endif &&Empty(m.lcFolder)

		lcValidFolder = Validate_TopLevel(m.lcFolder)
		If Empty(m.lcValidFolder) Then
			Messagebox('Top level folder not found, not a git repository.', 16, 'VFPX Project Deployment')
		Else &&empty(m.lcValidFolder)
			Return m.lcValidFolder
		Endif &&Empty(m.lcValidFolder)

	Enddo &&.t.

Endproc &&GetProject_Folder

* ================================================================================
* ================================================================================
* Search for project to work with (used for stand alone version)
* use git to check if a given folder is in a repository; if true, return toplevel folder
*
* Note: A similar procedure in Thor_Tool_DeployVFPXProject.prg is used for Thor operation
Procedure Validate_TopLevel
	Lparameters;
		tcFolder

* SF 20230512
*we test if this folder is a git folder and return the git base folder
*no need to search the base folder, git will tell this
* (and not embarrassingly testing for ".git" folder)
	Local;
		lcCommand As String,;
		lcOldFolder As String

	lcOldFolder = Fullpath('','')
	Cd (m.tcFolder)
	Delete File git_x.tmp    && in case

*if git is not installed, we get an empty or no file
	lcCommand = 'git rev-parse --show-toplevel>git_x.tmp'
	Run &lcCommand

	If File('git_x.tmp') Then
*the result is either the git base folder or empty for no git repo
		tcFolder = Chrtran(Filetostr('git_x.tmp'), '/' + CRLF, '\')
		Delete File git_x.tmp
	Else &&file('git_x.tmp')
* no file, no git
		tcFolder = ''
	Endif &&File('git_x.tmp')

	Cd (m.lcOldFolder)
	Return m.tcFolder

Endproc &&Validate_TopLevel

**********************************************************************************
*                                                                                *
* Thor internals                                                                 *
*                                                                                *
**********************************************************************************

* ================================================================================
* ================================================================================
* Thor internal, check version info?
Procedure CheckVersionFile
	Lparameters;
		tcVersionFile

	Local;
		lcErrorMsg As String,;
		llSuccess As Boolean,;
		loException As Object,;
		loUpdater As Object

	loUpdater  = Execscript (_Screen.cThorDispatcher, 'Thor_Proc_GetUpdaterObject2')
	Try
			Do (m.tcVersionFile) With m.loUpdater
			llSuccess = .T.
		Catch To m.loException
			llSuccess = .F.
	Endtry

	If !m.llSuccess Then
		lcErrorMsg = 'Error in Version file:' 		+ CRLF + 			;
			'Msg:   ' + m.loException.Message 		+ CRLF +			;
			'Code:  ' + m.loException.LineContents
		Messagebox(m.lcErrorMsg + CRLF +  CRLF + 'ABORTING', 16, 'VFPX Project Deployment')
	Endif &&!m.llSuccess

	Return m.llSuccess

Endproc &&CheckVersionFile

