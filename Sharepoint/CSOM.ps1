#requires -module Microsoft.Online.Sharepoint.PowerShell
function Invoke-SPORestMethod
{
    <#
            .SYNOPSIS
            Calls a given SharePoint REST endpoint given proper credentials for the tenant.

            .PARAMETER Url
            The address of the Sharepoint site you are interested in.

            .PARAMETER Api
            The Sharepoint REST api endpoint address relative to the address supplied in -Uri.

            .PARAMETER Method
            Specifies how the REST Api should be called. Default is GET.

            .PARAMETER Body
            Specifies the request body if needed. This should be in JSON format.

            .PARAMETER Credential
            The credential of an Office 365 global admin that can take action on Sharepoint objects.

            .EXAMPLE
        
        
            .EXAMPLE
            $Webinfos = & $psise.CurrentFile.FullPath -api https://contoso-my.sharepoint.com/personal/bob_contoso_com/_api/site/rootWeb/webinfos -credential $O365Cred
            $Webinfos.result

            Use the above example to find subsites created under onedrive site
        
            .EXAMPLE
            $Body = "{ '__metadata': { 'type': 'SP.User' }, 'LoginName':'i:0#.f|membership|bob@contoso.com' }"
            Invoke-SPORest -Url 'https://contoso.sharepoint.com/teams/teamsite' -Api '_api/web/sitegroups(8)/users' -Credential $O365Cred -Method post -Body $Body

            Add a user to a group using the group id ('8')

            .NOTES
            found here:
            https://github.com/OfficeDev/call-spo-rest
            Can i build an entire cmdlet library around this method? Should turn this into afunction and turn the JSON into objects
            API endpoints: https://msdn.microsoft.com/en-us/library/office/jj860569.aspx

            Sharepoint claims Encoding:
            http://social.technet.microsoft.com/wiki/contents/articles/13921.sharepoint-2013-claims-encoding-also-valuable-for-sharepoint-2010.aspx
    #>
    
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [String]
        $Url,
        
        [Parameter(Mandatory = $true)]
        [string]
        $Api,
        
        [Parameter(Mandatory = $True)]
        [System.Management.Automation.CredentialAttribute()]
        $Credential,
        
        [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestMethod]
        $Method = 'Get',
        
        [Parameter()]
        $Body
    )

    BEGIN
    {
        # Create the SharePoint Online credentials so we can call the APIs.
        $SPOCredential = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials ($Credential.UserName, $Credential.Password)
    }

    PROCESS
    {
        # Once the credentials are assembled, create the web request to call the REST APIs.
        $Url = $(if ($Url -like 'https://*') { $Url } else { "https://$($Url)" }) -replace '/$'
        $Api = $(if ($Api -like '/*') { $Api } else { "/$Api" }) -replace '/$'
        $ApiUri = "$Url$Api"
        $Request = [System.Net.WebRequest]::Create($ApiUri)
        $Request.Headers.Add("x-forms_based_auth_accepted", "f") 
        $Request.Accept = "application/json; odata=verbose"
        $Request.Credentials = $SPOCredential 

        # Set the verb (and the verb header, if needed).
        if (
            ($Method -ne [Microsoft.PowerShell.Commands.WebRequestMethod]::Get) -and
            ($Method -ne [Microsoft.PowerShell.Commands.WebRequestMethod]::Post) -and
            ($Method -ne [Microsoft.PowerShell.Commands.WebRequestMethod]::Delete)
        )
        {
            # PUT, PATCH, etc. have to use a X-HTTP-Method header, 
            # with POST as the real verb.
            $Request.Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Post
            $Request.Headers.Add("X-HTTP-Method", $Method)
        }
        else  { $Request.Method = $Method }

        # Get the request digest, if needed.
        if ($Method -ne [Microsoft.PowerShell.Commands.WebRequestMethod]::Get)
        {
            # Create the contextinfo URL.
            [string[]] $SplitURL = $ApiUri.Split("_")
            $Domain = $SplitURL[0]
            $ContextInfoURL = $Domain + "_api/contextinfo" 

            # Create the digest request
            $DigestRequest = [System.Net.WebRequest]::Create($ContextInfoURL)
            $DigestRequest.Headers.Add("x-forms_based_auth_accepted", "f") 
            $DigestRequest.Accept = "application/xml"
            $DigestRequest.Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Post
            $DigestRequest.Credentials = $SPOCredential
            $DigestRequest.ContentLength = 0

            # Get the digest from the response
            $Response = $DigestRequest.GetResponse()
            $Stream = $Response.GetResponseStream()
            $ReadStream = New-Object System.IO.StreamReader $Stream
            $ResponseData=$ReadStream.ReadToEnd()
            $Namespace = @{d="http://schemas.microsoft.com/ado/2007/08/dataservices"}
            $Digest = ($ResponseData | Select-Xml -Namespace $Namespace -XPath "//d:FormDigestValue")
    
            # Add digest to header of main request.
            $Request.Headers["X-RequestDigest"] = $Digest.Node.InnerXml
        }

        # Add the body, if there is one. 
        if ($Body)
        { 
            $Encoding = New-Object System.Text.ASCIIEncoding
            [byte[]] $BodyByteArray = $Encoding.GetBytes($body)
            $Request.ContentLength = $BodyByteArray.Length
            $RequestStream = $Request.GetRequestStream()
            $RequestStream.Write($BodyByteArray, 0, $BodyByteArray.Length)
            $Request.ContentType = "application/json; odata=verbose"
        }

        # Execute the response and see what happens.
        # this line takes avg 568 ms - is there a faster way?
        $Response = $Request.GetResponse()
        $Stream = $Response.GetResponseStream()
        $ReadStream = New-Object System.IO.StreamReader $Stream
        $ResponseData = $ReadStream.ReadToEnd()

        # Return the response as JSON
        # this line takes avg 548 ms - is there a faster way?
        ($ResponseData | ConvertFrom-JSON).d.results # can JSON.Net improve this?
    }
}

function Get-OnedriveSubsite
{
        <#
            .SYNOPSIS
            Returns Urls of any child SPWebs in a Onedrive for Business personal site collection.
            .DESCRIPTION
        
            .PARAMETER LoginName
            The UPN format username of a Onedrive for Business user.
            .EXAMPLE
        
            .NOTES
        
            .LINK
        
        #>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
        $LoginName,
        
        $TenantName,
        
        [System.Management.Automation.CredentialAttribute()]
        $Credential
    )

    PROCESS
    {
        $Url = Get-OnedriveUrl -TenantName $TenantName -LoginName $LoginName
        try
        {
            Invoke-SPORestMethod -Url $Url -Api '_api/web/webinfos' -Credential $Credential -ErrorAction Stop
        }
        catch [System.Management.Automation.MethodInvocationException]
        {
            $Global:Error.RemoveAt(0)
        }
    }
}

function Get-OnedriveUrl
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true)]
        [string]
        $TenantName,
        
        [Parameter(Mandatory=$true)]
        [string]
        $LoginName
    )
        
    $RelativeUrl = $LoginName -replace '[.@]','_'
    $RootUrl = "https://$TenantName-my.sharepoint.com/personal"
    "$RootUrl/$RelativeUrl"
}

# check for subsites of Onedrive site collections
Get-MsolUser | % {Get-OnedriveSubsite -LoginName  $_.userprincipalname -TenantName cincypowershell -Credential $O365Cred}