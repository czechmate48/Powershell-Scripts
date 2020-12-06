#----------------------------#
# Created by: Christopher N. Sefcik
# Use: Remove a duplicate OneDrive mapping in the windows file explorer
# Info: This script implements a fix obtained from https://appuals.com/fix-multiple-folders-icons-onedrive/
#       The script hides the OneDrive folder in the windows explorer, but does not remove it from the system. 
#	This program will not work if there are two OneDrive folders with the same name.
#----------------------------#

New-PSDrive -PSProvider registry -Root HKEY_CLASSES_ROOT -Name HKCR
$namespace="HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Desktop\Namespace"
$oneDriveKey = Get-ChildItem $namespace | Get-ItemProperty | Where-Object {$_.'(default)' -like 'OneDrive'}
$tmpKey=$oneDriveKey.PSChildName
Set-Itemproperty "HKCR:\CLSID\$tmpKey" -Name "System.IsPinnedToNameSpaceTree" -value 0
