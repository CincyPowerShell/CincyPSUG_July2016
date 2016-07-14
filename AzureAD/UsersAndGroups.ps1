#region users

# get details of an Azure AD user
Get-MsolUser -UserPrincipalName matt.mcnabb@cincypowershell.org

# save the user to a variable
$Matt = Get-Msoluser -UserPrincipalName matt.mcnabb@cincypowershell.org

# search for a user
Get-MsolUser -SearchString Jay

# get all users
Get-MsolUser -All

# create a user
$Frodo = New-MsolUser -DisplayName 'Frodo Baggins' -UserPrincipalName 'frodo.baggins@cincypowershell.org'

#endregion

#region groups

# find all groups
Get-MsolGroup -All

# create a group
New-MsolGroup -DisplayName 'The Fellowship'

#endregion