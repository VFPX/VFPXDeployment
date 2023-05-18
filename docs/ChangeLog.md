# Release History
![VFPX Deployment logo](./Images/vfpxdeployment.png "VFPX Deployment")

## 2023-05-18 Version 1.1.08538

- Added support for VFPX community documentation (option)
  - create .gitattributes to fix issues with git
  - create .gitignore template
  - create document templates for user project
  - automatic substitution for release date and version in README.md
  - automatic substitution for release date and version for a user defined list of files
  - .gitignore for BuildProcess and ThorUpdater folder, to allow simple git add . on whole project
- Updated search for home folder, using git info
- Updated search for home folder, using active project
- Added flag to disable FoxBin2Prg
- Added flag to disable git
- Option to use projects Version number as version
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
Last changed: <!--DeploymentDate-->2023-05-18<!--/DeploymentDate-->

![VFPX Deployment logo](./Images/vfpxpoweredby_alternative.gif "powered by VFPX")
