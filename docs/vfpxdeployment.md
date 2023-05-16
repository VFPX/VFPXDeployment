# Internals of VFPX Deployment
![](./Images/vfpxdeployment.png)
## Version 1.1.08536

This project is a bit like self referential, some code looks like to be on two places.
This document shows the usage of the folders  **in this project**.
For the use of folders in projects **using VFPX Deployment** see
[Thor Update](./ThorUpdate.md).

## Using this document
- Paths are relative to the project root folder. This is the toplevel folder of the local git repository you can get invoking `git rev-parse --show-toplevel`.

### Folder
| Folder | Use |
|----|----|
| ThorUpdater | The files used by Thor to update a users computer |
| BuildProcess | The information to create VFPX Deployment to Thor |
| .github | This folder and it's sub folder contain files to work on the VFPX Deployment on github |
| docs | This folder and it's sub folder contain for the documentation of VFPX Deployment, like this document. |
| InstalledFiles (from here: .\\) | This is the part of the project to deploy.<br />The files to will be compressed to a file in ThorUpdater folder<br />This is in special: |
| .\\ | The program to be send to the Thor administrators to publish VFPX Deployment |
| .\\Proc | The programs that will do the work if you call VFPX Deployment from Thor |
| .\\Apps | Files that will go into Thors Tools\\Apps folder. For this project mostly templates for a project managed by VFPX Deployment. |
| .\\Apps\\VFPXDeployment | Templates that will be copied to users project BuildProcess folder on the first run of VFPX Deployment.<br />The files must be modified on the project. |
| .\\Apps\\VFPXDeployment\\VFPXTemplate | This folder and it's sub folders contain templates that will be used to create some community standard documentation.<br />As soon as this feature is enabled in projects BuildProcess\\ProjectSettings.txt file, the files will be copied and some substitutions will be made to gather basic informations.<br />The files must be modified on the project. |

----
Last changed: 2023-05-16

![](./Images/vfpxpoweredby_alternative.gif)