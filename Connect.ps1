# save a credential object
$O365Cred = Get-Credential

#region Azure Active Directory
# import the Azure AD module
Import-Module MSOnline -Force

# connect to Azure AD
Connect-MsolService -Credential $O365Cred
#endregion

#region Exchange
$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange `
    -ConnectionUri "https://outlook.office365.com/powershell-liveid/" `
    -Credential $O365Cred `
    -Authentication "Basic" `
    -AllowRedirection
Import-PSSession $ExchangeSession
#endregion

#region Sharepoint
Import-Module Microsoft.Online.Sharepoint.PowerShell
Connect-SPOService -url https://cincypowershell-admin.sharepoint.com -Credential $O365Cred

#endregion

#region SkypeForBusiness
Import-Module LyncOnlineConnector
$SkypeSession = New-CsOnlineSession -Credential $O365Cred
Import-PSSession $SkypeSession
#endregion

#region ComplianceCenter
$ComplianceSession = New-PSSession -ConfigurationName Microsoft.Exchange `
    -ConnectionUri "https://ps.compliance.protection.outlook.com/powershell-liveid/" `
    -Credential $O365Cred `
    -Authentication "Basic" `
    -AllowRedirection
Import-PSSession $ComplianceSession

#endregion

#region A better way

Start-Process https://github.com/mattmcnabb/ConnectO365

#endregion