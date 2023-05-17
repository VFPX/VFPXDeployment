#DEFINE CRLF CHR(13) + CHR(10)

* Parameter lcFolder is the home folder for the project
*   and defaults to the current folder if not supplied
LPARAMETERS;
 tcFolder

LOCAL;
 lcCurrFolder        AS STRING,;
 lcProjectName       AS STRING,;
 lcStartFolder       AS STRING,;
 lcVFPXDeploymentFolder AS STRING

* Get the project folder.
lcStartFolder = FULLPATH("", "")
tcFolder      = EVL(m.tcFolder, m.lcStartFolder)
CD (m.tcFolder) && Project Home

* Bug out if NoVFPXDeployment.txt exists.

IF FILE('NoVFPXDeployment.txt') THEN
 MESSAGEBOX('VFPX Project Deployment will not run because NoVFPXDeployment.txt exists.', ;
   16, 'VFPX Project Deployment')
 RETURN
ENDIF &&file('NoVFPXDeployment.txt')

* Create the BuildProcess subdirectory of the project folder if necessary.

lcCurrFolder = ADDBS(ADDBS(m.tcFolder) + 'BuildProcess') && BuildProcess
IF NOT DIRECTORY(m.lcCurrFolder) THEN
*SF 20230512 we better check if this exists a different Thor
*this is not fool-proof, since there are many ways to do Thor
*but a very common one
 IF DIRECTORY(ADDBS(m.tcFolder) + 'ThorUpdater') THEN
  MESSAGEBOX('There is allready a Thor folder.' + CRLF + CRLF + 'Stoped.', ;
    16, 'VFPX Project Deployment')
  RETURN
 ENDIF &&directory(addbs(m.tcFolder) + 'ThorUpdater')
 MD (m.lcCurrFolder)
ENDIF &&not directory(m.lcCurrFolder)

* If we don't have ProjectSettings.txt, copy it, VersionTemplate.txt, and
* BuildMe.prg, AfterBuild.prg from the VFPXDeployment folder.

lcVFPXDeploymentFolder = _SCREEN.cThorFolder + 'Tools\Apps\VFPXDeployment\'

IF NOT FILE(m.lcCurrFolder + 'ProjectSettings.txt') THEN
 COPY FILE (m.lcVFPXDeploymentFolder + 'ProjectSettings.txt') TO ;
  (m.lcCurrFolder + 'ProjectSettings.txt')
 COPY FILE (m.lcVFPXDeploymentFolder + 'VersionTemplate.txt') TO ;
  (m.lcCurrFolder + 'VersionTemplate.txt')
 COPY FILE (m.lcVFPXDeploymentFolder + 'BuildMe.prg') TO ;
  (m.lcCurrFolder + 'BuildMe.prg')
 COPY FILE (m.lcVFPXDeploymentFolder + 'AfterBuild.prg') TO ;
  (m.lcCurrFolder + 'AfterBuild.prg')
 MESSAGEBOX('Please edit ProjectSettings.txt and fill in the settings ' + ;
   'for this project.' + CRLF + ;
   'Also, edit InstalledFiles.txt and specify ' + ;
   'which files should be installed.' + CRLF +  CRLF +;
   'Then run VFPX Project Deployment again.', ;
   16, 'VFPX Project Deployment')
 MODIFY FILE (m.lcCurrFolder + 'ProjectSettings.txt') NOWAIT
 MODIFY FILE (m.lcCurrFolder + 'InstalledFiles.txt') NOWAIT
 RETURN
ENDIF &&not file(m.lcCurrFolder + 'ProjectSettings.txt')

lcProjectName = GETWORDNUM(m.lcCurrFolder, GETWORDCOUNT(m.lcCurrFolder, '\') - 1, '\')
Deploy(m.lcVFPXDeploymentFolder, m.lcProjectName, ADDBS(m.tcFolder))

* Restore the former current directory.

CD (m.lcStartFolder)

RETURN


* ================================================================================
* ================================================================================
* The work horse - put in separate Proc so that any the cd (lcStartFolder) is always run

PROCEDURE Deploy
 LPARAMETERS;
  tcVFPXDeploymentFolder,;
  tcProjectName,;
  tcCurrFolder


* Put the paths for files we may use into variables.

 LOCAL;
  lcAfterBuildProgram  AS STRING,;
  lcAppFile            AS STRING,;
  lcBin2PRGFolder      AS STRING,;
  lcBin2PRGFolderSource AS STRING,;
  lcBuildProgram       AS STRING,;
  lcCategory           AS STRING,;
  lcChange             AS STRING,;
  lcCommand            AS STRING,;
  lcComponent          AS STRING,;
  lcContent            AS STRING,;
  lcErrFile            AS STRING,;
  lcFile               AS STRING,;
  lcFiles              AS STRING,;
  lcFolder             AS STRING,;
  lcFoxBin2PRG         AS STRING,;
  lcInstalledFilesFolder AS STRING,;
  lcInstalledFilesListing AS STRING,;
  lcSubstitudeListing  AS STRING,;
  lcLine               AS STRING,;
  lcName               AS STRING,;
  lcPJXFile            AS STRING,;
  lcProjectFile        AS STRING,;
  lcProjectSettings    AS STRING,;
  lcRecompile          AS STRING,;
  lcRepositoryRoot     AS STRING,;
  lcSource             AS STRING,;
  lcTarget             AS STRING,;
  lcUName              AS STRING,;
  lcUpdateFile         AS STRING,;
  lcUpdateTemplateFile AS STRING,;
  lcValue              AS STRING,;
  lcVersion            AS STRING,;
  lcVersionFile        AS STRING,;
  lcVersionTemplateFile AS STRING,;
  lcZipFile            AS STRING,;
  llInculde_VFPX       AS BOOLEAN,;
  llInculde_Thor       AS BOOLEAN,;
  llPrompt             AS BOOLEAN,;
  llRecompile          AS BOOLEAN,;
  lnBin2PRGFolders     AS NUMBER,;
  lnFiles              AS NUMBER,;
  lnI                  AS NUMBER,;
  lnJulian             AS NUMBER,;
  lnPos                AS NUMBER,;
  lnProject            AS NUMBER,;
  lnSettings           AS NUMBER
 LOCAL lnWords


 LOCAL ARRAY;
  laBin2PRGFolders(1),;
  laFiles(1,1),;
  laWords(1,1),;
  laSettings(1)

 lcProjectFile           = m.tcCurrFolder + 'BuildProcess\ProjectSettings.txt'
 lcInstalledFilesListing = m.tcCurrFolder + 'BuildProcess\InstalledFiles.txt'
 lcSubstitudeListing     = m.tcCurrFolder + 'BuildProcess\Substitude.txt'
 lcInstalledFilesFolder  = 'InstalledFiles'
 lcBuildProgram          = m.tcCurrFolder + 'BuildProcess\BuildMe.prg'
 lcAfterBuildProgram     = m.tcCurrFolder + 'BuildProcess\AfterBuild.prg'
 lcVersionTemplateFile   = m.tcCurrFolder + 'BuildProcess\VersionTemplate.txt'
 lcUpdateTemplateFile    = _SCREEN.cThorFolder + ;
  'Tools\Apps\VFPXDeployment\Thor_Update_Template.txt'

* Get the current project settings into public variables.

 lcProjectSettings = FILETOSTR(m.lcProjectFile)
 PUBLIC;
  pcAppName     AS STRING,;
  pcAppID       AS STRING,;
  pcVersion     AS STRING,;
  pdVersionDate AS DATE,;
  pcVersionDate AS STRING,;
  pcChangeLog   AS STRING,;
  plContinue    AS BOOLEAN
*SF 20230512: add new flags
 PUBLIC;
  pcFullVersion AS STRING,;
  pcDate        AS STRING,;
  pcJulian      AS STRING,;
  pcThisDate    AS STRING,;
  pcRepository  AS STRING,;
  plRun_Bin2Prg AS BOOLEAN,;
  plRun_git     AS BOOLEAN

 pdVersionDate = DATE()
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
 llInculde_VFPX        = .F.
 llInculde_Thor        = .T.
 lnSettings            = ALINES(laSettings, m.lcProjectSettings)
 FOR lnI = 1 TO m.lnSettings
  lcLine  = laSettings[m.lnI]
  lnPos   = AT('=', m.lcLine)
  lcName  = ALLTRIM(LEFT(m.lcLine, m.lnPos - 1))
  lcValue = ALLTRIM(SUBSTR(m.lcLine, m.lnPos + 1))
  lcUName = UPPER(m.lcName)
  DO CASE
   CASE m.lcUName = 'APPNAME'
    pcAppName = m.lcValue
   CASE m.lcUName = 'APPID'
    pcAppID = m.lcValue
   CASE m.lcUName = 'VERSION'
    pcVersion = m.lcValue
   CASE m.lcUName = 'VERSIONDATE'
    pdVersionDate = EVALUATE('{^' + m.lcValue + '}')
   CASE m.lcUName = 'PROMPT'
    llPrompt = UPPER(m.lcValue) = 'Y'
   CASE m.lcUName = 'CHANGELOG'
    pcChangeLog = m.lcValue
   CASE m.lcUName = 'BIN2PRGFOLDER'
    lcBin2PRGFolderSource = m.lcValue
   CASE m.lcUName = 'COMPONENT'
    lcComponent = m.lcValue
   CASE m.lcUName = 'CATEGORY'
    lcCategory = m.lcValue
   CASE m.lcUName = 'PJXFILE'
    lcPJXFile = m.lcValue
   CASE m.lcUName = 'RECOMPILE'
    llRecompile = UPPER(m.lcValue) = 'Y'
   CASE m.lcUName = 'APPFILE'
    lcAppFile = m.lcValue
   CASE m.lcUName = 'REPOSITORY'
    pcRepository = m.lcValue
   CASE m.lcUName = 'INSTALLEDFILESFOLDER'
    lcInstalledFilesFolder = m.lcValue
*SF 20230512: new flags
   CASE m.lcUName = 'RUNBIN2PRG'
    plRun_Bin2Prg = UPPER(m.lcValue) = 'Y'
   CASE m.lcUName = 'RUNGIT'
    plRun_git = UPPER(m.lcValue) = 'Y'
   CASE m.lcUName = 'INCULDE_VFPX'
    llInculde_VFPX = UPPER(m.lcValue) = 'Y'
   CASE m.lcUName = 'INCULDE_THOR'
    llInculde_Thor = UPPER(m.lcValue) = 'Y'
*/SF 20230512
  ENDCASE
 NEXT &&lnI

*SF 20230512, get pjx version
 IF UPPER(m.pcVersion)=='PJX' THEN
  pcVersion = ''
  IF EMPTY(m.lcPJXFile) THEN
*use the active pjx, since no pjx is defined
   IF TYPE("_VFP.ActiveProject")='O' THEN
    pcVersion = _VFP.ACTIVEPROJECT.VERSIONNUMBER

   ENDIF &&type("_VFP.ActiveProject")='O'
  ELSE  &&empty(m.lcPJXFile)
*use pjx defined
*bit more work
*see if the project is open
   FOR lnProject = 1 TO _VFP.PROJECTS.COUNT
    IF UPPER(FULLPATH(m.lcPJXFile))==UPPER(_VFP.PROJECTS(m.lnProject).NAME) THEN
     pcVersion = _VFP.PROJECTS(m.lnProject).VERSIONNUMBER
     EXIT

    ENDIF &&upper(fullpath(m.lcPJXFile))==upper(_vfp.projects(m.lnProject).name)
   ENDFOR &&lnProject

   IF EMPTY(m.pcVersion);
     AND FILE(FULLPATH(m.lcPJXFile)) THEN
    MODIFY PROJECT (FULLPATH(m.lcPJXFile)) NOWAIT NOSHOW NOPROJECTHOOK
    pcVersion = _VFP.PROJECTS(m.lnProject).VERSIONNUMBER
    _VFP.ACTIVEPROJECT.CLOSE

   ENDIF &&empty(m.pcVersion) and file(fullpath(m.lcPJXFile))
  ENDIF &&empty(m.lcPJXFile)

  IF EMPTY(m.pcVersion) THEN
   MESSAGEBOX('No project to get version number from found.', 16, ;
     'VFPX Project Deployment')
   ReleaseThis()
   RETURN

  ENDIF &&empty(m.pcVersion)
 ENDIF &&upper(m.pcVersion)=='PJX'
* Ensure we have valid pcAppName and pcAppID values.

 IF EMPTY(m.pcAppName) THEN
  MESSAGEBOX('The appName setting was not specified.', 16, ;
    'VFPX Project Deployment')
  ReleaseThis()
  RETURN
 ENDIF &&empty(m.pcAppName)

 IF EMPTY(m.pcAppID) THEN
  MESSAGEBOX('The appID setting was not specified.', 16, ;
    'VFPX Project Deployment')
  ReleaseThis()
  RETURN
 ENDIF &&empty(m.pcAppID)

 IF ' ' $ m.pcAppID OR '	' $ m.pcAppID THEN
  MESSAGEBOX('The appID setting cannot have spaces or tabs.', 16, ;
    'VFPX Project Deployment')
  ReleaseThis()
  RETURN
 ENDIF &&' ' $ m.pcAppID or '	' $ m.pcAppID

* If we're supposed to build an APP or EXE, ensure we have both settings
* and we're running VFP 9 and not VFP Advanced since the APP/EXE structure
* is different. If AppFile is omitted, use the same folder and name as the
* PJX file.

 IF NOT EMPTY(m.lcPJXFile) AND EMPTY(m.lcAppFile) THEN
  lcAppFile = FORCEEXT(m.lcPJXFile, 'app')
 ENDIF &&not empty(m.lcPJXFile) and empty(m.lcAppFile)

 IF (EMPTY(m.lcPJXFile) AND NOT EMPTY(m.lcAppFile)) OR ;
   (EMPTY(m.lcAppFile) AND NOT EMPTY(m.lcPJXFile)) THEN
  MESSAGEBOX('If you specify one of them, you have to specify both ' + ;
    'PJXFile and AppFile.', 16, 'VFPX Project Deployment')
  ReleaseThis()
  RETURN
 ENDIF &&(empty(m.lcPJXFile) and not empty(m.lcAppFile)) or (empty(m.lcAppFile) and not empty(m.lcPJXFile))

 IF NOT EMPTY(m.lcPJXFile) AND VAL(VERSION(4)) > 9 THEN
  MESSAGEBOX('You must run VFPX Project Deployment using VFP 9 not VFP Advanced.', ;
    16, 'VFPX Project Deployment')
  ReleaseThis()
  RETURN
 ENDIF &&not empty(m.lcPJXFile) and val(version(4)) > 9

* If Bin2PRGFolderSource or PJXFile was supplied, find FoxBin2PRG.EXE.

 lcBin2PRGFolder = ''
 lcFoxBin2PRG    = ''
 IF m.plRun_Bin2Prg AND (NOT EMPTY(m.lcBin2PRGFolderSource) OR NOT EMPTY(m.lcPJXFile)) THEN
  lcFoxBin2PRG = EXECSCRIPT(_SCREEN.cThorDispatcher, 'Thor_Proc_GetFoxBin2PrgFolder') + ;
   'FoxBin2Prg.exe'

  DO CASE
   CASE NOT FILE(m.lcFoxBin2PRG)
    MESSAGEBOX('FoxBin2PRG.EXE not found.', 16, ;
      'VFPX Project Deployment')
    ReleaseThis()
    RETURN
* &&not file(m.lcFoxBin2PRG)

   CASE NOT EMPTY(m.lcBin2PRGFolderSource)
    lnBin2PRGFolders = ALINES(laBin2PRGFolders, m.lcBin2PRGFolderSource, 4, ',')
    FOR lnI = 1 TO m.lnBin2PRGFolders
     lcFolder                = laBin2PRGFolders[m.lnI]
     laBin2PRGFolders[m.lnI] = FULLPATH(m.tcCurrFolder + m.lcFolder)
     IF NOT DIRECTORY(laBin2PRGFolders[m.lnI]) THEN
      MESSAGEBOX('Folder "' + m.lcFolder + '" not found.', 16,	;
        'VFPX Project Deployment')
      ReleaseThis()
      RETURN

     ENDIF &&not directory(laBin2PRGFolders[m.lnI])
    NEXT &&lnI
* &&not empty(m.lcBin2PRGFolderSource)

  ENDCASE
 ENDIF &&m.plRun_Bin2Prg and (not empty(m.lcBin2PRGFolderSource) or not empty(m.lcPJXFile))

* Get the names of the zip, Thor CFU version, and Thor updaters files and set pcVersionDate to
* a string version of the release date.

 lcZipFile     = 'ThorUpdater\' + m.pcAppID + '.zip'
 lcVersionFile = 'ThorUpdater\' + m.pcAppID + 'Version.txt'
 lcUpdateFile  = m.tcCurrFolder + 'BuildProcess\Thor_Update_' + m.pcAppID + '.prg'
 pcDate        = DTOC(m.pdVersionDate, 1)
 pcVersionDate = STUFF(STUFF(m.pcDate, 7, 0, '-'), 5, 0, '-')

 lnJulian = m.pdVersionDate - {^2000-01-01}
 pcJulian = PADL(m.lnJulian, 5, '0')

 pcThisDate = 'date(' + TRANSFORM(YEAR(DATE())) + ', ' + ;
  TRANSFORM(MONTH(DATE())) + ', ' + TRANSFORM(DAY(DATE())) + ')'

* Get the repository to use if it wasn't specified.

 IF EMPTY(m.pcRepository) THEN
  pcRepository = m.lcRepositoryRoot + m.pcAppID
 ENDIF &&empty(m.pcRepository)

* Get the version number if it wasn't specified and we're supposed to.

 IF EMPTY(m.pcVersion) AND m.llPrompt THEN
  lcValue = INPUTBOX('Version', 'VFPX Project Deployment', '')
  IF EMPTY(m.lcValue) THEN
   ReleaseThis()
   RETURN
  ENDIF &&empty(m.lcValue)
  pcVersion = m.lcValue

 ENDIF &&empty(m.pcVersion) and m.llPrompt

*SF 20230514 the test for the copy process here, we don't need to proceed if this is not here
 IF !FILE(m.lcInstalledFilesListing) AND !DIRECTORY(m.lcInstalledFilesFolder) THEN
* If no InstalledFiles.txt exists, and no InstalledFiles folder, break
  MESSAGEBOX('Please either create InstalledFiles.txt in the ' + ;
    'BuildProcess folder with each file to be installed by Thor ' + ;
    'listed on a separate line, or create a subdirectory of ' + ;
    'the project folder named InstalledFiles and copy the ' + ;
    'files Thor should install to it.', ;
    16, 'VFPX Project Deployment')
  ReleaseThis()
  RETURN

 ENDIF &&!file(m.lcInstalledFilesListing) and !directory(m.lcInstalledFilesFolder)

 pcFullVersion = m.pcVersion

* Execute BuildMe.prg if it exists. If it sets plContinue to .F., exit.

 IF FILE(m.lcBuildProgram) THEN
  DO (m.lcBuildProgram)
  IF NOT m.plContinue
   ReleaseThis()
   RETURN

  ENDIF &&not m.plContinue
 ENDIF &&file(m.lcBuildProgram)

 IF EMPTY(m.pcVersion) THEN
  MESSAGEBOX('The version setting was not specified.', 16, ;
    'VFPX Project Deployment')
  ReleaseThis()
  RETURN
 ENDIF &&empty(m.pcVersion)

*** JRN 2023-01-10 : Call FoxBin2PRG, if applicable
*SF 20230512: flag to disable FoxBin2PRG
 IF m.plRun_Bin2Prg AND NOT EMPTY(m.lcFoxBin2PRG) THEN
  IF NOT EMPTY(m.lcPJXFile)
   DO (m.lcFoxBin2PRG) WITH FULLPATH(m.lcPJXFile), '*'
  ENDIF &&not empty(m.lcPJXFile)

  IF NOT EMPTY(m.lcBin2PRGFolderSource) THEN
*** JRN 2023-01-29 : BIN2PRG for folder and sub-folders
   FOR lnI = 1 TO m.lnBin2PRGFolders
    lcFolder = laBin2PRGFolders[m.lnI]
    DO (m.lcFoxBin2PRG) WITH 'BIN2PRG', m.lcFolder && + '\*.*'

   NEXT &&lnI
  ENDIF &&not empty(m.lcBin2PRGFolderSource)
 ENDIF &&m.plRun_Bin2Prg and not empty(m.lcFoxBin2PRG)

* Ensure we have a version number (Build.prg may have set it).

* Create an APP/EXE if we're supposed to.

 lcRecompile = IIF(m.llRecompile, 'recompile', '')
 DO CASE
  CASE EMPTY(m.lcPJXFile)
  CASE UPPER(JUSTEXT(m.lcAppFile)) = 'EXE'
   BUILD EXE (m.lcAppFile) FROM (m.lcPJXFile) &lcRecompile
  OTHERWISE
   BUILD APP (m.lcAppFile) FROM (m.lcPJXFile) &lcRecompile
 ENDCASE

 lcErrFile = FORCEEXT(m.lcAppFile, 'err')

 IF NOT EMPTY(m.lcPJXFile) AND FILE(m.lcErrFile) THEN
  MESSAGEBOX('An error occurred building the project.' + CRLF +;
    ' Please see the ERR file for details.', 16, 'VFPX Project Deployment')
  MODIFY FILE (m.lcErrFile) NOWAIT
  ReleaseThis()
  RETURN

 ENDIF &&not empty(m.lcPJXFile) and file(m.lcErrFile)

 SetDocumentation (m.tcCurrFolder, m.tcVFPXDeploymentFolder, m.llInculde_VFPX, m.lcSubstitudeListing)

*SF 20230514 the test is moved to a place above, so no processing is done
 IF m.llInculde_Thor THEN
  IF FILE(m.lcInstalledFilesListing) THEN
* If InstalledFiles.txt exists, copy the files listed in it to the
* InstalledFiles folder (folders are created as necessary).
   lcFiles = FILETOSTR(m.lcInstalledFilesListing)
   lnFiles = ALINES(laFiles, m.lcFiles, 1 + 4)
   FOR lnI = 1 TO m.lnFiles
    IF LEFT(LTRIM(laFiles[m.lnI]), 1) == '#' THEN
     LOOP
    ENDIF &&LEFT(LTRIM(laFiles[m.lnI]e), 1) == '#'
    lnWords  = ALINES(laWords, STRTRAN(laFiles[m.lnI], '||', 0h00), 1 + 4,0h00)
    lcSource = laWords[1]
    lcTarget = IIF(m.lnWords=1, laWords[1],  laWords[2])
    IF RIGHT(m.lcSource, 1) == '\' THEN
* just with subfolders
     ScanDir_InstFiles(m.tcCurrFolder + m.lcSource, ADDBS(FULLPATH(m.lcInstalledFilesFolder, m.tcCurrFolder)) + m.lcTarget)
    ELSE
* just file / skeleton
     Copy_InstallFile(m.tcCurrFolder + m.lcSource, ADDBS(FULLPATH(m.lcInstalledFilesFolder, m.tcCurrFolder)) + m.lcTarget)
    ENDIF

   NEXT &&lnI
  ENDIF &&file(m.lcInstalledFilesListing)

* Create the ThorUpdater folder if necessary.

  IF NOT DIRECTORY('ThorUpdater') THEN
   MD ThorUpdater
  ENDIF &&not directory('ThorUpdater')

* Update Version.txt.
  lcVersion = FILETOSTR(m.lcVersionTemplateFile)

  lcChange  = IIF(FILE(m.pcChangeLog), FILETOSTR(m.pcChangeLog), '')
  lcVersion = STRTRAN(m.lcVersion, '{CHANGELOG}', m.lcChange,     -1, -1, 1)
  lcVersion = STRTRAN(m.lcVersion, '{COMPONENT}', m.lcComponent,  -1, -1, 1)
  lcVersion = STRTRAN(m.lcVersion, '{CATEGORY}',  m.lcCategory,   -1, -1, 1)

  lcVersion = ReplacePlaceholders_Once(m.lcVersion)

  STRTOFILE(m.lcVersion, m.lcVersionFile)

* check proposed version file for errors
  IF CheckVersionFile(m.lcVersionFile) = .F. THEN
   ReleaseThis()
   RETURN

  ENDIF &&CheckVersionFile(m.lcVersionFile) = .f.
  ERASE (FORCEEXT(m.lcVersionFile, 'fxp'))

* Update Thor_Update program.

  IF FILE(m.lcUpdateTemplateFile) AND NOT FILE(m.lcUpdateFile) THEN
   lcContent = FILETOSTR(m.lcUpdateTemplateFile)

   lcContent = ReplacePlaceholders_Once(m.lcVersion)

   lcContent = STRTRAN(m.lcContent, '{COMPONENT}', m.lcComponent, ;
     -1, -1, 1)
   STRTOFILE(m.lcContent, m.lcUpdateFile)

  ENDIF &&file(m.lcUpdateTemplateFile) and not file(m.lcUpdateFile)

* Zip the source files.

  EXECSCRIPT(_SCREEN.cThorDispatcher, 'Thor_Proc_ZipFolder', m.lcInstalledFilesFolder, m.lcZipFile)

* Add AppID.zip and AppIDVersion.txt to the repository.

*SF 20230512: flag to disable git
  IF m.plRun_git THEN
   lcCommand = 'git add ' + m.lcZipFile + ' -f'
   RUN &lcCommand
   lcCommand = 'git add ' + m.lcVersionFile
   RUN &lcCommand

* Add the BuildProcess files to the repository.

   FOR lnI = 1 TO ADIR(laFiles, 'BuildProcess\*.*', '', 1)
    lcFile = laFiles[m.lnI, 1]
    IF LOWER(JUSTEXT(m.lcFile)) <> 'fxp' THEN
     lcCommand = 'git add BuildProcess\' + m.lcFile
     RUN &lcCommand

    ENDIF &&lower(justext(m.lcFile)) <> 'fxp'
   NEXT &&lnI
  ENDIF &&plRun_git
 ENDIF &&m.llInculde_Thor

* Execute AfterBuild.prg if it exists.

 IF FILE(m.lcAfterBuildProgram) THEN
  DO (m.lcAfterBuildProgram)
 ENDIF &&file(m.lcAfterBuildProgram)

 ReleaseThis()

 MESSAGEBOX('Deployment for ' + m.tcProjectName + ' complete.' +  CRLF +  CRLF + 'All done', 64, 'VFPX Project Deployment', 5000)

ENDPROC &&Deploy

PROCEDURE SetDocumentation
 LPARAMETERS;
  tcCurrFolder,;
  tcVFPXDeploymentFolder,;
  tlInculde_VFPX,;
  tcSubstitudeListing

*check for several VFPX defaults:
 LOCAL;
  lcText AS STRING,;
  lnFile AS NUMBER
 LOCAL lcFiles,lcSource,lnFiles,lnI


 LOCAL ARRAY;
  laFiles(1, 1)

 IF NOT FILE(m.tcCurrFolder + 'README.md') THEN
  IF m.tlInculde_VFPX THEN
   lcText = FILETOSTR(m.tcVFPXDeploymentFolder + 'VFPXTemplate\R_README.md')
   lcText = ReplacePlaceholders_Once(m.lcText)
   lcText = ReplacePlaceholders_Run (m.lcText)
   STRTOFILE(m.lcText, 'README.md')

  ENDIF &&m.tlInculde_VFPX
 ELSE  &&not file(m.tcCurrFolder + 'README.md')
  IF FILE(m.tcCurrFolder + 'README.md') THEN
   lcText = FILETOSTR('README.md')
   lcText = ReplacePlaceholders_Run (m.lcText)
   STRTOFILE(m.lcText, 'README.md')

  ENDIF &&file(m.tcCurrFolder + 'README.md')
 ENDIF &&not file(m.tcCurrFolder + 'README.md')

 IF m.tlInculde_VFPX THEN
  IF NOT FILE(m.tcCurrFolder + 'BuildProcess\README.md') THEN
   lcText = FILETOSTR(m.tcVFPXDeploymentFolder + 'VFPXTemplate\B_README.md')
   lcText = ReplacePlaceholders_Once(m.lcText)
   lcText = ReplacePlaceholders_Run (m.lcText)
   STRTOFILE(m.lcText, 'BuildProcess\README.md')
  ENDIF &&not file(m.tcCurrFolder + 'BuildProcess\README.md')

  IF NOT FILE(m.tcCurrFolder + 'BuildProcess\.gitignore') THEN
   lcText = FILETOSTR(m.tcVFPXDeploymentFolder + 'VFPXTemplate\B.gitignore')
   lcText = ReplacePlaceholders_Once(m.lcText)
   STRTOFILE(m.lcText, 'BuildProcess\.gitignore')
  ENDIF &&not file(m.tcCurrFolder + 'BuildProcess\README.md')

  IF NOT FILE(m.tcCurrFolder + 'ThorUpdater\README.md') THEN
   lcText = FILETOSTR(m.tcVFPXDeploymentFolder + 'VFPXTemplate\T_README.md')
   lcText = ReplacePlaceholders_Once(m.lcText)
   lcText = ReplacePlaceholders_Run (m.lcText)
   STRTOFILE(m.lcText, 'ThorUpdater\README.md')
  ENDIF &&not file(m.tcCurrFolder + 'ThorUpdater\README.md')

  IF NOT FILE(m.tcCurrFolder + 'ThorUpdater\.gitignore') THEN
   lcText = FILETOSTR(m.tcVFPXDeploymentFolder + 'VFPXTemplate\T.gitignore')
   lcText = ReplacePlaceholders_Once(m.lcText)
   STRTOFILE(m.lcText, 'ThorUpdater\.gitignore')
  ENDIF &&not file(m.tcCurrFolder + 'ThorUpdater\README.md')

  IF NOT FILE(m.tcCurrFolder + '.gitignore') THEN
   lcText = FILETOSTR(m.tcVFPXDeploymentFolder + 'VFPXTemplate\C.gitignore')
   lcText = ReplacePlaceholders_Once(m.lcText)
   STRTOFILE(m.lcText, '.gitignore')
  ENDIF &&not file(m.tcCurrFolder + '.gitignore')

  IF NOT FILE(m.tcCurrFolder + '.gitattributes') THEN
   lcText = FILETOSTR(m.tcVFPXDeploymentFolder + 'VFPXTemplate\R.gitattributes')
   lcText = ReplacePlaceholders_Once(m.lcText)
   STRTOFILE(m.lcText, '.gitattributes')
  ENDIF &&not file(m.tcCurrFolder + '.gitattributes')

  IF NOT DIRECTORY(m.tcCurrFolder + '.github') THEN
   MKDIR .github
   COPY FILE (m.tcVFPXDeploymentFolder + 'VFPXTemplate\.github\*.*') TO ;
    .github\*.*

   FOR lnFile = 1 TO ADIR(laFiles,'.github\*.*')
    lcText = FILETOSTR('.github\' + laFiles(m.lnFile, 1))
    lcText = ReplacePlaceholders_Once(m.lcText)
    STRTOFILE(m.lcText, '.github\' + FORCEEXT(laFiles(m.lnFile, 1),LOWER(JUSTEXT(laFiles(m.lnFile, 1)))))

   ENDFOR &&lnFile

   MKDIR .github\ISSUE_TEMPLATE
   COPY FILE (m.tcVFPXDeploymentFolder + 'VFPXTemplate\.github\ISSUE_TEMPLATE\*.*') TO ;
    .github\ISSUE_TEMPLATE\*.*

   FOR lnFile = 1 TO ADIR(laFiles,'.github\ISSUE_TEMPLATE\*.*')
    lcText = FILETOSTR('.github\ISSUE_TEMPLATE\' + laFiles(m.lnFile, 1))
    lcText = ReplacePlaceholders_Once(m.lcText)
    STRTOFILE(m.lcText, '.github\ISSUE_TEMPLATE\' + LOWER(laFiles(m.lnFile, 1)))

   ENDFOR &&lnFile

  ENDIF &&not directory(m.tcCurrFolder + '.github')

  IF NOT DIRECTORY(m.tcCurrFolder + 'docs') THEN
   MKDIR docs
   COPY FILE (m.tcVFPXDeploymentFolder + 'VFPXTemplate\docs\*.*') TO ;
    docs\*.*

   FOR lnFile = 1 TO ADIR(laFiles,'docs\*.*')
    lcText = FILETOSTR('docs\' + laFiles(m.lnFile, 1))
    lcText = ReplacePlaceholders_Once(m.lcText)
    STRTOFILE(m.lcText, 'docs\' + laFiles(m.lnFile, 1))

   ENDFOR &&lnFile
  ENDIF &&not directory(m.tcCurrFolder + 'docs')

  IF NOT DIRECTORY(m.tcCurrFolder + 'docs\images') THEN
   MKDIR docs\images
   COPY FILE (m.tcVFPXDeploymentFolder + 'VFPXTemplate\docs\images\*.*') TO ;
    docs\images\*.*
  ENDIF &&not directory(m.tcCurrFolder + 'docs\images')
 ENDIF


 IF FILE(m.tcSubstitudeListing) THEN
* If InstalledFiles.txt exists, copy the files listed in it to the
* InstalledFiles folder (folders are created as necessary).
  lcFiles = FILETOSTR(m.tcSubstitudeListing)
  lnFiles = ALINES(laFiles, m.lcFiles, 1 + 4)
  FOR lnI = 1 TO m.lnFiles
   lcSource = laFiles[m.lnI]
   IF LEFT(LTRIM(m.lcSource), 1) == '#' THEN
    LOOP
   ENDIF &&LEFT(LTRIM(m.lcSource), 1) == '#'
   IF RIGHT(m.lcSource, 1) == '\' THEN
* just with subfolders
    ScanDir_Templates(m.tcCurrFolder + m.lcSource)
   ELSE
* just file / skeleton
    lcText = FILETOSTR(m.tcCurrFolder + laFiles[m.lnI])
    lcText = ReplacePlaceholders_Run (m.lcText)
    STRTOFILE(m.lcText,m.tcCurrFolder + laFiles[m.lnI])
   ENDIF

  NEXT &&lnI
 ENDIF &&file(m.lcInstalledFilesListing)

ENDPROC &&SetDocumentation

PROCEDURE ReplacePlaceholders_Once
 LPARAMETERS;
  tcText

 LOCAL;
  lcRemove AS STRING,;
  lcText AS STRING,;
  lnI   AS NUMBER

 tcText = STRTRAN(m.tcText, '{APPNAME}',     m.pcAppName,    -1, -1, 1)
 tcText = STRTRAN(m.tcText, '{APPID}',       m.pcAppID,      -1, -1, 1)
 lcText = STRTRAN(m.tcText, '{CURRDATE}',    m.pcThisDate,   -1, -1, 1)
 tcText = STRTRAN(m.tcText, '{VERSIONDATE}', m.pcDate,       -1, -1, 1)
 tcText = STRTRAN(m.tcText, '{CVERSIONDATE}',m.pcVersionDate,-1, -1, 1)
 tcText = STRTRAN(m.tcText, '{VERSION}',     m.pcVersion,    -1, -1, 1)
 tcText = STRTRAN(m.tcText, '{JULIAN}',      m.pcJulian,     -1, -1, 1)
 tcText = STRTRAN(m.tcText, '{REPOSITORY}',  m.pcRepository, -1, -1, 1)
 tcText = STRTRAN(m.tcText, '{CHANGELOG_F}', m.pcChangeLog, -1, -1, 1)
 tcText = TEXTMERGE(m.tcText)

 FOR lnI = OCCURS('@@@', m.tcText) TO 1 STEP -1
  lcRemove = STREXTRACT(m.tcText, '@@@', '\\\', m.lnI, 4)
  tcText   = STRTRAN(m.tcText, m.lcRemove)

 NEXT &&lnI

 RETURN m.tcText
ENDPROC &&ReplacePlaceholders_Once

PROCEDURE ReplacePlaceholders_Run
 LPARAMETERS;
  tcText

 LOCAL;
  lnLen    AS NUMBER,;
  lnOccurence AS NUMBER,;
  lnStart  AS NUMBER

 FOR lnOccurence = 1 TO OCCURS('<!--VERNO-->', UPPER(m.tcText))
  lnStart = ATC('<!--VerNo-->', m.tcText, m.lnOccurence)
  lnLen   = ATC('<!--/VerNo-->', SUBSTR(m.tcText,m.lnStart))
*	 tcText  = stuff(tcText, lnStart, lnLen, '<!--VerNo-->' + pcFullVersion)
  IF m.lnLen>0 THEN
   tcText  = STUFF(m.tcText, m.lnStart, m.lnLen - 1, '<!--VERNO-->' + pcFullVersion)

  ENDIF &&m.lnLen>0
 NEXT &&lnOccurence

 FOR lnOccurence = 1 TO OCCURS('<!--DEPLOYMENTDATE-->', UPPER(m.tcText))
  lnStart = ATC('<!--DeploymentDate-->', m.tcText, m.lnOccurence)
  lnLen   = ATC('<!--/DeploymentDate-->', SUBSTR(m.tcText,m.lnStart))
*	 tcText  = stuff(tcText, lnStart, lnLen, '<!--DeploymentDate-->' + tcVersionDateD)
  IF m.lnLen>0 THEN
   tcText  = STUFF(m.tcText, m.lnStart, m.lnLen - 1, '<!--DeploymentDate-->' + pcVersionDate)

  ENDIF &&m.lnLen>0
 NEXT &&lnOccurence

 RETURN m.tcText
ENDPROC &&ReplacePlaceholders_Run

PROCEDURE CheckVersionFile
 LPARAMETERS;
  tcVersionFile

 LOCAL;
  lcErrorMsg AS STRING,;
  llSuccess AS BOOLEAN,;
  loException AS OBJECT,;
  loUpdater AS OBJECT

 loUpdater  = EXECSCRIPT (_SCREEN.cThorDispatcher, 'Thor_Proc_GetUpdaterObject2')
 TRY
   DO (m.tcVersionFile) WITH m.loUpdater
   llSuccess = .T.
  CATCH TO m.loException
   llSuccess = .F.
 ENDTRY

 IF !m.llSuccess THEN
  lcErrorMsg = 'Error in Version file:' 		+ CRLF + 			;
   'Msg:   ' + m.loException.MESSAGE 		+ CRLF +			;
   'Code:  ' + m.loException.LINECONTENTS
  MESSAGEBOX(m.lcErrorMsg + CRLF +  CRLF + 'ABORTING', 16, 'VFPX Project Deployment')
 ENDIF &&!m.llSuccess

 RETURN m.llSuccess

ENDPROC &&CheckVersionFile

PROCEDURE ScanDir_Templates
 LPARAMETERS;
  tcSource

 LOCAL;
  lcOldDir,;
  lcText,;
  lnLoop1

 LOCAL ARRAY;
  laDir(1)

 lcOldDir = FULLPATH("", "")
 CD (m.tcSource)
 FOR lnLoop1 = 1 TO ADIR(m.laDir, '', 'D')
  IF INLIST(laDir(m.lnLoop1, 1), '.', '..') THEN
   LOOP
  ENDIF &&INLIST(laDir(m.lnLoop1,1), '.', '..')

  ScanDir_ScanDir_Templates(ADDBS(m.tcSource + laDir(m.lnLoop1, 1)))
 ENDFOR &&lnLoop1

 FOR lnLoop1  = 1 TO ADIR(laFiles, m.tcSource + '*.*', '', 1)
  lcText = FILETOSTR(m.tcSource + laFiles[m.lnI])
  lcText = ReplacePlaceholders_Run (m.lcText)
  STRTOFILE(m.lcText,m.tcSource + laFiles[m.lnI])
 ENDFOR &&lnLoop1

 CD (m.lcOldDir)

ENDPROC &&ScanDir_Templates

PROCEDURE ScanDir_InstFiles
 LPARAMETERS;
  tcSourceDir,;
  tcTargetDir

 LOCAL;
  lcOldDir,;
  lnLoop1

 LOCAL ARRAY;
  laDir(1)

 lcOldDir = FULLPATH("", "")
 CD (m.tcSourceDir)
 FOR lnLoop1 = 1 TO ADIR(m.laDir, '', 'D')
  IF INLIST(laDir(m.lnLoop1, 1), '.', '..') THEN
   LOOP
  ENDIF &&INLIST(laDir(m.lnLoop1,1), '.', '..')
  ScanDir_InstFiles(ADDBS(m.tcSourceDir + laDir(m.lnLoop1, 1)), ADDBS(m.tcTargetDir + laDir(m.lnLoop1, 1)))

 ENDFOR &&lnLoop1
 Copy_InstallFile(ADDBS(m.tcSourceDir) + '*.*', ADDBS(m.tcTargetDir) + '*.*')
 CD (m.lcOldDir)

ENDPROC &&ScanDir_InstFiles

PROCEDURE Copy_InstallFile
 LPARAMETERS;
  tcSource,;
  tcTarget

 LOCAL;
  lcFolder

 LOCAL ARRAY;
  laDir(1)

 lcFolder = JUSTPATH(m.tcTarget)
 IF NOT DIRECTORY(m.lcFolder) THEN
  MD (m.lcFolder)
 ENDIF &&not directory(m.tcFolder)

 IF !EMPTY(ADIR(m.laDir, m.tcSource)) THEN
  COPY FILE (m.tcSource) TO (m.tcTarget)
 ENDIF &&!empty(ADIR(m.laDir, m.tcSource))

ENDPROC &&Copy_InstallFile

PROCEDURE ReleaseThis
 RELEASE;
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

ENDPROC &&ReleaseThis
