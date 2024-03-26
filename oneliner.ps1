$userorg = "userorg"; `
Start-Process "https://github.$userorg.com"; `
Read-Host -Prompt "Log into GitHub in browser and then press Enter to continue"; `
Install-Script Install-Git -Scope CurrentUser -Force; `
Install-Git.ps1; `
$env:Path = [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ";" + [System.Environment]::GetEnvironmentVariable('Path', 'User'); `
$devbootPath = "$env:SystemDrive:\$userorg-devboot"; `
if (!(Test-Path $devbootPath)) { `
    mkdir $devbootPath; `
} `
else { `
    Remove-Item -Path $devbootPath -Recurse -Force; `
    mkdir $devbootPath; `
} `
git clone "https://github.com/$userorg/devboot.git" "C:\$userorg-devboot"; `
Push-Location "C:\$userorg-devboot"; `
.\publish-module.ps1