# get basic sharepoint tenant information
Get-SpoTenant

# get site information
Get-SpoSite -Identity https://cincypowershell-my.sharepoint.com/personal/matt_mcnabb_cincypowershell_org | fl

# get site information with storage quota
Get-SpoSite -Identity https://cincypowershell-my.sharepoint.com/personal/matt_mcnabb_cincypowershell_org -Detailed | fl