param(
    $PSM1 = "$PSScriptRoot\..\Source\ADOPS.psm1"
)

BeforeAll {
    Remove-Module ADOPS -Force -ErrorAction SilentlyContinue
    Import-Module $PSM1 -Force
}

Describe 'Get-ADOPSProject' {
    Context 'Parameters' {
        $TestCases = @(
            @{
                Name = 'Organization'
                Mandatory = $false
                Type = 'string'
            },
            @{
                Name = 'Project'
                Mandatory = $false
                Type = 'string'
            }
        )
    
        It 'Should have parameter <_.Name>' -TestCases $TestCases  {
            Get-Command Get-ADOPSProject | Should -HaveParameter $_.Name -Mandatory:$_.Mandatory -Type $_.Type
        }
    }

    Context 'Get project' {
        BeforeAll {
            Mock -CommandName GetADOPSDefaultOrganization -ModuleName ADOPS -MockWith { 'DummyOrg' }

            Mock -CommandName InvokeADOPSRestMethod -ModuleName ADOPS -MockWith {
                return @'
                {
                    "value": [
                        {
                            "id": "34f7babc-b656-4d13-bf24-bba1782d88fe",
                            "name": "DummyProject",
                            "description": "DummyProject",
                            "url": "https://dev.azure.com/DummyOrg/_apis/projects/34f7babc-b656-4d13-bf24-bba1782d88fe",
                            "state": "wellFormed",
                            "revision": 1,
                            "visibility": "private",
                        }
                    ]
                }
'@ | ConvertFrom-Json
            } -ParameterFilter { $Method -eq 'GET' }

            $OrganizationName = 'DummyOrg'
            $Project = 'DummyProject'
        }

        It 'uses InvokeADOPSRestMethod one time.' {
            Get-ADOPSProject -Organization $OrganizationName -Project $Project 
            Should -Invoke 'InvokeADOPSRestMethod' -ModuleName 'ADOPS' -Exactly -Times 1
        }
        It 'returns output after getting project' {
            Get-ADOPSProject -Organization $OrganizationName -Project $Project | Should -BeOfType [pscustomobject] -Because 'InvokeADOPSRestMethod should convert the json to pscustomobject'
        }
        It 'should not throw with no parameters' {
            { Get-ADOPSProject } | Should -Not -Throw
        }
    }
}
