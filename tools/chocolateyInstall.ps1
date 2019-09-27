# Custom value: [[CustomValue]]
$ErrorActionPreference = 'Stop'; # stop on all errors


$packageName  = 'ivanti-heat-agent'
$toolsDir     = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$fileLocation = Join-Path $toolsDir 'lmsetupx64.exe'

$pp = Get-PackageParameters

if (!$pp.HeatServerAddress) { $pp.HeatServerAddress = 'heat.example.com' }
if (!$pp.HeatModuleList) { $pp.HeatModuleList = 'VulnerabilityManagement' }


$packageArgs = @{
  packageName   = $packageName
  file          = $fileLocation
  fileType      = 'exe' #only one of these: exe, msi, msu

  #EXE
  silentArgs    = "install SERVERADDRESS=$($pp.HeatServerAddress) MODULELIST=$($pp.HeatModuleList)"
    validExitCodes= @(0, 3010, 1641)
}

Install-ChocolateyInstallPackage @packageArgs
