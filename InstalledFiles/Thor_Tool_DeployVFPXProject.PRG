lparameters;
 lxParam1

****************************************************************
****************************************************************
* Standard prefix for all tools for Thor, allowing this tool to
*   tell Thor about itself.

if pcount() = 1								;
		and 'O' = vartype (m.lxParam1)		;
		and 'thorinfo' == lower (m.lxParam1.class) THEN 

	with m.lxParam1   

* Required
		.prompt		   = 'VFPX Project Deployment' && used in menus

		text To .Description NOSHOW  
Deploy VFPX Project
		ENDTEXT
		
		.Category = 'Applications'
		.link     = 'https://github.com/VFPX/VFPXDeployment/blob/main/README.md'
		.Author   = 'JRN'
	endwith &&m.lxParam1

	return m.lxParam1

endif &&pcount() = 1 and 'O' = vartype (m.lxParam1) and 'thorinfo' == lower (m.lxParam1.class)

if pcount() = 0 THEN 
	do ToolCode
else &&pcount() = 0
	do ToolCode with m.lxParam1
endif &&pcount() = 0

return

#define ccTab  	chr(9)
#define ccLF	chr(10)
#define ccCR	chr(13)
#define ccCRLF	chr(13) + chr(10)

#define ccKey	'DeployVFPXProject'
#define ccTool	'HomeFolder'

****************************************************************
****************************************************************
* Normal processing for this tool begins here.
procedure ToolCode   
	lparameters;
		lxParam1

	local;
		lcPreviousFolder as string,;
		lcProjectFolder as string,;
		lcStartFolder as string

	lcStartFolder = fullpath('','')

* ================================================================================
	lcPreviousFolder = nvl(execscript(_screen.cThorDispatcher, 'Get Option=', ccKey, ccTool), '')

	lcProjectFolder	 = GetProjectFolder(m.lcPreviousFolder)

	if directory(m.lcProjectFolder) THEN 

		execscript(_screen.cThorDispatcher, 'Set Option=', ccKey, ccTool, m.lcProjectFolder)

		execscript(_screen.cThorDispatcher, 'Thor_Proc_DeployVFPXProject', m.lcProjectFolder)
	endif &&directory(m.lcProjectFolder)
* ================================================================================

	cd (m.lcStartFolder)

endproc &&ToolCode

procedure GetProjectFolder   
	lparameters;
		tcPreviousFolder
		
	local;
		lcFolder   as string,;
		lcValidFolder as string

* try if active folder is in a git repository
	lcValidFolder = validate(fullpath('',''))
	if not empty(m.lcValidFolder) THEN 
		return m.lcValidFolder
	endif &&not empty(m.lcValidFolder)

* SF 20230512, try active project next
*in case we have a structure where we sit in a base with many scatterd projects
*we try if the Active Project is the one
	if type("_VFP.ActiveProject")='O' THEN 
		if messagebox('Run for active project' + chr(13) + chr(10) + chr(13) + chr(10) + '"';
				 _vfp.activeproject.name + '" ?', 36, 'VFPX Project Deployment') = 6 THEN 
			lcValidFolder = justpath(_vfp.activeproject.name)
			if not empty(m.lcValidFolder) THEN 
				return m.lcValidFolder

			endif &&not empty(m.lcValidFolder)
		endif &&messagebox('Run for active project' + chr(13) + chr(10) + chr(13) + chr(10) + '"' _vfp.activeproject.name + ...
	endif &&type("_VFP.ActiveProject")='O'

*try to get a folder
	do while .t.   
		lcFolder = getdir(m.tcPreviousFolder, 'Project Home Folder', 'Home Path')
		if empty(m.lcFolder) THEN 
			return ''
		endif &&empty(m.lcFolder)

		lcValidFolder = validate(m.lcFolder)
		if empty(m.lcValidFolder) THEN 
			messagebox('Home Folder not found, not a git repository.', 16, 'VFPX Project Deployment')
		else &&empty(m.lcValidFolder)
			return m.lcValidFolder
		endif &&empty(m.lcValidFolder)

	enddo &&.t.

endproc &&GetProjectFolder

procedure validate   
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

	if file('git_x.tmp') THEN 
*the result is either the git base folder or empty for no git repo
		tcFolder = chrtran(filetostr('git_x.tmp'), '/' + chr(13) + chr(10), '\')
		delete file git_x.tmp
	else &&file('git_x.tmp')
* no file, no git
		tcFolder = ''
	endif &&file('git_x.tmp')

	cd (m.lcOldFolder)
	return m.tcFolder

endproc &&validate
