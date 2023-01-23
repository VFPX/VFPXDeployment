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

	lcValidFolder = Validate(Curdir())
	If Not Empty(m.lcValidFolder)
		Return m.lcValidFolder
	Endif

	Do While .T.
		lcFolder = getdir(m.lcPreviousFolder, 'Project Home Folder', 'Home Path')
		If Empty(m.lcFolder)
			Return ''
		Endif

		lcValidFolder = Validate(m.lcFolder)
		If Empty(m.lcValidFolder)
			Messagebox('Home Folder not found', 16)
		Else
			Return m.lcValidFolder
		Endif
	Enddo

Endproc


Procedure Validate(lcFolder)

	* already in the Project Home Folder?	
	Local lcHomeFolder

	If Directory(Addbs(m.lcFolder) + '.git', 1)
		Return m.lcFolder
	Endif

	Return ''

Endproc
