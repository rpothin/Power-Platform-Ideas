BeforeAll {
    # Import New-AzureDevOpsProject function
    Import-Module .\New-AzureDevOpsProject.ps1 -Force
}

# New-AzureDevOpsProject tests without integrations with other modules
Describe "New-AzureDevOpsProject Unit Tests" -Tag "UnitTests" {
    Context "Parameters configuration verification" {
        It "Given the Mandatory attribute of the OrganizationUrl parameter, it should be equal to true" {
            (Get-Command New-AzureDevOpsProject).Parameters['OrganizationUrl'].Attributes.Mandatory | Should -Be $true
        }
        It "Given the Mandatory attribute of the ProjectName parameter, it should be equal to true" {
            (Get-Command New-AzureDevOpsProject).Parameters['ProjectName'].Attributes.Mandatory | Should -Be $true
        }
        It "Given the Mandatory attribute of the ConfigurationFilePath parameter, it should be equal to true" {
            (Get-Command New-AzureDevOpsProject).Parameters['ConfigurationFilePath'].Attributes.Mandatory | Should -Be $true
        }
    }

    Context "Azure DevOps project configuration extraction from file verification" {
        BeforeEach{
            # Variables initialization
            $organizationUrlForTests = "https://dev.azure.com/tests"
            $existingAzureDevOpsProjectName = "ExistingProject"
            $nonExistingAzureDevOpsProjectName = "NonExistingProject"
            $correctConfigurationFile = ".\AzureDevOpsProjectConfiguration.txt"
            $wrongFormatConfigurationFile = ".\WrongFormatAzureDevOpsProjectConfiguration.txt"
            $wrongConfigurationFilePath = ".\wrongpath.ko"

            # Simulate the extraction of the content of the Azure DevOps project configuration file
            $azureDevOpsProjectConfigurationMock = @('process=Basic', 'sourceControl=git', 'visibility=private')
            $wrongFormatAzureDevOpsProjectConfigurationMock = @('wrongProcess=Basic', 'wrongSourceControl=git', 'wrongVisibility=private')
            Mock Get-Content { $azureDevOpsProjectConfigurationMock } -ParameterFilter { $Path -eq $correctConfigurationFile }
            Mock Get-Content { $wrongFormatAzureDevOpsProjectConfigurationMock } -ParameterFilter { $Path -eq $wrongFormatConfigurationFile }

            # Simulate the behavior of the execution of the 'az devops extension list' command
            $extensionListResult = [PSCustomObject]@{}

            Mock az { $extensionListResult | ConvertTo-Json } -ParameterFilter { "$args" -match 'devops extension list' }

            # Simulate the behavior of the execution of the 'az devops project list' command
            $projectListResult = [PSCustomObject]@{
                id = "00000000-0000-0000-0000-000000000000"
                name = $existingAzureDevOpsProjectName
                description = ""
                url = "https://dev.azure.com/tests/_apis/projects/00000000-0000-0000-0000-000000000000"
                visibility = "private"
                state = "wellFormed"
            }

            # Simulate the behavior of the execution of the 'az devops project create' command
            $projectCreated = [PSCustomObject]@{
                id = "00000000-0000-0000-0000-000000000000"
                name = $nonExistingAzureDevOpsProjectName
                description = ""
                url = "https://dev.azure.com/tests/_apis/projects/00000000-0000-0000-0000-000000000000"
                visibility = "private"
                state = "wellFormed"
            }

            Mock az { $projectCreated | ConvertTo-Json } -ParameterFilter { "$args" -match 'devops project create' }

            # Definition of the exepcted results of the tests of the this context
            $expectedResultExistingAzureDevOpsProjectFound = [PSCustomObject]@{
                Id = "00000000-0000-0000-0000-000000000000"
                Name = $existingAzureDevOpsProjectName
                Description = ""
                Url = "https://dev.azure.com/tests/_apis/projects/00000000-0000-0000-0000-000000000000"
                Visibility = "private"
                State = "wellFormed"
                Type = "Existing"
            }

            $expectedResultAzureDevOpsProjectCreated = [PSCustomObject]@{
                Id = "00000000-0000-0000-0000-000000000000"
                Name = $nonExistingAzureDevOpsProjectName
                Description = ""
                Url = "https://dev.azure.com/tests/_apis/projects/00000000-0000-0000-0000-000000000000"
                Visibility = "private"
                State = "wellFormed"
                Type = "Created"
            }

            $expectedResultWrongPathToAzureDevOpsConfigurationFile = [PSCustomObject]@{
                Error = "Error in the extraction of the Azure DevOps project configuration from the considered file: System.Management.Automation.ActionPreferenceStopException: The running command stopped because the preference variable 'ErrorActionPreference' or common parameter is set to Stop: Cannot find path"
            }
        }

        It "Given a correct path to a well formated Azure DevOps project configuration file and the name of an existing Azure DevOps project, it should return the information of the Azure DevOps project found" {
            Mock az { $projectListResult | ConvertTo-Json } -ParameterFilter { "$args" -match 'devops project list' }
            
            (New-AzureDevOpsProject -OrganizationUrl $organizationUrlForTests -ProjectName $existingAzureDevOpsProjectName -ConfigurationFilePath $correctConfigurationFile | ConvertTo-Json) | Should -Be ($expectedResultExistingAzureDevOpsProjectFound | ConvertTo-Json)
        }

        It "Given a correct path to an Azure DevOps project configuration file with errors and the name of an existing Azure DevOps project, it should return the information of the Azure DevOps project found" {
            Mock az { $projectListResult | ConvertTo-Json } -ParameterFilter { "$args" -match 'devops project list' }
            
            (New-AzureDevOpsProject -OrganizationUrl $organizationUrlForTests -ProjectName $existingAzureDevOpsProjectName -ConfigurationFilePath $wrongFormatConfigurationFile | ConvertTo-Json) | Should -Be ($expectedResultExistingAzureDevOpsProjectFound | ConvertTo-Json)
        }

        It "Given an incorrect path to an Azure DevOps project configuration file and the name of an existing Azure DevOps project, it should return the information of the Azure DevOps project found" {
            Mock az { $projectListResult | ConvertTo-Json } -ParameterFilter { "$args" -match 'devops project list' }
            
            (New-AzureDevOpsProject -OrganizationUrl $organizationUrlForTests -ProjectName $existingAzureDevOpsProjectName -ConfigurationFilePath $wrongFormatConfigurationFile | ConvertTo-Json) | Should -Be ($expectedResultExistingAzureDevOpsProjectFound | ConvertTo-Json)
        }

        It "Given a correct path to a well formated Azure DevOps project configuration file and the name of a non existing Azure DevOps project, it should return the information of the Azure DevOps project created" {
            Mock az { } -ParameterFilter { "$args" -match 'devops project list' }
            
            (New-AzureDevOpsProject -OrganizationUrl $organizationUrlForTests -ProjectName $nonExistingAzureDevOpsProjectName -ConfigurationFilePath $correctConfigurationFile | ConvertTo-Json) | Should -Be ($expectedResultAzureDevOpsProjectCreated | ConvertTo-Json)
        }

        It "Given a correct path to an Azure DevOps project configuration file with errors and the name of a non existing Azure DevOps project, it should return the information of the Azure DevOps project found" {
            Mock az { } -ParameterFilter { "$args" -match 'devops project list' }
            
            (New-AzureDevOpsProject -OrganizationUrl $organizationUrlForTests -ProjectName $nonExistingAzureDevOpsProjectName -ConfigurationFilePath $wrongConfigurationFilePath).Error.Substring(0, 288).replace('"', '''') | Should -Be $expectedResultWrongPathToAzureDevOpsConfigurationFile.Error
        }

        It "Given an incorrect path to an Azure DevOps project configuration file and the name of a non existing Azure DevOps project, it should return the information of the Azure DevOps project found" {
            Mock az { } -ParameterFilter { "$args" -match 'devops project list' }
            
            (New-AzureDevOpsProject -OrganizationUrl $organizationUrlForTests -ProjectName $nonExistingAzureDevOpsProjectName -ConfigurationFilePath $wrongConfigurationFilePath).Error.Substring(0, 288).replace('"', '''') | Should -Be $expectedResultWrongPathToAzureDevOpsConfigurationFile.Error
        }
    }

    Context "Behavior verification regarding the validation of the Azure DevOps organization URL provided" {
        BeforeEach{
            # Variables initialization
            $organizationUrlForTests = "https://dev.azure.com/tests"
            $wrongOrganizationUrlForTests = "https://dev.azure.com/unknown"
            $existingAzureDevOpsProjectName = "ExistingProject"
            $nonExistingAzureDevOpsProjectName = "NonExistingProject"
            $correctConfigurationFile = ".\AzureDevOpsProjectConfiguration.txt"

            # Simulate the extraction of the content of the Azure DevOps project configuration file
            $azureDevOpsProjectConfigurationMock = @('process=Basic', 'sourceControl=git', 'visibility=private')
            Mock Get-Content { $azureDevOpsProjectConfigurationMock } -ParameterFilter { $Path -eq $correctConfigurationFile }

            # Simulate the behavior of the execution of the 'az devops extension list' command
            $extensionListResult = [PSCustomObject]@{}

            # Simulate the behavior of the execution of the 'az devops project list' command
            $projectListResult = [PSCustomObject]@{
                id = "00000000-0000-0000-0000-000000000000"
                name = $existingAzureDevOpsProjectName
                description = ""
                url = "https://dev.azure.com/tests/_apis/projects/00000000-0000-0000-0000-000000000000"
                visibility = "private"
                state = "wellFormed"
            }

            Mock az { $projectListResult | ConvertTo-Json } -ParameterFilter { "$args" -match 'devops project list' }
            
            # Definition of the exepcted results of the tests of the this context
            $expectedResultExistingAzureDevOpsProjectFound = [PSCustomObject]@{
                Id = "00000000-0000-0000-0000-000000000000"
                Name = $existingAzureDevOpsProjectName
                Description = ""
                Url = "https://dev.azure.com/tests/_apis/projects/00000000-0000-0000-0000-000000000000"
                Visibility = "private"
                State = "wellFormed"
                Type = "Existing"
            }

            $expectedResultErrorVerificationOrganizationUrl = [PSCustomObject]@{
                Error = "Error in the verification of the existence of the following Azure DevOps organization: $wrongOrganizationUrlForTests"
            }
        }

        It "Given a correct Azure DevOps organization URL and the name of an existing Azure DevOps project, it should return the information of the Azure DevOps project found" {
            Mock az { $extensionListResult | ConvertTo-Json } -ParameterFilter { "$args" -match 'devops extension list' }

            (New-AzureDevOpsProject -OrganizationUrl $organizationUrlForTests -ProjectName $existingAzureDevOpsProjectName -ConfigurationFilePath $correctConfigurationFile | ConvertTo-Json) | Should -Be ($expectedResultExistingAzureDevOpsProjectFound | ConvertTo-Json)
        }

        It "Given a wrong Azure DevOps organization URL and the name of an existing Azure DevOps project, it should return an error regarding the verification of the Azure DevOps organization URL" {
            Mock az { } -ParameterFilter { "$args" -match 'devops extension list' }

            (New-AzureDevOpsProject -OrganizationUrl $wrongOrganizationUrlForTests -ProjectName $existingAzureDevOpsProjectName -ConfigurationFilePath $correctConfigurationFile | ConvertTo-Json) | Should -Be ($expectedResultErrorVerificationOrganizationUrl | ConvertTo-Json)
        }
    }

    Context "Behavior verification regarding Azure DevOps project search results" {
        BeforeEach{
            # Variables initialization
            $organizationUrlForTests = "https://dev.azure.com/tests"
            $existingAzureDevOpsProjectName = "ExistingProject"
            $nonExistingAzureDevOpsProjectName = "NonExistingProject"
            $correctConfigurationFile = ".\AzureDevOpsProjectConfiguration.txt"

            # Simulate the extraction of the content of the Azure DevOps project configuration file
            $azureDevOpsProjectConfigurationMock = @('process=Basic', 'sourceControl=git', 'visibility=private')
            Mock Get-Content { $azureDevOpsProjectConfigurationMock } -ParameterFilter { $Path -eq $correctConfigurationFile }

            # Simulate the behavior of the execution of the 'az devops extension list' command
            $extensionListResult = [PSCustomObject]@{}

            Mock az { $extensionListResult | ConvertTo-Json } -ParameterFilter { "$args" -match 'devops extension list' }

            # Simulate the behavior of the execution of the 'az devops project list' command
            $oneProjectFound = [PSCustomObject]@{
                id = "00000000-0000-0000-0000-000000000000"
                name = $existingAzureDevOpsProjectName
                description = ""
                url = "https://dev.azure.com/tests/_apis/projects/00000000-0000-0000-0000-000000000000"
                visibility = "private"
                state = "wellFormed"
            }

            $multipleProjectsFound = @($oneProjectFound, $oneProjectFound)

            # Simulate the behavior of the execution of the 'az devops project create' command
            $projectCreated = [PSCustomObject]@{
                id = "00000000-0000-0000-0000-000000000000"
                name = $nonExistingAzureDevOpsProjectName
                description = ""
                url = "https://dev.azure.com/tests/_apis/projects/00000000-0000-0000-0000-000000000000"
                visibility = "private"
                state = "wellFormed"
            }

            Mock az { $projectCreated | ConvertTo-Json } -ParameterFilter { "$args" -match 'devops project create' }

            # Definition of the exepcted results of the tests of the this context
            $expectedResultOneExistingAzureDevOpsProjectFound = [PSCustomObject]@{
                Id = "00000000-0000-0000-0000-000000000000"
                Name = $existingAzureDevOpsProjectName
                Description = ""
                Url = "https://dev.azure.com/tests/_apis/projects/00000000-0000-0000-0000-000000000000"
                Visibility = "private"
                State = "wellFormed"
                Type = "Existing"
            }

            $expectedResultAzureDevOpsProjectCreated = [PSCustomObject]@{
                Id = "00000000-0000-0000-0000-000000000000"
                Name = $nonExistingAzureDevOpsProjectName
                Description = ""
                Url = "https://dev.azure.com/tests/_apis/projects/00000000-0000-0000-0000-000000000000"
                Visibility = "private"
                State = "wellFormed"
                Type = "Created"
            }

            $expectedResultMultipleExistingAzureDevOpsProjectsFound = [PSCustomObject]@{
                Error = "Error - Multiple Azure DevOps projects corresponding to the following name: $existingAzureDevOpsProjectName"
            }
        }

        It "Given the name of an existing Azure DevOps project, it should return the information of the Azure DevOps project found" {
            Mock az { $oneProjectFound | ConvertTo-Json } -ParameterFilter { "$args" -match 'devops project list' }

            (New-AzureDevOpsProject -OrganizationUrl $organizationUrlForTests -ProjectName $existingAzureDevOpsProjectName -ConfigurationFilePath $correctConfigurationFile | ConvertTo-Json) | Should -Be ($expectedResultOneExistingAzureDevOpsProjectFound | ConvertTo-Json)
        }

        It "Given the name of a non existing Azure DevOps project, it should return the information of the Azure DevOps project created" {
            Mock az { } -ParameterFilter { "$args" -match 'devops project list' }

            (New-AzureDevOpsProject -OrganizationUrl $organizationUrlForTests -ProjectName $nonExistingAzureDevOpsProjectName -ConfigurationFilePath $correctConfigurationFile | ConvertTo-Json) | Should -Be ($expectedResultAzureDevOpsProjectCreated | ConvertTo-Json)
        }

        It "Given the name of an existing Azure DevOps project with the search returning multiple results, it should return an error regarding the number of results for the searche of an existing Azure DevOps project" {
            Mock az { $multipleProjectsFound | ConvertTo-Json } -ParameterFilter { "$args" -match 'devops project list' }

            (New-AzureDevOpsProject -OrganizationUrl $organizationUrlForTests -ProjectName $existingAzureDevOpsProjectName -ConfigurationFilePath $correctConfigurationFile | ConvertTo-Json) | Should -Be ($expectedResultMultipleExistingAzureDevOpsProjectsFound | ConvertTo-Json)
        }
    }

    Context "Behavior verification regarding Azure DevOps project creation" {
        BeforeEach{
            # Variables initialization
            $organizationUrlForTests = "https://dev.azure.com/tests"
            $nonExistingAzureDevOpsProjectName = "NonExistingProject"
            $correctConfigurationFile = ".\AzureDevOpsProjectConfiguration.txt"

            # Simulate the extraction of the content of the Azure DevOps project configuration file
            $azureDevOpsProjectConfigurationMock = @('process=Basic', 'sourceControl=git', 'visibility=private')
            Mock Get-Content { $azureDevOpsProjectConfigurationMock } -ParameterFilter { $Path -eq $correctConfigurationFile }

            # Simulate the behavior of the execution of the 'az devops extension list' command
            $extensionListResult = [PSCustomObject]@{}

            Mock az { $extensionListResult | ConvertTo-Json } -ParameterFilter { "$args" -match 'devops extension list' }

            # Simulate the behavior of the execution of the 'az devops project list' command
            Mock az { } -ParameterFilter { "$args" -match 'devops project list' }

            # Simulate the behavior of the execution of the 'az devops project create' command
            $projectCreated = [PSCustomObject]@{
                id = "00000000-0000-0000-0000-000000000000"
                name = $nonExistingAzureDevOpsProjectName
                description = ""
                url = "https://dev.azure.com/tests/_apis/projects/00000000-0000-0000-0000-000000000000"
                visibility = "private"
                state = "wellFormed"
            }

            # Definition of the exepcted results of the tests of the this context
            $expectedResultAzureDevOpsProjectCreated = [PSCustomObject]@{
                Id = "00000000-0000-0000-0000-000000000000"
                Name = $nonExistingAzureDevOpsProjectName
                Description = ""
                Url = "https://dev.azure.com/tests/_apis/projects/00000000-0000-0000-0000-000000000000"
                Visibility = "private"
                State = "wellFormed"
                Type = "Created"
            }

            $expectedResultErrorInAzureDevOpsProjectCreation = [PSCustomObject]@{
                Error = "Error in the creation of the Azure DevOps project with the following name: $nonExistingAzureDevOpsProjectName"
            }
        }

        It "Given the name of a non existing Azure DevOps project without error during creation, it should return the information of the Azure DevOps project created" {
            Mock az { $projectCreated | ConvertTo-Json } -ParameterFilter { "$args" -match 'devops project create' }

            (New-AzureDevOpsProject -OrganizationUrl $organizationUrlForTests -ProjectName $nonExistingAzureDevOpsProjectName -ConfigurationFilePath $correctConfigurationFile | ConvertTo-Json) | Should -Be ($expectedResultAzureDevOpsProjectCreated | ConvertTo-Json)
        }

        It "Given the name of a non existing Azure DevOps project with an error during creation, it should return an error regarding the creation of the Azure DevOps project" {
            Mock az { } -ParameterFilter { "$args" -match 'devops project create' }

            (New-AzureDevOpsProject -OrganizationUrl $organizationUrlForTests -ProjectName $nonExistingAzureDevOpsProjectName -ConfigurationFilePath $correctConfigurationFile | ConvertTo-Json) | Should -Be ($expectedResultErrorInAzureDevOpsProjectCreation | ConvertTo-Json)
        }
    }
}

# New-AzureDevOpsProject tests with integrations with external dependencies
#   Prerequisites: To execute the following tests you need to
#       - be authenticated using the 'az login' command
#       - to have a $OrganizationUrl initialized with a valid Azure DevOps organization URL
Describe "New-AzureDevOpsProject Integration Tests" -Tag "IntegrationTests" {
    Context "Integration tests with the commands of the Azure CLI" {
        BeforeEach{
            # Variables initialization
            $projectName = "Test auto $(Get-Date -format 'yyyyMMdd')"
            $projectDescription = "Test auto $(Get-Date -format 'yyyyMMdd') - Description"
            $correctConfigurationFile = ".\AzureDevOpsProjectConfiguration.txt"

            # Simulate the extraction of the content of the Azure DevOps project configuration file
            $azureDevOpsProjectConfigurationMock = @('process=Basic', 'sourceControl=git', 'visibility=private')
            Mock Get-Content { $azureDevOpsProjectConfigurationMock } -ParameterFilter { $Path -eq $correctConfigurationFile }
        }

        It "Given the name of a non existing Azure DevOps project, it should return the information of the Azure DevOps project created" {
            $newAzureDevOpsProject = New-AzureDevOpsProject -OrganizationUrl $OrganizationUrl -ProjectName $projectName -ProjectDescription $projectDescription -ConfigurationFilePath $correctConfigurationFile
    
            $newAzureDevOpsProject.Id | Should -Not -BeNullOrEmpty
            $newAzureDevOpsProject.Name | Should -Be $projectName
            $newAzureDevOpsProject.Description | Should -Be $projectDescription
            $newAzureDevOpsProject.Url | Should -BeLike "$OrganizationUrl*"
            $newAzureDevOpsProject.Visibility | Should -Be "private"
            $newAzureDevOpsProject.State | Should -Be "wellFormed"
            $newAzureDevOpsProject.Type | Should -Be "Created"
        }
    
        It "Given the name of an existing Azure DevOps project, it should return the information of the Azure DevOps project found" {
            $existingAzureDevOpsProject = New-AzureDevOpsProject -OrganizationUrl $OrganizationUrl -ProjectName $projectName -ProjectDescription $projectDescription -ConfigurationFilePath $correctConfigurationFile
    
            $existingAzureDevOpsProject.Id | Should -Not -BeNullOrEmpty
            $existingAzureDevOpsProject.Name | Should -Be $projectName
            $existingAzureDevOpsProject.Description | Should -Be $projectDescription
            $existingAzureDevOpsProject.Url | Should -BeLike "$OrganizationUrl*"
            $existingAzureDevOpsProject.Visibility | Should -Be "private"
            $existingAzureDevOpsProject.State | Should -Be "wellFormed"
            $existingAzureDevOpsProject.Type | Should -Be "Existing"
        }
    }
}