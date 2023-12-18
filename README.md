<!-- 
On each build, the sections framed by
"VerNo" or "CVERSIONDATE" will be replaced with recent data
-->
# VFPX Deployment
![VFPX Deployment logo](./docs/Images/vfpxdeployment.png "VFPX Deployment")

Project home: https://github.com/VFPX/VFPXDeployment

Project manager: Doug Hennig

VFPX Deployment automates the steps needed to include your project in the Thor Check for Updates (CFU) dialogue
so you can easily install your project and update to the latest version without having to clone your project's repository or manually download and extract a ZIP file.

![Thor CFU](./docs/Images/ThorCFUDialog.png "Thor CFU")

![VFPX Banner](./docs/images/vfpxbanner.gif "VFPX")   
This project is part of [VFPX](https://vfpx.github.io/).

## Documentation
See the [Documentation](./docs/Documentation.md) for details on using VFPX Deployment.

## Releases

Latest release: <!--CVERSIONDATE-->2023-12-16<!--/CVERSIONDATE-->,
Version <!--VERNO-->1.7.08750<!--/VerNo-->

See the [Release history](./docs/ChangeLog.md) for release information.

### Highlights to version 1.1.08538
- A better sophisticated way to determine projects home folder.
- Additional templates for VFPX community standards. See [VFPX Templates](./vfpx_templates.md).
- Better control of work flow

## External information
See the great article [Anatomy of a VFPX Project](https://doughennig.blogspot.com/2023/05/anatomy-of-vfpx-project.html) by Doug Hennig.
It shows the setup of *VFPX related data* and *Thor* in two chapters.   
Since version 1.1.08538 this tool merges both, but the article gives a good idea.

## Run the tool stand alone:
Download the [zip](https://github.com/VFPX/VFPXDeployment/blob/main/ThorUpdater/VFPXDeployment.zip), expand the folder and run relative to this folder `Procs\Thor_Proc_DeployVFPXProject.prg`.   
**Note:** While this is not installed *via Thor*, Thor still *needs to be running* to provide access to FoxBin2Prg and zip.

## Run this tool from Thor:
Download via Thor Check for Updates and run from Thor.

## Helping with this project

See [How to contribute to VFPX Deployment](.github/CONTRIBUTING.md) for details on how to help with this project.

Last changed: _<!--CVERSIONDATE-->2023-12-16<!--/CVERSIONDATE-->_   
![powered by VFPX](./docs/Images/vfpxpoweredby_alternative.gif "powered by VFPX")
