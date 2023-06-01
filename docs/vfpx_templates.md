# VFPX Templates in VFPX Deployment
![VFPX Deployment logo](./Images/vfpxdeployment.png "VFPX Deployment")
## Version  1.2.08541

There is a common way to give documentation to projects that are published for common use. A brief idea how to give your project a standard look is discussed in [BestPractice.md](./BestPractice.md).

[Anatomy of a VFPX Project](https://doughennig.blogspot.com/2023/05/anatomy-of-vfpx-project.html)  by Doug Hennig gives a good insight from a VFP POV.

This document gives in introduction to the templates used by VFPX Deployment to create a VFPX community standard to your project.

## Table of contents
- [Using this document](#using-this-document)
- [Prerequisites](#prerequisites)
- [Overview](#overview)
- [Files](#files)
- [Processing](#processing)

## Using this document
- Target paths are relative to your projects root folder. This is the toplevel folder of the local git repository you can get invoking `git rev-parse --show-toplevel`.
- Source paths are relative to *Source\Apps\VFPXDeployment\VFPXTemplate* folder of this project
or the the `"Thor\Thor\Tools\Apps\VFPXDeployment\VFPXTemplate"` local subdirectory in your Thor folder. <u>Sourcefolders</u> are highlighted with underline.


## Overview
This templates will only be used if the *Inculde_VFPX* in your projects *BuildProcess\\ProjectSettings.txt* file is set to Yes.
Any run of VFPX Deployment after this is turned on will check for the targets and merge missing stuff to your project.   
The templates are using substitution of placeholders, see [Documentation](./Documentation.md) for information.

Some templates may hold comments *available while not substituted* like `@@@ Comments \\\`. They will be removed after merged into the project.

## Files
| Source | Target | Use |
|----|----|----|
| \*\\README.md | <u>\*\\README.md</u> | Several templates for a <u>README.md</u> to give information about a folder.<br />Notable exclusion. There is no <u>.github\\README.md</u>. This file would be used by github as product documentation on the root of your project instead of the README.md placed there. This is a bit unusual. |
| .\\R.README.md | <u>README.md</u> | Template for a <u>README.md</u> to give information about your project.<br />This file need to be modified by you.<br />The file will be checked on every run, and substituted in a special way:<br /><ul><li>All space between *\<!--VERNO--\>* and *\<!--/VERNO--\>* will be replaced with *pcFullVersion* placeholder.</li><li>All space between *\<!--CVERSIONDATE--\>* and *\<!--/CVERSIONDATE--\>* will be replaced with *pcVersionDate* placeholder</li></ul> |
| .\\B.README.md | <u>BuildProcess\\README.md</u> | Template for a <u>README.md</u> to give information about the folder.<br />The file will be checked on every run. |
| .\\T.README.md | <u>ThorUpdater\\README.md</u> | Template for a <u>README.md</u> to give information about the folder.<br />The file will be checked on every run. |
| .\\C.gitignore | <u>.gitignore</u> | Template for a <u>.gitignore</u> file to control what files in your whole project are **excluded** to git.<br />The file will be checked on every run. |
| .\\L.gitignore | n/a | An alternative template for a <u>.gitignore</u> file to control what files in your whole project are **included** to git.<br />This is not the *normal* approach, but gives more security.<br />There is no automatic use of this file. |
| .\\B.gitignore | <u>BuildProcess\\.gitignore</u> | Template for a <u>.gitignore file</u> to control what files of the <u>BuildProcess</u> folder should be included to git.<br />The file will be checked on every run. |
| .\\T.gitignore | <u>ThorUpdater\\.gitignore</u> | Template for a .gitignore file to control what files of the <u>ThorUpdater</u> folder should be included to git.<br />The file will be checked on every run. |
| .\\R.gitattributes | <u>.gitattributes</u> | Template for a <u>gitattributes.md</u> to give information about your projct.<br />Depending how you install or config git, it might transform  CRLF &lt;&gt; LF on add / checkout - or not. This creates havoc if different developers set there system different. This file forces to keep CRLF - the idea is VFP, i.e. DOS, not LINUX.<br />The file will be checked on every run |
| .github\\CONTRIBUTING.md | <u>.github\\CONTRIBUTING.md</u> | Template for a <u>CONTRIBUTING.md</u> to give help the user contributing to your project. github is using this file.<br />This file need to be modified by you.<br />The file will not be checked on every run. It will only be created, if the <u>.github</u> folder is missing. |
| .github\\ISSUE_TEMPLATE\\bug_report.md | <u>.github\\ISSUE_TEMPLATE\\bug_report.md</u> | github is using this file as a template for issues - to allow your user to give most helpfull information about an issue.<br />This file need to be modified by you.<br />The file will not be checked on every run. It will only be created, if the <u>.github</u> folder is missing. |
| .github\\ISSUE_TEMPLATE\\feature_request.md | <u>.github\\ISSUE_TEMPLATE\\feature_request.md</u> | github is using this file as a template for issues - to allow your user to ask for a new feature.<br />This file need to be modified by you.<br />The file will not be checked on every run. It will only be created, if the <u>.github</u> folder is missing. |
| docs\\ChangeLog.md | <u>docs\\ChangeLog.md</u> | A list of changes to your project.ust be maintained on every new version published.<br />This file need to be modified by you.<br />The file will not be checked on every run. It will only be created, if the <u>docs</u> folder is missing. |
| docs\\documentation.md | <u>docs\\documentation.md</u> | A template to document your project.<br />This file need to be modified by you.<br />The file will not be checked on every run. It will only be created, if the <u>docs</u> folder is missing. |
| docs\\topic\[n\].md | <u>docs\\topic\[n\]</u> | Templates for subtopics to document your project.<br />This files need to be modified by you.<br />The files will not be checked on every run. They will only be created, if the <u>docs</u> folder is missing. |
| docs\\images\\\*.\* | <u>docs\\images\\\*.\*</u> | Pictures to used in the templates. The place to store pictures used in documentation.<br />The files will not be checked on every run. They will only be created, if the <u>docs</u> folder is missing. |

## Processing
The templates will be processed like
1. Get the template
2. Replace the placeholders
3. Run `Textmerge()`. This can do some processing.
See Source\Apps\VFPXDeployment\VersionTemplate.txt, procedure GetRegisterWithThor for example.
Here this controls if a code snippet will be include by setting the template comments.
4. Remove templates comments, that is anything like `@@@ Comments \\\`.

----
Last changed: 2023-05-22

![VFPX Deployment logo](./Images/vfpxpoweredby_alternative.gif "powered by VFPX")
