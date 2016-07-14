# find Preservation Policies
Get-CCRetentionCompliancePolicy

# Create a Preservation Policy
# whatif doesn't work here!
$MySiteUrl = Get-O365OnedriveUrl -TenantName CincyPowershell -LoginName frodo.baggins@cincypowershell.org
New-CCRetentionCompliancePolicy -Name FrodoOnedrive -SharepointLocation $MySiteUrl -Enabled $true
New-CCRetentionComplicanceRule -Name FrodoOnedrive -PreservationDuration 120