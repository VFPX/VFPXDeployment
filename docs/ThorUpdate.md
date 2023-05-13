# VFPX Deployment
## Version 1.0.1

These instructions describe how to use VFPX Deployment to include your project in the Thor Check for Updates (CFU) dialog so users can easily install your project and update to the latest version without having to clone your project's repository or manually download and extract a ZIP file.   
It also sets a minimum of community standards as used for VFPX and github (check if you use gitlab, it's more or less the same, except naming).

![](./Images/ThorCFUDialog.png)

See the great article [Anatomy of a VFPX Project](https://doughennig.blogspot.com/2023/05/anatomy-of-vfpx-project.html) by Doug Hennig.
It shows the setup of *VFPX related data* and *Thor* in two chapters.
This version of VFPX Deployment combines both to one tool, but the principles remain. (Remember, set up **.github\\CONTRIBUTING.md**)

----
## Table of contents
- [Using this document](#using-this-document)
- [Overview](#overview)
- [Setup Guide](#setup-guide)
- [Configuration](#Configuration)
  - [Folder](#folder)
    - [BuildProcess](#buildprocess)
    - [InstalledFiles](#installedfiles)
    - [ThorUpdater](#thorupdater)
    - [.github](#github)
    - [docs](#docs)
    - [images](#images)
    - [Root folder](#root-folder)
  - [Settings](#settings)
  - [Public variables](#public-variables)
- [Setting up the build process](#setting-up-the-build-process)
  - [VFPX Deployment process](#vfpx-deployment-process)
  - [Download the VFPX Deployment tool](#download-the-4-deployment-tool)
  - [Customize the project settings for your project](#customize-the-project-settings-for-your-project)
  - [Specify what files are to install on the target computer](#specify-what-files-are-to-install-on-the-target-computer)
  - [Customize the version template](#customize-the-version-template)
  - [Customize the build tasks](#customize-the-build-tasks)
    - [BuildMe](#buildme)
    - [AfterBuild](#afterbuild)
- [Running the build process](#running-the-build-process)
- [First time task](#first-time-task)
- [Checking for updates](#checking-for-updates)

## Using this document
- Paths are relative to the project root folder. This is the toplevel folder of the local git repository you can get invoking `git rev-parse --show-toplevel`.
- Strings like {This} must be replaced with the value of the entry from the [Settings](#settings) file.
Example:  
Settings contains `AppID = VFPXDeployment`, then *Thor_Update_{AppID}.prg* is Thor_Update_VFPXDeployment.prg
- Strings like \[This\] must be replaced with a user set value.

## Overview

To make it easier to create the files necessary to support Thor CFU, an automated build process is used. The main component of this process is Thor_Tools_DeployVFPXProject.prg, a generic program that works with any project. After doing the necessary set up (discussed in the next section), you'll run Thor_Tools_DeployVFPXProject.prg whenever you release a new version of your project.

In addition to whatever subdirectories your project root folder contains, it will also contain BuildProcess, InstalledFiles, and ThorUpdater subdirectories.

## Setup Guide
This is the step-by-step guide to set up your VFPX / Thor project. Some information is identicall to [VFPX Deployment process](#vfpx-deployment-process).

See [Setting up the build process](#setting-up-the-build-process)

1. Install Thor
2. Download [VFPX Deployment](#download-the-4-deployment-tool) from Thors *Check for Update* (CFU)
3. If not allready done, create a **remote** git repository for your project, for example at github. See [VFPX Add a Project](https://vfpx.github.io/newproject/)
4. If not allready done, create a **local** git repository for your project root folder. Just init, do not add files.
   - or clone the remote, that's up to your choice and level of git knowlodge.
5. Open your pjx or  CD into your project (anywhere) or simple
6. Run *VFPX Project Deployment* from Thor/Applications menu
  - The program tries to figure out your project root from information provided by git in the following order:
    1. The recent path in VFP
    2. Home of `_VFP.ACTIVEPROJECT` if there is one (user will be prompted to use it, if found)
    3. User prompt for folder
7. If the folder [BuildProcess](#buildprocess) exists, proceed to step 10, else it's a first run. VFPX Deployment copies some files into that folder and quits
8. Now you need to set your basic project information in [BuildProcess\\ProjectSettings.txt](#settings)
   - AppName - Mandatory
   - AppID - Mandatory
   - Version - Mandatory
   - Component - Mandatory
   - Repository - Mandatory if remote repository is not a github.com/VFPX/{AppID}
   - others, see [ProjectSettings](#settings)
9. Rerun 
10. The [ProjectSettings](#settings) will be read
11. Additional processing and tests run
12. Now the program checks creates several [Folders and files](#folder).
If something is missing, the file or folder is created, and some information like {AppName} name is substituted.
14. To run VFPX Deployment for production, one need to set up some information, documentation etc.
What to do should be noted step by step into **.github\\CONTRIBUTING.md** so everybody know what to do.

## Configuration
### Folder
#### BuildProcess
BuildProcess contains the files for the build process:

- [ProjectSettings.txt:](#settings) contains project settings, such as project name and version number.
- VersionTemplate.txt: contains the template for the Thor CFU version file. Although it has a TXT extension, it actually contains VFP code.
- [BuildMe.prg:](#buildme) contains custom code you write to do whatever is necessary for the build process. It can use public variables created by VFPX Deployment (discussed later). This program is optional.
- [AfterBuild.prg:](#afterbuild) contains custom code you write to do whatever is necessary after the build process. It can use public variables created by VFPX Deployment (discussed later). This program is optional.
- Thor_Update_{AppID}.prg (where *AppID* is the value of the AppID setting in ProjectSettings.txt): the Thor CFU update program, which contains the URLs for Thor to use to download the version and ZIP files to install the tool. This file is created the [first time](#first-time-task) you use the VFPX Deployment process and then not updated again after that.
- InstalledFiles.txt: contain the paths for the files to be installed by Thor CFU. This file is optional.
- Thor_Update_{AppID}.prg: The control to control the updateprocess in Thor

#### InstalledFiles
InstalledFiles: this is a staging folder that contains only the files Thor CFU should install, not other files related to your project (such as git-related files, README.md, etc.). There are two options for copying the necessary files into this folder:

- If InstalledFiles.txt exists in the BuildProcess folder, VFPX Deployment copies the files listed in it to the InstalledFiles folder (creating that folder and any subdirectories of it if they don't exist).
- You can manually create the InstalledFiles folder and copy the necessary files into it.

> Note: you can specify a different folder name using the InstalledFilesFolder setting in ProjectSettings.txt.

#### ThorUpdater
ThorUpdater: this contains the Thor CFU files generated by the build process (VFPX Deployment creates this folder if necessary):

- {AppID}.zip (*AppID* is the AppID value specified in ProjectSettings.txt): the zip file downloaded by Thor CFU to install the project. This file is created by VFPX Deployment by zipping the contents of the InstalledFiles folder.
- {AppID}Version.txt: the Thor version file downloaded by Thor CFU to decide if a newer version is available (it compares the version number specified in this file with the version number in the copy of the file on your system) and also to contain other information such as the text displayed for the selected project at the bottom of the Thor CFU dialog.

#### .github
Folder to store some files to interact with github.

Those files should be changed to the need of the project
- *CONTRIBUTING.md* A file telling how to participate on the project, and what befor running this programm.
- *ISSUE_TEMPLATE/\*.md* Templates to create issues

#### docs
Folder to store documentation.

Those files should be changed to the need of the project
- *documentation.md* Anchor for documentation, target of links from other documents.
- *ChangeLog.md* File to list your changes, might be substituted into {AppID}Version.txt if set as ChangeLog setting.
- *topic1.md*,*topic2.md* Example files.

#### images
Folder to store images for documention etc.
- Picture used in some templates and README.md

#### Root folder
This is the project root. Some files will pe copied on first run, if they are not existing.
- *README.md*: Basic information about your project, the main information on git server pages.
  - Fit to your needs
  - The second run on your system use [ProjectSettings.txt:](#settings) to set the project with the value of AppName
  - The second run on your system use [ProjectSettings.txt:](#settings) to set the project with the value of AppName
  - All following runs will merge the values of pdVersionDate and pcVersionDate into this file. There are comments as place holder.
- *.gitignore*: File to control what to exclude from git, for example executables and backups.
  - There are two ways to do this, this is the conventional *exclude* one.
  - If you like the more secure *include* way, you need to copy the *[L.gitignore](..\InstalledFiles\Apps\VFPXDeployment\VFPXTemplate\L.gitignore)* file. The idea here is to only include what you are sure of, so private keys will not be included by accident.
  - Fit to your needs
  - The second run on your system use [ProjectSettings.txt:](#settings) to mark this file as belonging to AppName
- *.gitattributes*: Depending how you install or config git, it might transform  CRLF &lt;&gt; LF on add / checkout - or not. This creates havoc if different developers set there system different. This file forces to keep CRLF - the idea is VFP, i.e. DOS, not LINUX.
  - There is no need to alter this file
  - The second run on your system use [ProjectSettings.txt:](#settings) to mark this file as belonging to AppName

### Settings
| Setting | Usage |
| ------ | ------ |
| **AppName** | the display name for the project. |
| **AppID** | similar to appName but must be URL-friendly (no spaces or other illegal URL characters). |
| **Version** | the version number, such as 1.0 (optional; see below).<br />There is a special value *pjx*. If this is set, the version number will be read from the project provided by PJXFile. |
| | Most will like to set up there own repository |
| **Repository** | when VFPX Deployment generates Thor_Update_{AppID}.prg, it assumes the project repository is github.com/VFPX/{AppID}. If your project exists in a different location (for example, github.com/\[YourName\]/{AppID}), add a <br /> Repository setting with the full URL, such as ```https://github.com/DougHennig/SFMail```.   
| | You can also add the following optional settings if you wish |
| **VersionDate** | the release date formatted as YYYY-MM-DD; if omitted, today's date is used. |
| **Prompt** | Yes to prompt for Version if it isn't specified; No to not prompt. Not required if Version is specified. If Version isn't specified, your code in BuildMe.prg can set the public pcVersion variable (for example, by reading a value from an INI or include file), so set Prompt to No in that case. If Version isn't specified, Prompt is No, and your code doesn't set pcVersion, a warning message is displayed and the build process terminates. |
| **ChangeLog** | the path for a file containing changes (see below). |
| **Component** | "Yes" for Components (Default), else "No" for Apps.<ul><li>Apps create Thor tools for use in your IDE (e.g., GoFish, PEMEditor).</li><li>Components are not called directly from Thor tools but are used indirectly in either your IDE (FoxBin2PRG) or in production applications (Dynamic Forms)</li></ul> |
| **Category** | the category to use when adding to the Thor menu. If this is omitted, "Applications" is used. This is only used when Component is No. |
| **PJXFile** | the relative path to the PJX file to build an APP or EXE from. Omit this if that isn't required.<br />The version number of this project can be auto-used, see Version setting.  |
| **Recompile** | by default, VFPX Deployment builds the project specified in PJXFile without the RECOMPILE clause. Add _Recompile = Yes_ to force recompilation upon building. |
| **AppFile** | the path to the APP or EXE to build from the project (specified with the extension; for example, MyApp.app builds an APP and MyApp.exe builds an EXE). If PJXFile is specified and AppFile is omitted, VFPX Deployment automatically builds an APP file in the same folder and with the same file name as the PJX file specified in the PJXFile setting.<br />  > If ProjectSettings.txt specifies that an APP or EXE is part of the VFPX project, VFPX Deployment ensures it's built using VFP 9 and not VFP Advanced because the APP/EXE structure is different. While VFP Advanced can run APP/EXEs created in VFP 9, VFP 9 cannot run APP/EXEs created in VFP Advanced. |
| **Bin2PRGFolder** | a comma-separated list of relative paths to which [FoxBin2PRG](https://github.com/fdbozzo/foxbin2prg) is to be applied. If this is specified, FoxBin2PRG is run on all VFP binary files (SCX, VCX, PJX, etc.) in the specified folders to create their text equivalents. This is important because Git cannot do diffs on binary files. Also git is bad on binaries, it's made for text files.<br />  > FoxBin2PRG: is automatically run on the project file specified in the PJXFile setting. If PJXFile is specified and the only files that need to have FoxBin2PRG run on them are included in the project, you can omit the Bin2PRGFolder setting. The use of FoxBin2Prg can be turned off. |
| **InstalledFilesFolder** | by default, the staging folder VFPX Deployment uses to generate the ZIP file from is called InstalledFiles. This setting allows you to specify a different name. |
| **RunBin2Prg** | "Yes" to auto run FoxBin2prg (Default), else "No" to not run. |
| **RunGit** | "Yes" to auto run git (Default), else "No" to not run. |


### Public variables
| Variable | Usage |
| ------ | ------ |
| **pcAppName**: | the AppName setting |
| **pcAppID** | the AppID setting |
| **pcVersion** | the version number (the Version setting but can also be set in code; see the next section) |
| **pdVersionDate** | the release date (the VersionDate setting or the current date if not specified) |
| **pcVersionDate** | the release date as a string (YYYY-MM-DD) |
| **pcChangeLog** | the ChangeLog setting |
| **plContinue** | .T. to continue the deployment process or .F. to stop |
| **plRun_Bin2Prg** | .T. to auto run FoxBin2prg (default) |
| **plRun_git** | .T. to auto run git (default) |
| **pcFullVersion** | The version as it should look like to replace in README.md on each run. Default: pcVersion |   

### VFPX Deployment process
The VFPX Deployment process does the following:

- Creates the BuildProcess subdirectory of the project root folder and copies the files listed above to it.
- Reads the settings in [ProjectSettings.txt](#settings) into the following public variables so BuildMe.prg can read from or write to them if necessary:   

This is he step-by-step walk through the Deplyoment process. Some information is identicall to [Setup Guide](#setup-guide).

If you run VFPX Deployment for production, you need to set information, documentation etc.
What to do you should note step by step into **.github\\CONTRIBUTING.md** so everybody know what to do.

1. Run *VFPX Project Deployment* from Thor/Applications menu
  - The program tries to figure out your project root folder from information provided by git in the following order:
    1. The recent path in VFP
    2. Home of `_VFP.ACTIVEPROJECT` if there is one (user will be prompted to use it, if found)
    3. User prompt for folder
2. If the folder [BuildProcess](#buildprocess) exists, proceed to step 5, else it's a first run. VFPX Deployment copies some files into that folder and quits
3. Now you need to set your basic project information in [BuildProcess\\ProjectSettings.txt](#settings)
   - AppName - Mandatory
   - AppID - Mandatory
   - Version - Mandatory
   - Component - Mandatory
   - Repository - Mandatory if remote repository is not a github.com/VFPX/{AppID}
   - others, see [ProjectSettings](#settings)
4. Rerun 
5. The [ProjectSettings](#settings) will be read
6. Additional processing and tests run
7. If no Versionnumber could be determined, the user will be prompted.
8. If found, [BuildProcess\\BuildMe.prg](#buildme) runs user defined code to pre-process and gather other information to the [Public variables](public-variables). Some ideas are provided in the file.
9. Now the program checks for the existence of several [Folders and files](#folder).
If something is missing, the file or folder is created, and some information like {AppName} name is substituted.
10. If enabled, run [FoxBinb2Prg](https://github.com/fdbozzo/foxbin2prg)
11. If a pjx (*PJXFILE*)is provided, compile the PJX, depending on *APPFILE*
12. If a [ InstalledFiles.txt](#specify-what-files-are-installed) file is provided
    - copy all files listed to [InstalledFiles](#installedfiles), or
    - use the files in it (must be provided before run)
13. Check for [ThorUpdater](#thorupdater) folder and create if missing.
14. Create Thor files
    - {AppID}Version.txt from BuildProcess\\VersionTemplate.txt
    - Zips the contents of the InstalledFiles folder into {AppID}.zip in the ThorUpdater folder.
15. If enabled, run git
16. If found, [BuildProcess\\AfterBuild.prg](#afterbuild) runs user defined code to post-process. Some ideas are provided in the file.

## Setting up the build process

This looks like a lot of steps but most of it is simple and you only have to do it once.   
See [Setup Guide](#setup-guide).

### Download the VFPX Deployment tool

- Choose Check for Updates from the Thor menu and install VFPX Deployment. It's automatically added to the Thor Tools menu under Applications, VFPX Project Deployment.

### Customize the project settings for your project
Start VFP, CD to the folder containing your project, and invoke the VFPX Deployment tool (from the Thor Tools, Application, VFPX Project Deployment menu item or using ```EXECSCRIPT(_screen.cThorDispatcher, 'Thor_Tool_DeployVFPXProject')```. The first time you do that, it'll create a BuildProcess subdirectory of the project root folder, copy some files to it, and terminate.

Edit *BuildProcess\\ProjectSettings.txt* to specify your project information (the case of these settings is unimportant):

![](./Images/ProjectSettings.png)

See [Settings](#settings) for details.

### Specify what files are to install on the target computer

Edit InstalledFiles.txt and list each file to be copied to the InstalledFiles folder on a separate line. All paths should be relative to the project root folder.

![](./Images/InstalledFiles.png)

### Customize the version template
This is an optional task.

VersionTemplate.txt already has the code most projects would use. However, you may wish to edit it to customize the behavior; see comments in the provided file for possible customization points. Also note the use of @@@ and \\\\\\\: text between those delimiters is for you to read but is removed in the {AppID}Version.txt file that's generated from the template.

The code in this file must accept a single parameter, which is a Thor CFU updater object. The code typically sets properties of that object to do whatever is necessary.

The template file should have placeholders for project settings (the case of the placeholder isn't important):

| Placeholder | Usage |
| ------ | ------ |
| **{APPNAME}** | substituted with the value of *pcAppName*. |
| **{APPID}** | substituted with the value of *pcAppID*. |
| **{VERSIONDATE}** | substituted with the value of *pdVersionDate* formatted as YYYYMMDD. |
| **{CVERSIONDATE}** | substituted with the value of *pdVersionDate* formatted as YYYY-MM-DD. |
| **{VERSION}** | substituted with the value of *pcVersion*. |
| **{JULIAN}** | substituted with the value of *pdVersionDate* as a numeric value: the Julian date since 2000-01-01. If you wish, you can use that as a minor version number (see the example below). |
| **{CHANGELOG}** | substituted with the contents of the file specified in *pcChangeLog*. |
| **{COMPONENT}** | substituted with the value of the *Component* setting in ProjectSettings.txt. |
| **{CATEGORY}** | substituted with the value of the *Category* setting in ProjectSettings.txt. |

The format of AvailableVersion in VersionTemplate.txt&mdash;the project name, a dash, the version number, a dash, some text, a dash, and the release date formatted as YYYYMMDD&mdash;is required by Thor (Thor actually only uses the version number and release date and ignores the rest).

See comments in VersionTemplate.txt about how to use different types of version numbers.

### Customize the build tasks
This is an optional task.

#### BuildMe
If you need to perform specific tasks as part of the build process, such as updating version numbers in code or include files, edit BuildMe.prg to perform those tasks. It can use the [Public variables](#public-variables) created by VFPX Deployment (discussed earlier). If the Version setting isn't specified in ProjectSettings.txt and the prompt setting is N, set the pcVersion variable to the appropriate value.

If no specific tasks are needed beyond what the VFPX Deployment process does, you can delete BuildMe.prg.

#### AfterBuild
If you need to perform specific tasks after the build process, such as running your own idea of git, like add ., tag, push, etc, edit AfterBuild.prg to perform those tasks. It can use the public variables created by VFPX Deployment (discussed earlier). 

If no specific tasks are needed beyond what the VFPX Deployment process does, you can delete AfterBuild.prg.

## Running the build process

After doing all of the tasks in the previous section, you're ready to create the files Thor needs to download and install or update your project. This is the normal deployment process you'll use each time there's a new release for your project:

1. Make whatever changes to your project files are necessary.
2. Update [ProjectSettings.txt:](#settings) with a new version number if necessary. For example, if you use the Version setting as the version number, increment it. If you use Version as the major version number and the Julian date as a minor version number, and this is just a minor release (e.g. going from 3.2.1234 to 3.2.1245), you don't need to change Version at all.
3. If you've specified the ChangeLog setting in ProjectSettings.txt, update the specified file to describe the changes.
4. Start VFP 9 (not VFP Advanced) and CD into the project or make the pjx the active one.
5. Invoke the VFPX Deployment tool from the Thor Tools, Application, VFPX Project Deployment menu item or using ```EXECSCRIPT(_screen.cThorDispatcher, 'Thor_Tool_DeployVFPXProject')```.
6. Commit and push to the remote repository.

The steps required for a project should be found in **.github\\CONTRIBUTING.md** so everybody know what to do.

### First time task

In order for Thor to know about your project, it needs a Thor updater program named Thor_Update_{AppID}.prg. The build process creates that PRG in the BuildProcess folder and then doesn't update it again after that.

You can test that the updater PRG works by copying it to Thor\Tools\Updates\My Updates under your Thor installation folder. Then choose Check for Updates from the Thor menu. The tool should appear in the CFU dialog in italics, and installing it should work.

Once you confirm the update process works, zip Thor_Update_{AppID}.prg and email it to the VFPX administrators (<a href="mailto:projects@vfpx.org">projects@vfpx.org</a>). They'll add it to the Thor repository so Thor knows about your project.

> Note to admins: see [How to contribute to Thor](https://github.com/VFPX/Thor/blob/master/.github/CONTRIBUTING.md) for instructions to handle the new Thor_Update_{AppID}.prg.

### Checking for updates

Now that Thor knows about your project, the next time a user chooses Check for Updates from the Thor menu in VFP, Thor will download {AppID}Version.txt from the ThorUpdater folder of your repository, see that the project is available to be installed or a new version is ready for download, and display it to the user in the update dialog.

If the user chooses to install the project or the update, Thor downloads {AppID}.zip from the ThorUpdater folder of your repository and unzips it in the appropriate folder on your machine (the {AppName} subdirectory of either the Thor\Tools\Apps or Thor\Tools\Components, depending on the Component setting in ProjectSettings.txt, subdirectory of the main Thor folder) and creates {AppID}VersionFile.txt in that folder so it knows what version the user has so they aren't prompted about an update until the next release.

----
Last changed: 2023-05-13

![](..\InstalledFiles\Apps\VFPXDeployment\VFPXTemplate\images\vfpxpoweredby_alternative.gif)
