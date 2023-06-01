Lparameters;
	lxParam1

****************************************************************
****************************************************************
* Standard prefix for all tools for Thor, allowing this tool to
*   tell Thor about itself.

If Pcount() = 1								;
		and 'O' = Vartype (m.lxParam1)		;
		and 'thorinfo' == Lower (m.lxParam1.Class) Then

	With m.lxParam1

* Required
		.Prompt		   = 'VFPX Project Deployment' && used in menus

		TEXT To .Description NOSHOW
Deploy VFPX Project
		ENDTEXT

		.Category = 'Applications'
		.Link     = 'https://github.com/VFPX/VFPXDeployment/blob/main/README.md'
		.Author   = 'JRN'
	Endwith &&m.lxParam1

	Return m.lxParam1

Endif &&pcount() = 1 and 'O' = vartype (m.lxParam1) and 'thorinfo' == lower (m.lxParam1.class)

If Pcount() = 0 Then
	Do ToolCode
Else &&pcount() = 0
	Do ToolCode With m.lxParam1
Endif &&pcount() = 0

Return

#Define ccTab  	Chr(9)
#Define ccLF	Chr(10)
#Define ccCR	Chr(13)
#Define ccCRLF	Chr(13) + Chr(10)

#Define ccKey	'DeployVFPXProject'
#Define ccTool	'HomeFolder'

****************************************************************
****************************************************************
* Normal processing for this tool begins here.
Procedure ToolCode
	Lparameters;
		lxParam1

	Local;
		lcPreviousFolder As String,;
		lcProjectFolder As String

	AddProperty(_Screen, 'VFPX_DeployStartFolder', Fullpath("", ""))

* ================================================================================
	lcProjectFolder	 = GetProjectFolder()

	If Directory(m.lcProjectFolder) Then

		Execscript(_Screen.cThorDispatcher, 'Thor_Proc_DeployVFPXProject', m.lcProjectFolder)
	Endif &&directory(m.lcProjectFolder)
* ================================================================================

	Cd (_Screen.VFPX_DeployStartFolder)
	Removeproperty(_Screen, 'VFPX_DeployStartFolder')

Endproc &&ToolCode

* ================================================================================
* ================================================================================
* Search for project to work with
* Search a pattern of folders to figure out if those folders are within a repository; if true, get toplevel folder
*
* Note: There is a similar procedure in Thor_Proc_DeployVFPXProject.prg to allow Thor independed operation
Procedure GetProjectFolder

	Local;
		lcFolder   As String,;
		lcValidFolder As String

* try if active folder is in a git repository
	lcFolder = Fullpath('','')
	lcValidFolder = ValidateTopLevel(m.lcFolder)
	If Not Empty(m.lcValidFolder) Then
		Return m.lcValidFolder
	Endif &&not empty(m.lcValidFolder)

* SF 20230512, try active project next
*in case we have a structure where we sit in a base with many scatterd projects
*we try if the Active Project is the one
	If Type("_VFP.ActiveProject")='O' Then
		lcValidFolder = Justpath(_vfp.ActiveProject.Name)
		If Not Empty(m.lcValidFolder) AND  Messagebox('Run for active project' + Chr(13) + Chr(10) + Chr(13) + Chr(10) + '"' + ;
					_vfp.ActiveProject.Name + '" ?', 36, 'VFPX Project Deployment') = 6 THEN 
			Return m.lcValidFolder

		Endif &&Not Empty(m.lcValidFolder) AND Messagebox('Run for active project' + Chr(13) + Chr(10) + Chr(13) + Chr(10) ...
	Endif &&type("_VFP.ActiveProject")='O'

*try to get a folder
	Do While .T.
		lcFolder = Getdir(m.lcFolder, 'Project Home Folder', 'Home Path')
		If Empty(m.lcFolder) Then
			Return ''
		Endif &&empty(m.lcFolder)

		lcValidFolder = ValidateTopLevel(m.lcFolder)
		If Empty(m.lcValidFolder) Then
			Messagebox('Top level folder not found, not a git repository.', 16, 'VFPX Project Deployment')
		Else &&empty(m.lcValidFolder)
			Return m.lcValidFolder
		Endif &&empty(m.lcValidFolder)

	Enddo &&.t.

Endproc &&GetProjectFolder

* ================================================================================
* ================================================================================
* Search for project to work with (used for stand alone version)
* use git to check if a given folder is in a repository; if true, return toplevel folder
*
* Note: There is a similar procedure in Thor_Proc_DeployVFPXProject.prg to allow Thor independed operation
Procedure ValidateTopLevel
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
		tcFolder = Chrtran(Filetostr('git_x.tmp'), '/' + Chr(13) + Chr(10), '\')
		Delete File git_x.tmp
	Else &&file('git_x.tmp')
* no file, no git
		tcFolder = ''
	Endif &&file('git_x.tmp')

	Cd (m.lcOldFolder)
	Return m.tcFolder

Endproc &&ValidateTopLevel
