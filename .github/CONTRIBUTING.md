# How to contribute to VFPX Deployment
![VFPX Deployment logo](../docs/Images/vfpxdeployment.png)
## Bug report?
- Please check [issues](https://github.com/VFPX/ObjectExplorer/issues) if the bug is reported
- If you're unable to find an open issue addressing the problem, open a new one. Be sure to include a title and clear description, as much relevant information as possible, and a code sample or an executable test case demonstrating the expected behaviour that is not occurring.

### Did you write a patch that fixes a bug?
- Open a new github merge request with the patch.
- Ensure the PR description clearly describes the problem and solution.
  - Include the relevant version number if applicable.
- See [New version](#new-version) for additional tasks

## New version
Here are the steps to updating to a new version:

## Fix a bug or add an enhancement

1. Create a fork at github
   - See this [guide](https://www.dataschool.io/how-to-contribute-on-github/) for setting up and using a fork
2. Make whatever changes are necessary.
   - Note: This project looks a bit circular, because it defines stuff it may use itself. See [Internals of VFPX Deployment](../docs/vfpxdeployment.md)
Most likely you must alter something in InstallFiles or it's sub folders.

---
3. For major settings, edit the Version setting in _BuildProcess\ProjectSettings.txt_.
4. Update major changes in _README.md_.
4. Update _docs\ThorUpdate.md_ on chages how to USE this tool.
4. Update _docs\VFPXDeployment.md_  on chages how this tool WORKS.
5. Describe the changes in the top of _docs\Change Log.md_.
6. Run the VFPX Deployment tool to create the installation files by
    -   Invoking menu item  **Thor Tools -> Applications -> VFPX Project Deployment**  
    -   Or executing ```EXECSCRIPT(_screen.cThorDispatcher, 'Thor_Tool_DeployVFPXProject')``` 
    -   Or executing Thor tool **"VFPX Project Deployment"**
    -   Or follow the [Documentation](../docs/ThorUpdate.md), this project is a normal project of itself.

---
7. Commit
8. Push to your fork
9. Create a pull request

----
Last changed: _2023-05-17_

![powered by VFPX](../docs/Images/vfpxpoweredby_alternative.gif "powered by VFPX")
