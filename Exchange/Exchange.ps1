# retrieve all mailboxes
Get-Mailbox -ResultSize unlimited

# Configure mail forwarding
Set-Mailbox -Identity frodo.baggins -ForwardingAddress matt.mcnabb -DeliverToMailboxAndForward

# Configure a mailbox to be hidden from the Global Address List
Set-Mailbox -Identity frodo.baggins -HiddenFromAddressListsEnabled $true

# troubleshoot message delivery
Get-MessageTrace -SenderAddress matt.mcnabb@cincypowershell.org

# report on OSes used to access Office 365
Get-O365ClientOSDetailReport | where upn -like "matt*" | select *