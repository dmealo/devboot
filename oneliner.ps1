Start-Process "https://github.valtech.com"; `
Read-Host -Prompt "Log into GitHub in browser and then press Enter to continue"; `
Install-Script Install-Git -Scope CurrentUser -Force; `
Install-Git.ps1; `
$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ";" + [System.Environment]::GetEnvironmentVariable('Path', 'User'); `
$devbootPath = "$env:SystemDrive:\valtech-devboot"; `
if (!(Test-Path $devbootPath)) { `
    mkdir $devbootPath; `
} `
else { `
    Remove-Item -Path $devbootPath -Recurse -Force; `
    mkdir $devbootPath; `
} `
git clone "https://github.com/US-Baltimore-Valtech/internal-vbalt-ps-modules.git" "C:\valtech-devboot"; `
Push-Location "C:\valtech-devboot"; `
.\publish-module.ps1