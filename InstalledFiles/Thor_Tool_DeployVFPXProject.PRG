Lparameters lxParam1

****************************************************************
****************************************************************
* Standard prefix for all tools for Thor, allowing this tool to
*   tell Thor about itself.

If Pcount() = 1								;
		And 'O' = Vartype (m.lxParam1)		;
		And 'thorinfo' == Lower (m.lxParam1.Class)

	With m.lxParam1

		* Required
		.Prompt		   = 'VFPX Project Deployment' && used in menus

		Text To .Description Noshow
Deploy VFPX Project
		Endtext
		.Category = 'Applications'
		.Link     = 'https://github.com/VFPX/VFPXDeployment/blob/main/README.md'
		.Author	  = 'JRN'
	Endwith

	Return m.lxParam1
Endif

If Pcount() = 0
	Do ToolCode
Else
	Do ToolCode With m.lxParam1
Endif

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
	Lparameters lxParam1

	Local lcPreviousFolder, lcProjectFolder, lcStartFolder

	lcStartFolder = Curdir()

	* ================================================================================ 
	lcPreviousFolder = Nvl(Execscript(_Screen.cThorDispatcher, 'Get Option=', ccKey, ccTool), '')

	lcProjectFolder	 = GetProjectFolder(m.lcPreviousFolder)

	If Directory(m.lcProjectFolder)

		Execscript(_Screen.cThorDispatcher, 'Set Option=', ccKey, ccTool, m.lcProjectFolder)

		Execscript(_Screen.cThorDispatcher, 'Thor_Proc_DeployVFPXProject', m.lcProjectFolder)
	Endif
	* ================================================================================ 

	Cd (m.lcStartFolder)

Endproc


Procedure GetProjectFolder(lcPreviousFolder)

	Local lcFolder, lcValidFolder

* try if active folder is in a git repository
	lcValidFolder = Validate(Curdir())
	If Not Empty(m.lcValidFolder)
		Return m.lcValidFolder
	Endif

* SF 20230512, try active project next
*in case we have a structure where we sit in a base with many scatterd projects
*we try if the Active Project is the one
	if TYPE("_VFP.ActiveProject")='O'
		if messagebox('Run for active project' + chr(13) + chr(10) + chr(13) + chr(10) + '"';
				_VFP.ActiveProject.Name + '" ?', 36, 'VFPX Project Deployment')=6
			lcValidFolder = justpath(_VFP.ActiveProject.Name)
			If Not Empty(m.lcValidFolder)
				Return m.lcValidFolder
			Endif
		endif
	endif
	
*try to get a folder
	Do While .T.
		lcFolder = getdir(m.lcPreviousFolder, 'Project Home Folder', 'Home Path')
		If Empty(m.lcFolder)
			Return ''
		Endif

		lcValidFolder = Validate(m.lcFolder)
		If Empty(m.lcValidFolder)
			Messagebox('Home Folder not found, not a git repository.', 16, 'VFPX Project Deployment')
		Else
			Return m.lcValidFolder
		Endif
	Enddo

Endproc


Procedure Validate(lcFolder)
* SF 20230512
*we test if this folder is a git folder and return the git base folder
*no need to search the base folder, git will tell this
* (and not embarrassingly testing for ".git" folder)
	Local lcOldFolder, lcCommand

	lcOldFolder = FULLPATH('','')
	CD (m.lcFolder)
	delete file git_x.tmp	&& in case

*if git is not installed, we get an empty or no file
	lcCommand = 'git rev-parse --show-toplevel>git_x.tmp'
	run &lcCommand

	If file('git_x.tmp')
*the result is either the git base folder or empty for no git repo
		lcFolder = chrtran(filetostr('git_x.tmp'), '/' + chr(13) + chr(10), '\')
		delete file git_x.tmp
	else
* no file, no git
		lcFolder = ''
	Endif

	CD (m.lcOldFolder)
	Return m.lcFolder

Endproc
