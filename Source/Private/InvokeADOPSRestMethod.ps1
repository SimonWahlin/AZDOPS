function InvokeADOPSRestMethod {
    [SkipTest('HasOrganizationParameter')]
    param (
        [Parameter(Mandatory)]
        [URI]$Uri,

        [Parameter()]
        [Microsoft.PowerShell.Commands.WebRequestMethod]$Method,

        [Parameter()]
        [string]$Body,

        [Parameter()]
        [string]$ContentType = 'application/json',

        [Parameter()]
        [switch]$FullResponse,

        [Parameter()]
        [string]$OutFile,

        [Parameter()]
        [string]$Token
    )
    
    if (-not $PSBoundParameters.ContainsKey('Token')) {
        $Token = (NewAzToken).Token
    }

    $InvokeSplat = @{
        'Uri' = $Uri
        'Method' = $Method
        'Headers' = @{
            'Authorization' = "Bearer $Token"
        }
        'ContentType' = $ContentType
    }

    if (-not [string]::IsNullOrEmpty($Body)) {
        $InvokeSplat.Add('Body', $Body)
    }

    if ($FullResponse) {
        $InvokeSplat.Add('ResponseHeadersVariable', 'ResponseHeaders')
        $InvokeSplat.Add('StatusCodeVariable', 'ResponseStatusCode')
    }

    if ($OutFile) {
        Invoke-RestMethod @InvokeSplat -OutFile $OutFile
    }
    else {
        $Result = Invoke-RestMethod @InvokeSplat

        if ($Result -like "*Azure DevOps Services | Sign In*") {
            throw 'Failed to call Azure DevOps API. Please login using Connect-ADOPS before running commands.'
        }
        elseif ($FullResponse) {
            @{ Content = $Result; Headers = $ResponseHeaders; StatusCode = $ResponseStatusCode }
        }
        else {
            $Result
        }
    }
}
