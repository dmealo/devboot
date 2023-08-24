#requires -RunAsAdministrator
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

# Get version number of latest preview version of winget
$releases = Invoke-RestMethod -Uri https://api.github.com/repos/microsoft/winget-cli/releases
$releases | ConvertTo-Json -Depth 100 | Out-File -FilePath .\releases.json
$releases = Get-Content -Path .\releases.json -Raw | ConvertFrom-Json
$latestPreviewRelease = $releases | Where-Object { $_.prerelease -eq $true } | Select-Object -First 1 | Select-Object -ExpandProperty tag_name

# Skip installation if latest already installed
$wingetCurrentVersion = winget --version
if ($wingetCurrentVersion -eq $latestPreviewRelease) {
    Write-Host "Latest version of winget preview already installed: $wingetCurrentVersion"
}
else {
    # Install latest version of winget preview
    Push-Location $devbootPath\.winget\install
    Start-BitsTransfer -Source https://aka.ms/getwingetpreview -Destination Microsoft.DesktopAppInstaller.msixbundle
    $wingetPreviewInstaller = Get-ChildItem -Filter Microsoft.DesktopAppInstaller*.msixbundle | Sort-Object LastWriteTime | Select-Object -Last 1 | Select-Object -ExpandProperty FullName
    Add-AppxPackage -Path $wingetPreviewInstaller
}

# Check/add 'configuration' experimental setting to winget settings file

$wingetSettingsFile = Get-ChildItem -Path $env:UserProfile\AppData\Local\Packages\Microsoft.DesktopAppInstaller*\LocalState\settings.json | Select-Object -ExpandProperty FullName
$settings = Get-Content -Raw $wingetSettingsFile | ConvertFrom-Json
$experimentalFeaturesSettings = $settings.experimentalFeatures
if ($null -eq $experimentalFeaturesSettings) {
    $settings | Add-Member -MemberType NoteProperty -Name experimentalFeatures -Value ''
    $settings.experimentalFeatures | Add-Member -MemberType NoteProperty -Name configuration -Value true
}
else {
    $experimentalFeatures = $settings.experimentalFeatures
    if ($null -eq $experimentalFeatures.configuration) {
        $experimentalFeatures | Add-Member -MemberType NoteProperty -Name configuration -Value true
    }
    else {
        if ($experimentalFeatures.configuration -eq $false) {
            $experimentalFeatures.configuration = $true
        }
    }
}
$settings | ConvertTo-Json | Set-Content $wingetSettingsFile

# Download winget configuration and dependencies (.vsconfig, etc.)
Push-Location $devbootPath
Start-BitsTransfer -Source https://raw.githubusercontent.com/BerndtGroup/devboot/main/.vsconfig/VS2022/.vsconfig -Destination .vsconfig/VS2022/.vsconfig
Start-BitsTransfer -Source https://raw.githubusercontent.com/BerndtGroup/devboot/main/.winget/configuration.dsc.yaml -Destination .winget/configuration.dsc.yaml
# Run winget configure using configuration file with verbose output, and opening logs folder after run
# Note: using --disable-interactivity to interactive prompts other than agreeing to configuration warning causes Notepad++ and possibly other apps to fail to install, so removed for now
& winget configure -f .winget\configuration.dsc.yaml --verbose --logs
Pop-Location