# Release History
![VFPX Deployment logo](./Images/vfpxdeployment.png "VFPX Deployment")

<!-- Note, the next line needs to be on top to auto generate version and date for this version,
     old version must be without the substitution marks (HTML comments),
     so please remove for second newest version-->
## <!--CVERSIONDATE-->2025-01-18<!--/CVERSIONDATE--> Version <!--VERNO-->1.7.09149<!--/VerNo-->
- Fixed a typo.

## 2025-01-18 Version 1.7.08750
- Added new settings REPOSITORY_URL and REPOSITORY_BRANCH to better control the github URLs allowing to split between *Project/Repository* and *Branch*
- Added new setting DEBUGGING to allow auto creating a debug version of the Thor_Update_* file for testing.
- Switched compiling and FoxBin2prg, so we get the latest version of the pjx.

## 2023-12-09 Version 1.6.08743
- Added help program BeforeZip.prg, to run before zip
- Run zip with APIRun
- JRN, via merge: Added ThorInfo.APPID property to both program and template

## 2023-08-09 Version 1.5.08621
- Added new public var, to deal with GoFish complex creation.
- Added new public var, to expose PJXFile (Read Only).
- Added new setting to control the creation of .gitignore file in staging folder
- Minor in file documentation changes

## 2023-07-30 Version 1.4.08611
- It now handles tabs in ProjectSettings.txt.
- It now ignores errors when textmerging the version file.
- It now strips placeholders from the version file.
- It no longer creates .gitignore in the InstalledFiles folder.

## 2023-07-08 Version 1.4.08589
- Fixed typos in documentation
- Add ALLTRIM() to folder for FoxBin2PRG to process in case there's a space in the FoxBin2PRGFolder setting in ProjectSettings.txt

## 2023-06-11 Version 1.4.08562
- Fixed an issue with ActiveProject as target

## 2023-06-07 Version 1.3.08558
- Fixed an issue with ActiveProject not in toplevel folder
- Fixed problem with autocreated .gitignore in staging folder, if no InstalledFiles.txt is given. The file must be removed manually.

## 2023-06-04 Version 1.2.08555
- Fixed problem that VFPX Deployment needs Thor running, even when Thor_Proc_DeployVFPXProject.prg is not started from Thor
  - Clarified in README.md 
- Fixed superfluous folder VFPXDeployment in zip. Please remove the folder from Thor *tools* folder.

## 2023-06-03 Version 1.2.08554

- New ability for Thor_Proc_DeployVFPXProject.prg, it might run stand alone, without Thor.
- Added switch to InstalledFiles.txt to exclude file pattern from staging area
- Messagebox to use active project will only appear if the project is stored in a git repository
- More substitutions for runtime files. See https://github.com/VFPX/VFPXDeployment/blob/main/docs/Documentation.md#file-substitution
- One incompatible change for substitutions due to generalized use. See https://github.com/VFPX/VFPXDeployment/blob/main/docs/Documentation.md#file-substitution
- Changed structure of documentation to fit to own template
- Added links to own source as example in documentation
- New option to pick a folder on startup, circumventing check for current folder and project

## 2023-05-22 Version  1.2.08542

- Fixed used of fixed typos (INCULDE_ in docu and settings file (~template) )
- Ignore empty source in InstalledFiles.txt
- Use empty target in InstalledFiles.txt as staging folder
- New option Clear_InstalledFiles to copy to empty staging folder
- A .gitignore to keep the staging folder out of the repository.   
  Note: If already in the repo, this will not remove the files!
- Moved sources of the VFPX Deployment project from "InstalledFiles" to "Source", to keep it in it's own structure (it also helps understanding the way the project works)   
  Note: If your project stores sources in the staging, "InstalledFiles", folder; move it to a better location. See .gitignore above.
  
## 2023-05-21 Version  1.2.08541

- Added support for special remote version file (VersionFile_Remote)
- Check if InstalledFiles.txt containes text
- Allow CLEAR ALL in AfterBuild.prg

## 2023-05-18 Version 1.1.08538

- Added support for VFPX community documentation (option)
  - create .gitattributes to fix issues with git
  - create .gitignore template
  - create document templates for user project
  - automatic substitution for release date and version in README.md
  - automatic substitution for release date and version for a user defined list of files
  - .gitignore for BuildProcess and ThorUpdater folder, to allow simple `git add .` on whole project
- Updated search for home folder, using git info
- Updated search for home folder, fixed wrong search for current folder
- Updated search for home folder, using active project
- Added flag to disable FoxBin2Prg
- Added flag to disable git
- Option to use projects (pjx) Version number as version
- InstalledFiles.txt may now target whole structures of subdirectories
- InstalledFiles.txt may name a target for a source
- Several new public variables to interact with
- Substitutions while creating templates
- Generalized substitution for templates and VersionTemplate.txt
- Added post-processing program AfterBuild.prg
- Clean up public variables
- FULLPATH() instead of CURDIR()
- Added logo


## 2023-04-02 Version 1.0.08492

- Added support for multiple folders to be processed by FoxBin2PRG.

## 2023-03-12 Version 1.0.08471

- The files in the BuildProcess folder are now automatically added to the repository.

## 2023-02-15 Version 1.0.08446

- Added support for InstalledFilesFolder and Recompile settings in ProjectSettings.txt.

## 2023-01-29 Version 1.0.08429

- Run FoxBin2PRG includes sub-folders.

## 2023-01-23 Version 1.0.08423

- Restored starting directory when complete (failed previously under some conditions).

- Performs test execution of the Version file to ensure if does not fail with errors.

## 2023-01-22 Version 1.0.08422

- Added support for specifying the URL for the project's repository.

- Fixed an issue with install location when Component = "Yes".

## 2023-01-21 Version 1.0.08421

- If PJXFile is specified and AppFile is omitted, VFPX Deployment automatically builds an APP file in the same folder and with the same file name as the PJX file specified in the PJXFile setting.

- FoxBin2PRG is automatically run on the project file specified in the PJXFile setting. If PJXFile is specified and the only files that need to have FoxBin2PRG run on them are included in the project, you can omit the Bin2PRGFolder setting.

- If a file named NoVFPXDeployment.txt exists, VFPX Deployment will terminate.

## 2023-01-20 Version 1.0

- Initial release

----
Last changed: <!--CVERSIONDATE-->2025-01-18<!--/CVERSIONDATE-->

![VFPX Deployment logo](./Images/vfpxpoweredby_alternative.gif "powered by VFPX")
