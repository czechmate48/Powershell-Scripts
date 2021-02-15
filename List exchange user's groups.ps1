$smtp_address = Read-Host -Prompt 'What is the email address of the user? (ex. john.doe@contoso.net)'
$admin_credential = Get-Credential
Import-Module ExchangeOnlineManagement
Connect-ExchangeOnline -Credential $admin_credential -ShowProgress $false
$smtp_mailbox = Get-Mailbox | Where-Object {$_.PrimarySmtpAddress -eq $smtp_address}
$office365_groups = Get-UnifiedGroup | Where-Object { (Get-UnifiedGroupLinks $_.Alias -LinkType Members | ForEach-Object {$_.name}) -contains $smtp_mailbox.Alias}
$distribution_groups = Get-DistributionGroup | Where-Object {(Get-DistributionGroupMember $_.Name | ForEach-Object {$_.PrimarySmtpAddress}) -contains $smtp_address}

$office365_groups
$distribution_groups