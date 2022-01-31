function InvokeAZDevOPSRestMethod {
    param (
        [Parameter(Mandatory)]
        [URI]$uri,

        [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestMethod]$method,

        [Parameter()]
        [string]$Body
    )

    $CallHeaders = GetAZDevOPSHeader

    $InvokeSplat = @{
        'Uri' = $uri
        'Method' = $method
        'Headers' = $CallHeaders
        'ContentType' = 'application/json'
    }

    if (-not [string]::IsNullOrEmpty($Body)) {
        $InvokeSplat.Add('Body', $body)
    }
    
    $result = Invoke-RestMethod @InvokeSplat

    if ($result -like "*Azure DevOps Services | Sign In*") {
        throw 'Failed to call Azure DevOps API. Please login before using.'
    }
    else {
        $result
    }
}