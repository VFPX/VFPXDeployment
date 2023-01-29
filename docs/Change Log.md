# Release History

## 2023-01-29 Version 1.0.08429

* Run FoxBin2PRG includes sub-folders

## 2023-01-23 Version 1.0.08423

* Restored starting directory when complete (failed previously under some conditions)

* Performs test execution of the Version file to ensure if does not fail with errors

## 2023-01-22 Version 1.0.08422

* Added support for specifying the URL for the project's repository.

* Fixed an issue with install location when Component = "Yes".

## 2023-01-21 Version 1.0.08421

* If PJXFile is specified and AppFile is omitted, VFPX Deployment automatically builds an APP file in the same folder and with the same file name as the PJX file specified in the PJXFile setting.

* FoxBin2PRG is automatically run on the project file specified in the PJXFile setting. If PJXFile is specified and the only files that need to have FoxBin2PRG run on them are included in the project, you can omit the Bin2PRGFolder setting.

* If a file named NoVFPXDeployment.txt exists, VFPX Deployment will terminate.

## 2023-01-20 Version 1.0

* Initial release