# How to contribute to Object Explorer

## Bug report?
- Please check [issues](https://github.com/VFPX/ObjectExplorer/issues) if the bug is reported
- If you're unable to find an open issue addressing the problem, open a new one. Be sure to include a title and clear description, as much relevant information as possible, and a code sample or an executable test case demonstrating the expected behavior that is not occurring.

### Did you write a patch that fixes a bug?
- Open a new GitHub merge request with the patch.
- Ensure the PR description clearly describes the problem and solution.
  - Include the relevant version number if applicable.
- See [New version](#new-version) for additional tasks

## New version
Here are the steps to updating to a new version:

1. Create a fork at github
   - See this [guide](https://www.dataschool.io/how-to-contribute-on-github/) for setting up and using a fork
2. Make whatever changes are necessary.
---
3. In folder _BuildProcess_:
   - Edit the Version setting in _ProjectSettings.txt_
   - Run Thor Tool "**Deploy VFPX Project**" to create the installation files.
3. Update the version and date in the top few lines and at the very bottom of _ReadMe.md_ 
3. Describe the changes in the top of _Change Log.md_.
---
6. Commit
9. Push to your fork
10. Create a pull request

----

Last changed: _2023-01-10_
![Picture](../Docs/Images/vfpxpoweredby_alternative.gif)