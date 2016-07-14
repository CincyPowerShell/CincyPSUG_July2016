$Users = Get-MsolUser -all

foreach ($User in $Users)
{
    If ($User.Department -eq "Sales")
    {
        Set-O365UserLicense -MsolUser $User -LicenseTemplate $SalesLicenses
    }
    
    if ($User.department -eq "Engineering")
    {
        Set-O365UserLicense -MsolUser $User -LicenseTemplate $EngineerLicense
    }
}