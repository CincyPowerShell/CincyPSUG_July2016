# get skype users
Get-CSOnlineUser

# get a particular user
Get-CSOnlineUser -Identity matt.mcnabb@cincypowershell.org

# disable audio and video
Set-CSUser -Identity matt.mcnabb@cincypowershell.org -AudioVideoDisabled $true

# set Skype to archive IMs to Exchange mailbox
Set-CSUser -Identity matt.mcnabb@cincypowershell.org -ExchangeArchivingPolicy ArchivingToExchange