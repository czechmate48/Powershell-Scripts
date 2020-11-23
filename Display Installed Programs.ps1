#--------------------------------------------------#
# ADAPTED BY: Christopher N. Sefcik
# DATE: 11/23/2020
# ATTRIBUTION: This script is a slight adaptation of the script created by Ed Wilson & Sean Kearney
# https://devblogs.microsoft.com/scripting/use-powershell-to-quickly-find-installed-software/
#--------------------------------------------------#

$computername=$env:COMPUTERNAME
#Define the variable to hold the location of currently installed programs
$UninstallKey="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
#Create an instance of the Registry Object and open the HKLM base key
$reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$computername)
$regkey=$reg.OpenSubKey($UninstallKey) #Open Uninstall key
$subkeys=$regkey.GetSubKeyNames() #Retrieve array of sub keys
foreach ($key in $subkeys){
    $thiskey=$UninstallKey+"\\"+$key
    $thisSubKey=$reg.OpenSubKey($thiskey)
    $DisplayName=$thisSubKey.GetValue("DisplayName")
    if ($DisplayName -notlike ""){ #Prevents values without a diplay name from displaying
        Write-Host $comptuername, $DisplayName
    }
}