function Get-ADOPSPipeline {
    [CmdletBinding()]
    param (
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Project,
        
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$Organization
    )

    if (-not [string]::IsNullOrEmpty($Organization)) {
        $OrgInfo = GetADOPSHeader -Organization $Organization
    }
    else {
        $OrgInfo = GetADOPSHeader
        $Organization = $OrgInfo['Organization']
    }

    $Uri = "https://dev.azure.com/$Organization/$Project/_apis/pipelines?api-version=7.1-preview.1"
    
    $InvokeSplat = @{
        Method       = 'Get'
        Uri          = $URI
        Organization = $Organization
    }

    $AllPipelines = (InvokeADOPSRestMethod @InvokeSplat).value

    if ($PSBoundParameters.ContainsKey('Name')) {
        $Pipelines = $AllPipelines | Where-Object {$_.name -eq $Name}
        if (-not $Pipelines) {
            throw "The specified PipelineName $Name was not found amongst pipelines: $($AllPipelines.name -join ', ')!" 
        } 
    } else {
        $Pipelines = $AllPipelines
    }

    $return = @()

    foreach ($Pipeline in $Pipelines) {

        $InvokeSplat = @{
            Method       = 'Get'
            Uri          = $Pipeline.url
            Organization = $Organization
        }
    
        $result = InvokeADOPSRestMethod @InvokeSplat

        $return += $result
    }

    return $return
}

