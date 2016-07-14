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

# modify the services available in the license
$DisabledPlans = @(
    'PROJECTWORKMANAGEMENT',
    'SWAY',
    'INTUNE_O365',
    'YAMMER_ENTERPRISE',
    'RMS_S_ENTERPRISE'
)
$Options = New-MsolLicenseOptions -AccountSkuId cincypowershell:ENTERPRISEPACK -DisabledPlans $DisabledPlans
$Frodo | Set-MsolUserLicense -LicenseOptions $Options
