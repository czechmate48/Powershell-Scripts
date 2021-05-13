#https://docs.microsoft.com/en-us/microsoft-365/enterprise/assign-licenses-to-user-accounts-with-microsoft-365-powershell?view=o365-worldwide#move-a-user-to-a-different-subscription-license-plan-with-the-azure-active-directory-powershell-for-graph-module

#Open powershell as an administrator

#CONNECT TO AZURE AD
Install-Module -Name AzureAD
Connect-AzureAD

#GET LIST OF USERS WITH E2 & E3 LICENSES
$e2OffUsers = @()
$e3OffUsers = @()
$e5OffUsers = @()
$e3MicUsers = @()
$e5MicUsers = @()
$e2OffSku = "STANDARDWOFFPACK"
$e3OffSku = "ENTERPRISEPACK"
$e5OffSku = "ENTERPRISEPREMIUM"
$e3MicSku = "SPE_E3"
$e5MicSku = "SPE_E5"
$entModSecE5 = "EMSPREMIUM"

#CSV FILE NEEDS COLUMN HEADER FOR CSV IMPORT TO WORK CORRECTLY
$identity = "identity"
$curLicense = "license"
$header = "$identity,$curLicense"
$header | Out-File "C:\users\csefcik\Documents\AllUsersAndLicenses.txt" -Append

$licensePlanList = Get-AzureADSubscribedSku
$userPrincipalNames = Get-AzureADUser -Top 700 | Where-Object {$_.UserType -ne "guest"}
$userSkus = $userPrincipalNames[1] | Select -ExpandProperty AssignedLicenses | Select SkuID #Get all user license skus

function Get-SkuPartNumber {

    [CmdletBinding()]
    param (
        [Object[]]$skus,
        [Object[]]$licensePlanList
    )

    $skuPartNumbers = @()

    for ($j=0; $j -lt $skus.Length; $j++){
        for ($k=0; $k -lt $licensePlanList.Length; $k++){
            If ($skus[$j].SkuId -eq $licensePlanList[$k].SkuId) {
                $skuPartNumbers += $licensePlanList[$k].SkuPartNumber
            }

        }
    }

    $skuPartNumbers.Count

    return $skuPartNumbers
}


for ($i=0; $i -lt $userPrincipalNames.Length; $i++) {

    $userSkus = $userPrincipalNames[$i] | Select -ExpandProperty AssignedLicenses | Select SkuID #Get all user license skus
    $skuPartNumbers = Get-SkuPartNumber -skus $userSkus -licensePlanList $licensePlanList

    if ($skuPartNumbers.Count -ne 0){
        $name = $userPrincipalNames[$i] | Select DisplayName
    }

    for ($j = 0; $j -lt $skuPartNumbers.Count; $j++){ #need to make sure coming trhough as an array skupartnumbers

        $skuPartNum = $skuPartNumbers[$j]

        if ($skuPartNum -like $e2OffSku){ #Office E2
            $e2OffUsers += $userPrincipalNames[$i].UserPrincipalName
            $curUserName = $userPrincipalNames[$i].UserPrincipalName
            $userAndLicense = "$curUserName,$e2OffSku"
        }
        elseif ($skuPartNum -like $e3OffSku){ #Office E3
            $e3OffUsers += $userPrincipalNames[$i].UserPrincipalName
            $curUserName = $userPrincipalNames[$i].UserPrincipalName
            $userAndLicense = "$curUserName,$e3OffSku"
        }
        elseif ($skuPartNum -like $e5OffSku) { #Office E5
            $e5OffUsers += $userPrincipalNames[$i].UserPrincipalName
            $curUserName = $userPrincipalNames[$i].UserPrincipalName
            $userAndLicense = "$curUserName,$e5OffSku"
        }
        elseif ($skuPartNum -like $e3MicSku){ #Microsoft E3
            $e3MicUsers += $userPrincipalNames[$i].UserPrincipalName
            $curUserName = $userPrincipalNames[$i].UserPrincipalName
            $userAndLicense = "$curUserName,$e3MicSku"
        }
        elseif ($skuPartNum -like $e5MicSku){ #Microsoft E5
            $e5MicUsers += $userPrincipalNames[$i].UserPrincipalName
            $curUserName = $userPrincipalNames[$i].UserPrincipalName
            $userAndLicense = "$curUserName,$e5MicSku"
        }
        else {
            continue
        }
        $userAndLicense | Out-File "C:\users\csefcik\Documents\AllUsersAndLicenses.txt" -Append
    }               
}

#GENERATE FILE WITH NAMES OF USERS BASED ON LICENSE TYPE
$e2OffUsers | ForEach {"$_.UserPrincipalName,$e2OffUsers" | Out-File "C:\users\csefcik\Documents\e2OffUsers.txt" -Append}
$e3OffUsers | ForEach {"$_.UserPrincipalName,$e3OffUsers" | Out-File "C:\users\csefcik\Documents\e3OffUsers.txt" -Append}
$e5OffUsers | ForEach {"$_.UserPrincipalName,$e5OffUsers" | Out-File "C:\users\csefcik\Documents\e5OffUsers.txt" -Append}
$e3MicUsers | Out-File "C:\users\csefcik\Documents\e3MicUsers.txt" -Append
$e5MicUsers  | Out-File "C:\users\csefcik\Documents\e5MicUsers.txt" -Append

#REPLACE BASE SUBSCRIPTION - DO NOT RUN UNTIL READY
$allUsersAndLicenses = Import-Csv "C:\users\csefcik\Documents\mutualUsers.txt"

#REPLACE "STANDARDWOFFPACK" WITH 'SPE_E3'
$allUsersAndLicenses | ForEach {

    $subscriptionFrom = $_.$curLicense
    $subscriptionTo = $e3MicSku
    $license = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
    $licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
    $license.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value $subscriptionFrom -EQ).SkuID
    $licenses.AddLicenses = $license
    Set-AzureADUserLicense -ObjectId $_.$identity -AssignedLicenses $licenses
    $licenses.AddLicenses = @()
    $licenses.RemoveLicenses =  (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value $subscriptionFrom -EQ).SkuID
    Set-AzureADUserLicense -ObjectId $_.$identity -AssignedLicenses $licenses
    $license.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value $subscriptionTo -EQ).SkuID
    $licenses = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
    $licenses.AddLicenses = $License
    Set-AzureADUserLicense -ObjectId $_.$identity -AssignedLicenses $licenses

}

#https://docs.microsoft.com/en-us/powershell/module/azuread/set-azureaduserlicense?view=azureadps-2.0
#ADD Enterprise Mobility + Security E5

#ASSIGN
$allUsersAndLicenses | ForEach {

    $userUPN = (Get-AzureADUser -ObjectId $_.$identity).UserPrincipalName
    $newLicense = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicense
    $newLicense.SkuId = (Get-AzureADSubscribedSku | Where-Object -Property SkuPartNumber -Value $entModSecE5 -EQ).SkuID
    $licenseToAssign = New-Object -TypeName Microsoft.Open.AzureAD.Model.AssignedLicenses
    $licenseToAssign.AddLicenses = $newLicense
    Set-AzureADUserLicense -ObjectId $userUPN -AssignedLicenses $licenseToAssign

}

#####
#Not part of above script. Used to combine AzureAD and Active Directory
#####

$identity = "identity"
$curLicense = "license"
$header = "$identity,$curLicense"
$header | Out-File "C:\users\csefcik\Documents\mutualUsers.txt" -Append
"email" | Out-File "C:\users\csefcik\Documents\inAD_NotAzure.txt"

$azureADUsers = Import-CSV -Path "C:\users\csefcik\Documents\AllUsersAndLicenses.txt"
$adUsers = Import-CSV -Path "C:\users\csefcik\Documents\adusers.txt"

$match = $false
for ($i=0; $i -lt $azureADUsers.Length; $i++){
    $userIdentity = $azureADUsers[$i].$identity
    $userLicense = $azureADUsers[$i].$curLicense
    $combo = "$userIdentity,$userLicense"
    for ($j=0; $j -lt $adUsers.Length; $j++){
        if ($azureADUsers[$i].identity -like $adUsers[$j].email){
            $combo | Out-File "C:\users\csefcik\Documents\mutualUsers.txt" -Append
            $match = $true
        }
    }
    if ($match -eq $false){
        #$combo | Out-File "C:\users\csefcik\Documents\notMutualUsers.txt" -Append
        $userIdentity | Out-File -FilePath "C:\users\csefcik\Documents\inAzure_NotAD.txt" -Append
    }
    else {
        $match = $false
    }
}

$match = $false
for ($i=0; $i -lt $adUsers.Length; $i++){
    $userIdentity = $adUsers[$i].email
    for ($j=0; $j -lt $azureADUsers.Length; $j++){
        if ($adUsers[$i].email -like $azureADUsers[$j].identity){
            $match = $true
        }
    }
    if ($match -eq $false){
        #$combo | Out-File "C:\users\csefcik\Documents\notMutualUsers.txt" -Append
        $userIdentity | Out-File -FilePath "C:\users\csefcik\Documents\inAD_NotAzure.txt" -Append
    }
    else {
        $match = $false
    }
}


