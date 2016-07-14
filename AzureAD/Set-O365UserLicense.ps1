function Set-O365UserLicense
{
    <#
            .SYNOPSIS
            Sets licenses for Office 365 users.
            
            .PARAMETER MsolUser
            Specifies an Azure Active Directory user to set license entitlements for. Should be an object of type [Microsoft.Online.Administration.User] which is returned by the Get-MsolUser cmdlet found in the Azure Active Directory (MSOnline) module.
            
            .PARAMETER LicenseTemplate
            Specifies a licensing template to apply to the user. The license template should be a collection of one or more hashtables with two keys in each: "AccountSkuId" and "EnabledPlans." The AccountSkuId value should be the complete name of a license subscription including the tenant name, and the EnabledPlans value should be the names of any of the service plans that belong to that license subscription that you'd like enabled for the user(s). Any plans not included in the EnabledPlans value will be disabled. This means that you must specify at least one service plan for each AccountSkuId that you would like to provision.

            As an example, this license template contains values to provide a user with Exchange, Sharepoint, Office Web Apps, Skype For Business, and Yammer.

            $LicenseTemplate = @(
                @{
                    AccountSkuId = 'whitehouse:ENTERPRISEPACK'
                    EnabledPlans = 'EXCHANGE_S_ENTERPRISE','SHAREPOINTENTERPRISE','SHAREPOINTWAC','MCOSTANDARD','YAMMER_ENTERPRISE'
                },

                @{
                    AccountSkuId = 'whitehouse:PROJECTONLINE_PLAN_1'
                    EnabledPlans = 'OFFICESUBSCRIPTION'
                }
            )
            
            .EXAMPLE
            $Template = @{AccountSkuId = 'whitehouse:ENTERPRISEPACK'; EnabledPlans = 'EXCHANGE_S_ENTERPRISE'}
            
            $User = Get-MsolUser -UserPrincipalName abe.lincoln@whitehouse.gov
            Set-O365UserLicense -MsolUser $User -LicenseTemplate $Template
            
            .INPUTS
            [Microsoft.Online.Administration.User]
            
            .NOTES
            Author: Matt McNabb
            Date: 3/17/2016

            Todo
            X Remove any licenses not in the template
            Full error handling - transactional?
            Validate that all sku and service plan input is valid
            full module with helpers?
            empty template to clear all licensing?

            Prerequisites
            Azure Active Directory Module (MSOnline)
            PowerShell v2.0+
            Office 365 global admin account
            Connection to Azure Active Directory
            eventually add this to set-o365userlicense
              - with parameter sets: accountskuid and template, which allows for setting all licenses or just one
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [Microsoft.Online.Administration.User]
        $MsolUser,
        
        [Parameter(Mandatory = $true)]
        [ValidateScript(
                {
                    foreach ($Item in $_)
                    {
                        ($Item.ContainsKey('AccountSkuId')) -and
                        ($Item.ContainsKey('EnabledPlans')) -and
                        ($Item.AccountSkuId) -and
                        ($Item.EnabledPlans)
                    }   
                }
        )]
        [hashtable[]]
        $LicenseTemplate
    )

    begin
    {
        # get skus and available service plans
        $AccountSkuIds = Get-MsolAccountSku
        
        # convert enabled service plans to disabled
        # generate license options collection
        $LicenseOptions = foreach ($Item in $LicenseTemplate)
        {
            $AllPlans = ($AccountSkuIds | Where-Object { $_.AccountSkuId -eq $Item.AccountSkuId }).ServiceStatus
            $DisabledPlans = ($AllPlans | Where-Object { $_.ServicePlan.ServiceName -notin $Item.EnabledPlans }).ServicePlan.ServiceName
            New-MsolLicenseOptions -AccountSkuId $Item.AccountSkuId -DisabledPlans $DisabledPlans
        }
    }

    process
    {
        # add license with options for each sku
        # if error, try to just set the license options
        
        $UserPrincipalName = $MsolUser.UserPrincipalName
        $CurrentSkus = $MsolUser.Licenses.AccountSkuId
        
        if ($PSCmdlet.ShouldProcess($UserPrincipalName))
        {
            $Splat = @{
                UserPrincipalName = $UserPrincipalName
            }
            
            # set licenses and options from template
            foreach ($LicenseOption in $LicenseOptions)
            {
                $Sku = "$($LicenseOption.AccountSkuId.AccountName):$($LicenseOption.AccountSkuId.SkuPartNumber)"
                $Splat.AddLicenses = $Sku
                $Splat.LicenseOptions = $LicenseOption
                
                try
                {
                    Set-MsolUserLicense @Splat -ErrorAction Stop
                }
                catch [Microsoft.Online.Administration.Automation.MicrosoftOnlineException]
                {
                    switch ($_)
                    {
                        { $_.Exception -match '.+UsageLocation$' } { throw $_; break }
        
                        default
                        {
                            $Splat.Remove('AddLicenses')
                            Set-MsolUserLicense @Splat -ErrorAction Stop
                        }
                    }       
                }
            }
            
            # remove any licenses that the user currently owns that aren't included in the template
            foreach ($License in $CurrentSkus)
            {
                if ($License -notin $LicenseTemplate.AccountSkuId )
                {
                    Set-MsolUserLicense -UserPrincipalName $UserPrincipalName -RemoveLicenses $License -ErrorAction Stop
                }
            }
        }
    }
}

$Template = @{
    AccountSkuId = 'cincypowershell:ENTERPRISEPACK'
    EnabledPlans = @(
        'EXCHANGE_S_ENTERPRISE',
        'SHAREPOINTENTERPRISE',
        'SHAREPOINTWAC',
        'MCOSTANDARD',
        'YAMMER_ENTERPRISE'
    )
}

Set-O365UserLicense -MsolUser $MAtt -LicenseTemplate $Template