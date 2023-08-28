# devboot - WinGet Configuration Baseline BootStrap/Setup and Run
# 🏃tl;dr Usage
Run the one-liner in [Scripted, one-liner Winget Configuration Setup and Run](#-scripted-one-liner-winget-configuration-setup-and-run)
# Purpose
tl;dr: Auto Bulk Software Installs for Dev Workstations via [Winget Configuration]([url](https://learn.microsoft.com/en-us/windows/package-manager/configuration/)) and/or [Dev Home]([url](https://learn.microsoft.com/en-us/windows/dev-home/setup)) app

Microsoft announced a nice new way of doing desired state configuration (DSC) for workstations via pretty simple YAML code/configs - especially for dev systems - at Build, called winget configuration and in tests it's pretty cool. In other words, it can install a list of commonly needed development software with a few clicks in a new app from MSFT called Dev Home or a command from a terminal. 

We also can call it from Dev Box (Windows development workstation in Azure accessed via Remote Desktop, etc) confguration which was also announced at Build and is in private preview now. 

I set up this repo with configs for all of this and worked out some issues and I think it works well. The `devboot.ps1` script automates the steps listed in Microsoft's Winget Congiguration setup (also listed below in Manual Setup) since their tool is in preview at the time of writing and so requires these additional opt-in steps.

Alternatively, users could install the new Dev Home app from Windows Store, then add their GitHub account, clone the repo in the app (along with a list of other repos in bulk if desired), and use the Machine Configuration > Configuration File option there to run the winget config with a GUI. 

This could/should be very useful to help save probably hours per developer reinstalling software when workstations need to be reset/reimaged or for new machine setups.

> Note: Individual projects can have their own Winget Configurations and .vsconfig's (VS will even feature these in a popup in the application when present) as well for project-specific tooling, prerequisites, but this allows us to get a good baseline install of the most commonly used development tools installed and managed here so that those do not need to be managed in each project - just the few specifics, if needed. :)

# Usage
> Note: Winget Configuration, as Desired State Configuration (DSC), is idempotent, so you can rerun it without affecting the already-installed software.

## Prerequisites
- Appropriate PowerShell ExecutionPolicy (example: Set a less restrictive script execution policy like `Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned`. See [more information and warnings](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies) in Microsoft's PowerShell documentation.)
## 🤖 Scripted, one-liner Winget Configuration Setup and Run
1. Run the script (in an admin-elevated PowerShell session) like this:<br/>
`Start-BitsTransfer -Source "https://raw.githubusercontent.com/berndtgroup/devboot/main/devboot.ps1"; .\devboot.ps1`
2. Type `y` when prompted to confirm the safety of the source of the configuration you are applying.
3. The folder with the logs from the run will be displayed after the run is completed. 

## 💪 Manual Winget Configuration Setup and Run
1. Install the latest winget "-preview" version from https://aka.ms/getwingetpreview
2. Enable the winget experimental feature "Configuration" with the brief steps at https://learn.microsoft.com/en-us/windows/package-manager/configuration/#enable-the-winget-configuration-experimental-configuration-preview-feature
3. Clone devboot repo
4. Run `winget configure -f .winget\configuration.dsc.yaml --verbose` from repo root
5. If you run into issues, you can quickly abandon this method and do a manual install of all software and only have spent 5 minutes trying to save a few hours. :)

# 📝 Notes & Known Issues
- Docker Desktop has been moved for now to an alternative configuration file, `configuration.dsc.withDockerDesktop.yaml`, since Docker Desktop for Windows Containers requires Hyper-V and related configurations to function which the Winget Configuration method of running the setup for does not currently seem to enable. This means that one would likely need to do so [manually](https://docs.docker.com/desktop/troubleshoot/topics/#hyper-v) either before or after running devboot or Winget configure using the included configuration. This nullifies the time savings and convenience, so it is recommended to simply [install Docker Desktop manually](https://docs.docker.com/desktop/install/windows-install/) and let it configure it's prerequisites rather than have it included in this configuration.

# 🆘 Troubleshooting
 - Error running script: "...cannot be loaded because running scripts is disabled on this system..."
   - Solution: Set a less restrictive script execution policy like `Set-ExecutionPolicy -Scope LocalMachine -ExecutionPolicy RemoteSigned`. See [more information and warnings](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies) in Microsoft's PowerShell documentation.

# 🙏 Software Suggestions, Ideas
Please make software installation suggestions and other ideas for devboot in the [Ideas Discussion](https://github.com/BerndtGroup/devboot/discussions/categories/ideas)
