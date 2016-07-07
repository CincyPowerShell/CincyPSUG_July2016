# what licenses are available?
Get-MsolAccountSku

# what plans are available?
Get-MsolAccountSku | Select-Object -ExpandProperty ServiceStatus

#region licenses
# see what licenses skus a user has assigned
Get-MsolUser -UserPrincipalName matt.mcnabb@cincypowershell.org |
    Select-Object -ExpandProperty licenses

# what service plans are enabled?
Get-MsolUser -UserPrincipalName matt.mcnabb@cincypowershell.org |
    Select-Object -ExpandProperty Licenses |
    Select-Object -ExpandProperty ServiceStatus

# Add a license
$Frodo | Set-MsolUserLicense -AddLicenses cincypowershell:ENTERPRISEPACK
#endregion