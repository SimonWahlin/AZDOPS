param(
    $PSM1 = "$PSScriptRoot\..\Source\ADOPS.psm1"
)

BeforeAll {
    Remove-Module ADOPS -Force -ErrorAction SilentlyContinue
    Import-Module $PSM1 -Force
}

Describe 'Start-ADOPSPipeline' {
    Context 'Parameters' {
        $TestCases = @(
            @{
                Name      = 'Name'
                Mandatory = $true
                Type      = 'string'
            },
            @{
                Name      = 'Project'
                Mandatory = $true
                Type      = 'string'
            },
            @{
                Name      = 'Organization'
                Mandatory = $false
                Type      = 'string'
            },
            @{
                Name      = 'Branch'
                Mandatory = $false
                Type      = 'string'
            }
        )
    
        It 'Should have parameter <_.Name>' -TestCases $TestCases {
            Get-Command Start-ADOPSPipeline | Should -HaveParameter $_.Name -Mandatory:$_.Mandatory -Type $_.Type
        }
    }

    Context 'Starting pipeline' {
        BeforeAll {
            InModuleScope -ModuleName ADOPS {
                Mock -CommandName GetADOPSDefaultOrganization -ModuleName ADOPS -MockWith { 'DummyOrg' }
            
                Mock -CommandName InvokeADOPSRestMethod -ModuleName ADOPS -MockWith {
                    '{"count":2,"value":[{"_links":{"self":{"href":"https://dev.azure.com/dummyorg/9ca5975f-7615-4f60-927d-d9222b095544/_apis/pipelines/1?revision=1"},"web":{"href":"https://dev.azure.com/dummyorg/9ca5975f-7615-4f60-927d-d9222b095544/_build/definition?definitionId=1"}},"url":"https://dev.azure.com/dummyorg/9ca5975f-7615-4f60-927d-d9222b095544/_apis/pipelines/1?revision=1","id":1,"revision":1,"name":"dummypipeline1","folder":"\\"},{"_links":{"self":{"href":"https://dev.azure.com/dummyorg/9ca5975f-7615-4f60-927d-d9222b095544/_apis/pipelines/3?revision=1"},"web":{"href":"https://dev.azure.com/dummyorg/9ca5975f-7615-4f60-927d-d9222b095544/_build/definition?definitionId=3"}},"url":"https://dev.azure.com/dummyorg/9ca5975f-7615-4f60-927d-d9222b095544/_apis/pipelines/3?revision=1","id":3,"revision":1,"name":"dummypipeline2","folder":"\\"}]}' | ConvertFrom-Json     
                } -ParameterFilter { $Method -eq 'Get' }
    
                Mock -CommandName InvokeADOPSRestMethod -ModuleName ADOPS -MockWith {
                    return $InvokeSplat
                } -ParameterFilter { $Method -eq 'Post' }
            }
        }

        It 'Should call mock InvokeADOPSRestMethod' {
            Start-ADOPSPipeline -Name 'DummyPipeline1' -Project 'DummyProject'
            Should -Invoke 'InvokeADOPSRestMethod' -ModuleName 'ADOPS' -Exactly -Times 2
        }
        It 'If no organization is passed, get default' {
            Start-ADOPSPipeline -Name 'DummyPipeline1' -Project 'DummyProject'
            Should -Invoke 'GetADOPSDefaultOrganization' -ModuleName 'ADOPS' -Exactly -Times 1
        }
        It 'If an organization is passed, that organization should be used for URI' {
            Start-ADOPSPipeline -Name 'DummyPipeline1' -Project 'DummyProject' -Organization 'Organization'
            Should -Invoke 'GetADOPSDefaultOrganization' -ModuleName 'ADOPS' -Exactly -Times 0
        }
        It 'If no pipeline with correct name is found we should throw error' {
            { Start-ADOPSPipeline -Name 'NonExistingPipeline' -Project 'DummyProject' -Organization 'Organization' } | Should -Throw
        }
        It 'Uri should be set correct' {
            $r = Start-ADOPSPipeline -Name 'DummyPipeline1' -Project 'DummyProject'
            $r.Uri | Should -Be 'https://dev.azure.com/DummyOrg/DummyProject/_apis/pipelines/1/runs?api-version=7.1-preview.1'
        }
        It 'Method should be post' {
            $r = Start-ADOPSPipeline -Name 'DummyPipeline1' -Project 'DummyProject'
            $r.Method | Should -Be 'post'
        }
        It 'Body should be set with branch name. If no branch is given, "main"' {
            $r = Start-ADOPSPipeline -Name 'DummyPipeline1' -Project 'DummyProject'
            $r.Body | Should -BeLike '*main*'
        }
        It 'Body should be set with branch name If branch is given as parameter, "branch"' {
            $r = Start-ADOPSPipeline -Name 'DummyPipeline1' -Project 'DummyProject' -Branch 'branch'
            $r.Body | Should -BeLike '*branch*'
        }
    }
}