#requires -RunAsAdministrator

<#
.SYNOPSIS
Bootstrap script to set up and run WinGet configuration for developer workstations.

.DESCRIPTION
This script automates the setup of WinGet and runs a configuration file to install development tools.

.PARAMETER Configuration
Specifies which configuration to use. Valid values are:
- 'default': Standard configuration with Visual Studio Professional (configuration.dsc.yaml)
- 'minimal': Minimal configuration without Visual Studio (configuration.dsc.minimal.yaml)
- 'withDockerDesktop': Configuration including Docker Desktop (configuration.dsc.withDockerDesktop.yaml)

.EXAMPLE
.\devboot.ps1
Runs with the default configuration.

.EXAMPLE
.\devboot.ps1 -Configuration minimal
Runs with the minimal configuration.

.EXAMPLE
.\devboot.ps1 -Configuration withDockerDesktop
Runs with the Docker Desktop configuration.
#>

param(
    [ValidateSet('default', 'minimal', 'withDockerDesktop')]
    [string]$Configuration = 'default'
)

function GetLatestNetLtsVersion {
    $response = Invoke-RestMethod -Uri "https://dotnetcli.blob.core.windows.net/dotnet/release-metadata/releases-index.json"
    $latestLTS = $response.'releases-index' | Where-Object { $_.'release-type' -eq 'lts' } | Select-Object -First 1
    $latestVersion =[int]($latestLTS.'channel-version').ToString()
    Write-Host "Latest .NET LTS version is $latestVersion"
    return $latestVersion
}

# Map configuration names to file names
$configFiles = @{
    'default' = 'configuration.dsc.yaml'
    'minimal' = 'configuration.dsc.minimal.yaml'
    'withDockerDesktop' = 'configuration.dsc.withDockerDesktop.yaml'
}

$selectedConfigFile = $configFiles[$Configuration]
Write-Host "Using configuration: $Configuration ($selectedConfigFile)"

# Check/create/switch to devboot folder
$drive = Get-PsDrive -PsProvider FileSystem | Select-Object -First 1 | Select-Object -ExpandProperty Name
$devbootPath = $drive + ':\devboot'
if (!(Test-Path $devbootPath)) {
    mkdir $devbootPath
    mkdir $devbootPath\.winget
}
if (!(Test-Path $devbootPath\.winget)) {
    mkdir $devbootPath\.winget
}
if (!(Test-Path $devbootPath\.winget\install)) {
    mkdir $devbootPath\.winget\install
}
if (!(Test-Path $devbootPath\.vsconfig)) {
    mkdir $devbootPath\.vsconfig
}
if (!(Test-Path $devbootPath\.vsconfig\VS2022)) {
    mkdir $devbootPath\.vsconfig\VS2022
}

# Get version number of latest release version of winget
$latestRelease = Invoke-RestMethod -Uri https://api.github.com/repos/microsoft/winget-cli/releases | ConvertTo-Json -Depth 100 | ConvertFrom-Json | Where-Object { $_.prerelease -eq $false } | Select-Object -First 1 | Select-Object -ExpandProperty tag_name

# Skip installation if latest already installed
$wingetCurrentVersion = winget --version
if ($wingetCurrentVersion -ge $latestRelease) {
    Write-Host "Latest winget release version ($latestRelease) already installed (installed version: $wingetCurrentVersion; ignore following settings error prefixing version number display `
    if settings not initialized by a previous run): $wingetCurrentVersion"
}
else {
    # Display latest winget release version and current installed version
    Write-Host "Latest winget release version: $latestRelease; installed version: $wingetCurrentVersion"
    # Install latest winget release version
    Push-Location $devbootPath\.winget\install
    $downloadUrl = (([System.Net.HttpWebRequest]::Create('https://github.com/microsoft/winget-cli/releases/latest/').GetResponse().ResponseUri.AbsoluteUri) -Replace 'tag', 'download') + '/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
    Start-BitsTransfer -Source $downloadUrl -Destination Microsoft.DesktopAppInstaller.msixbundle
    $wingetPreviewInstaller = Get-ChildItem -Filter Microsoft.DesktopAppInstaller*.msixbundle | Sort-Object LastWriteTime | Select-Object -Last 1 | Select-Object -ExpandProperty FullName
    Add-AppxPackage -Path $wingetPreviewInstaller
    Pop-Location
}

# # Deprecated by general release of WinGet Configurations without requiring enablement of experimental settings
# # Check/add 'configuration' experimental setting to winget settings file
# $wingetSettingsFilePath = "$env:LocalAppData\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalState\"
# $settingsFileName = "settings.json"
# $wingetSettingsFilePathFull = $wingetSettingsFilePath + $settingsFileName
# $wingetSettingsFile = Get-ChildItem -Path $env:LocalAppData\Packages\Microsoft.DesktopAppInstaller*\LocalState\settings.json | Select-Object -ExpandProperty FullName
# if ($null -eq $wingetSettingsFile) {
#     Write-Host "Could not find winget settings file; creating a new one"
#     # Create new empty winget settings file
#     New-Item -Path $wingetSettingsFilePath -Name $settingsFileName -ItemType File
#     $fileModel = New-Object -TypeName PSObject
#     $fileModel | Add-Member -MemberType NoteProperty -Name '$schema' -Value 'https://aka.ms/winget-settings.schema.json'
#     $fileModel | ConvertTo-Json | Set-Content $wingetSettingsFilePathFull
#     $wingetSettingsFile = Get-ChildItem -Path $wingetSettingsFilePathFull
# }
# $settings = Get-Content -Raw $wingetSettingsFile | ConvertFrom-Json
# $experimentalFeaturesSettings = $settings.experimentalFeatures
# if ($null -eq $experimentalFeaturesSettings) {
#     $settings | Add-Member -MemberType NoteProperty -Name experimentalFeatures -Value @{}
#     $settings.experimentalFeatures = @{'configuration'=$true}
# }
# else {
#     $experimentalFeatures = $settings.experimentalFeatures
#     if ($null -eq $experimentalFeatures.configuration) {
#         $experimentalFeatures | Add-Member -MemberType NoteProperty -Name configuration -Value $true
#     }
#     else {
#         if ($experimentalFeatures.configuration -eq $false) {
#             $experimentalFeatures.configuration = $true
#         }
#     }
# }
# $settings | ConvertTo-Json | Set-Content $wingetSettingsFile

# Download winget configuration and dependencies (.vsconfig, etc.)
Push-Location $devbootPath
Start-BitsTransfer -Source https://raw.githubusercontent.com/userorg/devboot/main/.vsconfig/VS2022/.vsconfig -Destination .vsconfig/VS2022/.vsconfig
Start-BitsTransfer -Source https://raw.githubusercontent.com/userorg/devboot/main/.winget/configuration.dsc.yaml -Destination .winget/configuration.dsc.yaml
# Run winget configure using configuration file with verbose output, and opening logs folder after run
# Note: using --disable-interactivity to interactive prompts other than agreeing to configuration warning causes Notepad++ and possibly other apps to fail to install, so removed for now
& winget configure -f .winget\configuration.dsc.yaml --verbose --logs
Pop-Location
