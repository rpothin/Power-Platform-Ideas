Function New-AzureDevOpsProject {
    <#
        .SYNOPSIS
            Create an Azure DevOps project if it does not exist.

        .DESCRIPTION
            Search an Azure DevOps project with the name provided.
            If no Azure DevOps project found, create a new one.

        .PARAMETER OrganizationUrl
            Specifies the URL of the targeted Azure DevOps organization.

        .PARAMETER ProjectName
            Specifies the name of the Azure Devops project to create.

        .PARAMETER ProjectDescription
            Specifies the description of the Azure Devops project to create.

        .PARAMETER ConfigurationFilePath
            Specifies the path to the configuration file to use for the creation of the Azure DevOps project.

        .INPUTS
            None. You cannot pipe objects to New-AzureDevOpsProject.

        .OUTPUTS
            Object. New-AzureDevOpsProject returns information regarding the Azure DevOps project found or created.

        .EXAMPLE
            PS> New-AzureDevOpsProject -OrganizationUrl "https://dev.azure.com/demonstration" -ProjectName "ExistingDemonstration" -ConfigurationFilePath ".\AzureDevOpsProjectConfiguration.txt"
            Id                  : 00000000-0000-0000-0000-000000000000
            Name                : ExistingDemonstration
            Description         : First test
            Url                 : https://dev.azure.com/demonstration/_apis/projects/00000000-0000-0000-0000-000000000000
            Visibility          : private
            State               : wellFormed
            Type                : Existing

        .EXAMPLE
            PS> New-AzureDevOpsProject -OrganizationUrl "https://dev.azure.com/demonstration" -ProjectName "NewDemonstration" -ProjectDescription "Description of the project" -ConfigurationFilePath ".\AzureDevOpsProjectConfiguration.txt"
            Id                  : 00000000-0000-0000-0000-000000000000
            Name                : NewDemonstration
            Description         : First test
            Url                 : https://dev.azure.com/demonstration/_apis/projects/00000000-0000-0000-0000-000000000000
            Visibility          : private
            State               : wellFormed
            Type                : Created

        .LINK
            README.md: https://github.com/microsoft/coe-starter-kit/tree/main/PowerPlatformDevOpsALM/SetupAutomation

        .NOTES
            * You need to be authenticated with an account with the permission to create a project in the considered Azure DevOps organization using the "az login" (Azure CLI) command to be able to use this function
    #>

    [CmdletBinding()]
    [OutputType([psobject])]
    Param (
        # URL of the targeted Azure DevOps organization
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$OrganizationUrl,
        
        # Name of the Azure DevOps project to create
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ProjectName,
        
        # Description of the Azure DevOps project to create
        [Parameter()]
        [String]$ProjectDescription,

        # Path to the configuration file to use for the creation of the Azure DevOps project
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ConfigurationFilePath
    )

    Begin{}

    Process{
        # Set ProjectDescription to empty string if not provided
        $ProjectDescription = if($ProjectDescription -eq $null) { '' } else { $ProjectDescription }

        # Extract the configuration of the Azure DevOps project to create
        Write-Verbose "Get content from configuration file in following location: $ConfigurationFilePath"
        try {
            Write-Verbose "Try to call the Get-Content command."
            Write-Debug "Before the call to the Get-Content command..."
            $values = Get-Content $ConfigurationFilePath -ErrorVariable getAzureDevOpsProjectConfigurationError -ErrorAction Stop | Out-String | ConvertFrom-StringData
            $process = $values.process
            $sourceControl = $values.sourceControl
            $visibility = $values.visibility

            $azureDevOpsProjectConfigurationExtracted = $true
        }
        catch {
            Write-Verbose "Error in the extraction of the Azure DevOps project configuration from the considered file: $getAzureDevOpsProjectConfigurationError"
            $azureDevOpsProjectConfigurationExtracted = $false
            $errorMessage = "Error in the extraction of the Azure DevOps project configuration from the considered file: $getAzureDevOpsProjectConfigurationError"
            $azureDevOpsProject = [PSCustomObject]@{
                Error = $errorMessage
            }
        }

        # Check the provided Azure DevOps organization URL provided (call to the 'az devops extension list' command)
        # List non built in and non disabled extensions for the considered Azure DevOps organization
        Write-Verbose "Try to call the 'az devops extension list' command for the following Azure DevOps organization: $OrganizationUrl"
        Write-Debug "Before the call to the 'az devops extension list' command..."
        $organizationNonBuiltInExtensions = az devops extension list --org $OrganizationUrl --include-built-in false

        # Case Azure DevOps organization does not exist
        if(!$organizationNonBuiltInExtensions) {
            Write-Verbose "Error in the verification of the existence of the following Azure DevOps organization: $OrganizationUrl"
            $errorMessage = "Error in the verification of the existence of the following Azure DevOps organization: $OrganizationUrl"
            $azureDevOpsProject = [PSCustomObject]@{
                Error = $errorMessage
            }
        }
        # Case Azure DevOps organization exists
        else {
            # Search for an existing Azure DevOps project with the name provided
            Write-Verbose "Search Azure DevOps projects with the following name: $ProjectName"
            Write-Debug "Before the call to the 'az devops project list' command..."
            $azureDevOpsProjectsListJson = az devops project list --org $OrganizationUrl --query "value[?contains(name, '$ProjectName')]"

            # Number of Azure DevOps projects found
            $azureDevOpsProjectsList = $azureDevOpsProjectsListJson | ConvertFrom-Json
            $azureDevOpsProjectsListMeasure = $azureDevOpsProjectsList | Measure
            $azureDevOpsProjectsListCount = $azureDevOpsProjectsListMeasure.Count

            # Case one Azure DevOps project found for the provided name
            if ($azureDevOpsProjectsListCount -eq 1) {
                Write-Verbose "Only one Azure DevOps project found - Do nothing"
                $azureDevOpsProjectFound = $azureDevOpsProjectsList[0]

                $azureDevOpsProject = [PSCustomObject]@{
                    Id = $azureDevOpsProjectFound.id
                    Name = $azureDevOpsProjectFound.name
                    Description = $azureDevOpsProjectFound.description
                    Url = $azureDevOpsProjectFound.url
                    Visibility = $azureDevOpsProjectFound.visibility
                    State = $azureDevOpsProjectFound.state
                    Type = "Existing"
                }
            }

            # Case no Azure DevOps project found for the provided name and configuration extracted from file
            if ($azureDevOpsProjectsListCount -eq 0 -and $azureDevOpsProjectConfigurationExtracted) {
                Write-Verbose "No Azure DevOps project found - Create a new one"

                # Call to 'az devops project create' command
                Write-Verbose "Try to call the 'az devops project create' command."
                Write-Debug "Before the call to the 'az devops project create' command..."
                $azureDevOpsProjectCreatedJson = az devops project create --org $OrganizationUrl --name $ProjectName --description $ProjectDescription --process $process --source-control $sourceControl --visibility $visibility
                
                if (!$azureDevOpsProjectCreatedJson) {
                    Write-Verbose "Error in the creation of the Azure DevOps project with the following name: $ProjectName"
                    $errorMessage = "Error in the creation of the Azure DevOps project with the following name: $ProjectName"
                    $azureDevOpsProject = [PSCustomObject]@{
                        Error = $errorMessage
                    }
                }
                else {
                    $azureDevOpsProjectCreated = $azureDevOpsProjectCreatedJson | ConvertFrom-Json

                    $azureDevOpsProject = [PSCustomObject]@{
                        Id = $azureDevOpsProjectCreated.id
                        Name = $azureDevOpsProjectCreated.name
                        Description = $azureDevOpsProjectCreated.description
                        Url = $azureDevOpsProjectCreated.url
                        Visibility = $azureDevOpsProjectCreated.visibility
                        State = $azureDevOpsProjectCreated.state
                        Type = "Created"
                    }
                }
            }

            # Case multiple Azure DevOps projects found for the provided name
            if ($azureDevOpsProjectsListCount -gt 1) {
                Write-Verbose "Error - Multiple Azure DevOps projects corresponding to the following name: $ProjectName"
                $errorMessage = "Error - Multiple Azure DevOps projects corresponding to the following name: $ProjectName"
                $azureDevOpsProject = [PSCustomObject]@{
                    Error = $errorMessage
                }
            }
        }

        # Return the considered Azure DevOps project (found or created)
        Write-Verbose "Return the Azure DevOps project found or created."
        Write-Debug "Before sending the output..."
        $azureDevOpsProject
    }

    End{}
}