# Set up ALM Accelerator for Advanced Maker components

This folder contains some PowerShell functions to automate the Set up of the **ALM Accelerator For Advanced Makers** app, corresponding to the [**coe-starter-kit/ALMAcceleratorForAdvancedMakers/SETUPGUIDE.md**](https://github.com/microsoft/coe-starter-kit/blob/main/ALMAcceleratorForAdvancedMakers/SETUPGUIDE.md) procedure.

> This work was done in the early stages of the automation initiative for the setup of the **ALM Accelerator For Advanced Makers** app and then replaced by the [coe-cli](https://github.com/microsoft/coe-starter-kit/tree/main/coe-cli). But I think there are still some values in PowerShell code you will find in this folder 😊

## Good to know

- You can import the last version of each function by executing the following command: `Import-Module <PathToTheFunctionFile> -Force`

> You can use the following command to verify the function has been correctly imported: `Get-Command -Name '<FunctionName>' -CommandType Function`

- Once imported you can execute a function just with its name (*do not forget the paramaters*): `<FunctionName>`

> As configured today, the function will stay imported only in your current PowerShell session. You will need to import it again the next time you will want to use it.

- If you want to get some help regarding a function (*once imported*) you can use one of the following command:
   - `Get-Help <FunctionName>`: to have an overview of the function
   - `Get-Help <FunctionName> -Full`: to get all the details documented for the function

- You can get details about the execution of the function using the `-Verbose` parameter (*ex:* `New-DataverseEnvironment -DisplayName "Demonstration" -ConfigurationFilePath ".\DataverseEnvironmentConfiguration.txt -Verbose`)
- You can debug the execution of the function using the `-Debug` parameter (*ex:* `New-DataverseEnvironment -DisplayName "Demonstration" -ConfigurationFilePath ".\DataverseEnvironmentConfiguration.txt -Debug`)

## Functions

- **New-DataverseEnvironment** | [**SETUPGUIDE - Dataverse Environments**](https://github.com/microsoft/coe-starter-kit/blob/main/ALMAcceleratorForAdvancedMakers/SETUPGUIDE.md#dataverse-environments) - Create a new Dataverse environment if it does not exist.
- **New-AzureAdAppRegistration** | [**SETUPGUIDE - Create an App Registration in your AAD Environment**](https://github.com/microsoft/coe-starter-kit/blob/main/ALMAcceleratorForAdvancedMakers/SETUPGUIDE.md#create-an-app-registration-in-your-aad-environment) - Create an Azure AD app registration if it does not exist.
- **Install-AzureDevOpsExtensions** | [**SETUPGUIDE - Install Azure DevOps Extensions**](https://github.com/microsoft/coe-starter-kit/blob/main/ALMAcceleratorForAdvancedMakers/SETUPGUIDE.md#install-azure-devops-extensions) - Installed extensions in an Azure DevOps organization if they are not already installed.
- **New-AzureDevOpsProject** | Prerequisite for [**SETUPGUIDE - Clone the YAML Pipelines from GitHub to your Azure DevOps instance**](https://github.com/microsoft/coe-starter-kit/blob/main/ALMAcceleratorForAdvancedMakers/SETUPGUIDE.md#clone-the-yaml-pipelines-from-github-to-your-azure-devops-instance) - Create an Azure DevOps project if it does not exist.
- **New-ApplicationUserInDataverseEnvironment** | [**SETUPGUIDE - Create an App User in your Dataverse Environments**](https://github.com/microsoft/coe-starter-kit/blob/main/ALMAcceleratorForAdvancedMakers/SETUPGUIDE.md#create-an-app-user-in-your-dataverse-environments) - Create an application user in a Dataverse environment if it does not exist.

### New-DataverseEnvironment

> This function does not work for now with PowerShell 7 (*['Exception calling "AcquireToken with "4" argument(s)" Error with Add-PowerAppsAccount PowerShell Cmdlet](https://crmchap.co.uk/exception-calling-acquiretoken-with-4-arguments-error-with-add-powerappsaccount-powershell-cmdlet/) by [Joe Griffin](https://twitter.com/joejgriffin)*).

Create a new Dataverse environment if it does not exist (*search based on the DisplayName provided*).

#### Persona: Power Platform administrator

User with access to an Azure AD app registration with the following API Permissions: Dynamics CRM.user_impersonation, Microsoft Graph.User.Read and PowerApps Runtime Service (*more tests needed to check if we could execute the code with less permissions*).

**OR**

User with the Power Platform administrator or the Dynamics 365 administrator role in Azure AD (*more tests needed to check this point*).

#### Prerequisites

- You need to have the [**Microsoft.PowerApps.Administration.PowerShell**](https://www.powershellgallery.com/packages/Microsoft.PowerApps.Administration.PowerShell) PowerShell module installed to be able to use this function
- The **New-DataverseEnvironment** function requires a configuration file. You can use the **DataverseEnvironmentConfiguration.txt** file as a template.
- You need to be authenticated using the [**Add-PowerAppsAccount**](https://docs.microsoft.com/en-us/powershell/module/microsoft.powerapps.administration.powershell/add-powerappsaccount) (*Microsoft.PowerApps.Administration.PowerShell*) command to be able to use this function.

> You can use
> - a user account with the **Power Platform administrator** role or the **Dynamics 365 administrator** role in Azure AD
> - an app registration in Azure AD with the following API permissions: Dynamics CRM.user_impersonation, Microsoft Graph.User.Read and PowerApps Runtime Service.user_impersonation ==> do not forget to register the application using the [**New-PowerAppManagementApp**](https://docs.microsoft.com/en-us/powershell/module/microsoft.powerapps.administration.powershell/new-powerappmanagementapp) (*Microsoft.PowerApps.Administration.PowerShell*) command on your tenant

> The main advantage of using a service principal for the creation of a new Dataverse environment is that it will automatically be added as an application user in the new environment

- Configure the **DataverseEnvironmentConfiguration.txt** file using the following commands to help you:
   - [**Get-AdminPowerAppEnvironmentLocations**](https://docs.microsoft.com/en-us/powershell/module/microsoft.powerapps.administration.powershell/get-adminpowerappenvironmentlocations) (*Microsoft.PowerApps.Administration.PowerShell*) to get all the supported locations for your Dataverse environment
   - [**Get-AdminPowerAppCdsDatabaseLanguages**](https://docs.microsoft.com/en-us/powershell/module/microsoft.powerapps.administration.powershell/get-adminpowerappcdsdatabaselanguages) (*Microsoft.PowerApps.Administration.PowerShell*) to get all the supported languages for a specific location for your Dataverse environment
   - [**Get-AdminPowerAppCdsDatabaseTemplates**](https://docs.microsoft.com/en-us/powershell/module/microsoft.powerapps.administration.powershell/get-adminpowerappcdsdatabasetemplates) (*Microsoft.PowerApps.Administration.PowerShell*) to get all the supported applications for a specific location  for your Dataverse environment
   - [**Get-AdminPowerAppCdsDatabaseCurrencies**](https://docs.microsoft.com/en-us/powershell/module/microsoft.powerapps.administration.powershell/get-adminpowerappcdsdatabasecurrencies) (*Microsoft.PowerApps.Administration.PowerShell*) to get all the supported currencies for a specific location  for your Dataverse environment

#### Examples of command execution

- `New-DataverseEnvironment -DisplayName "Demonstration" -ConfigurationFilePath ".\DataverseEnvironmentConfiguration.txt"`
- `New-DataverseEnvironment -DisplayName "Demonstration" -ConfigurationFilePath ".\DataverseEnvironmentConfiguration.txt" -Sku "Production"`
- `New-DataverseEnvironment -DisplayName "Demonstration" -ConfigurationFilePath ".\DataverseEnvironmentConfiguration.txt" -Description "Demonstration"`
- `New-DataverseEnvironment -DisplayName "Demonstration" -ConfigurationFilePath ".\DataverseEnvironmentConfiguration.txt" -SecurityGroupId "00000000-0000-0000-0000-000000000000"`
- `New-DataverseEnvironment -DisplayName "Demonstration" -Description "Demonstration" -Sku "Sandbox" -SecurityGroupId "00000000-0000-0000-0000-000000000000" -ConfigurationFilePath ".\DataverseEnvironmentConfiguration.txt"`

#### DataverseEnvironmentConfiguration.txt

```
location=france
currencyName=EUR
languageCode=1033
templates=D365_Sales
```

### New-AzureAdAppRegistration

Create a new Azure AD app registration if it does not exist (*search based on the DisplayName provided*).

#### Persona: Azure AD administrator

User with at least the [**Application Administrator**](https://docs.microsoft.com/en-us/azure/active-directory/roles/permissions-reference#application-administrator) role in Azure AD.

#### Prerequisites

- You need to have the [**Azure CLI**](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed to be able to use this function
- The **New-AzureAdAppRegistration** function requires a manifest file. The **manifest.json** has been created with the API Permissions required for the setup of the **ALM Accelerator For Advanced Makers app**.
- You need to be authenticated using the [**az login**](https://docs.microsoft.com/en-us/cli/azure/reference-index?view=azure-cli-latest#az_login) (*Azure CLI*) command with a user account with at least the [Application Administrator](https://docs.microsoft.com/en-us/azure/active-directory/roles/permissions-reference#application-administrator) role in Azure AD to be able to use this function.

#### Examples of command execution

- `New-AzureAdAppRegistration -DisplayName "Demonstration" -ManifestPath .\manifest.json`
- `New-AzureAdAppRegistration -DisplayName "NewDemonstration" -AvailableToOtherTenants $true -ManifestPath .\manifest.json`

#### API permissions details

| API Name          | API ID                               | API Permission Name | API Permission ID                          |
| ----------------- | ------------------------------------ | ------------------- | ------------------------------------------ |
| Dynamics CRM      | 00000007-0000-0000-c000-000000000000 | user_impersonation  | 78ce3f0f-a1ce-49c2-8cde-64b5c0896db4=Scope |
| PowerApps-Advisor | c9299480-c13a-49db-a7ae-cdfe54fe0313 | Analysis.All        | d533b86d-8f67-45f0-b8bb-c0cee8da0356=Scope |
| Azure DevOps      | 499b84ac-1321-427f-aa17-267ca6975798 | user_impersonation  | ee69721e-6c3a-468f-a9ec-302d16a4c599=Scope |

#### Limitations

- This function does not currently configure a **Redirect URI** as requested in the step **14** of the [**SETUPGUIDE - Create an App Registration in your AAD Environment**](https://github.com/microsoft/coe-starter-kit/blob/main/ALMAcceleratorForAdvancedMakers/SETUPGUIDE.md#create-an-app-registration-in-your-aad-environment) step (*Note:* [*az ad app create ... --reply-urls ...*](https://docs.microsoft.com/en-us/cli/azure/ad/app?view=azure-cli-latest#az_ad_app_create))

### Install-AzureDevOpsExtensions

Install extensions in an Azure DevOps organization if they are not already installed.

#### Persona: Project Collection Administrators or Organization Owners

> Microsoft documentation page: [Install extensions - Prerequisites](https://docs.microsoft.com/en-us/azure/devops/marketplace/install-extension?view=azure-devops&tabs=browser#prerequisites)

To be able to execute this function, you will need, at least the **Project Collection Administrators** or **Organization Owners** role in the considered Azure DevOps organization.

#### Prerequisites

- You need to have the [**Azure CLI**](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed to be able to use this function
- The **Install-AzureDevOpsExtensions** function requires a file with the details of the extension to install. The **AzureDevOpsExtensionsDetails.json** has been created with the extensions required for the setup of the **ALM Accelerator For Advanced Makers app**.
- You need to be authenticated using the [**az login**](https://docs.microsoft.com/en-us/cli/azure/reference-index?view=azure-cli-latest#az_login) (*Azure CLI*) command with a user account with at least the **Project Collection Administrators** or **Organization Owners** role in the considered Azure DevOps organization to be able to use this function.

#### Examples of command execution

`Install-AzureDevOpsExtensions -OrganizationUrl "https://dev.azure.com/Demonstration" -ExtensionsFilePath .\AzureDevOpsExtensions.json`

#### Azure DevOps extensions details

| Search query                                                               | Publisher Name        | Publisher Id                         | Extension Name               | Extension Id                         |
| -------------------------------------------------------------------------- | --------------------- | ------------------------------------ | ---------------------------- | ------------------------------------ |
| `az devops extension search --search-query "PowerPlatform-BuildTools"`     | microsoft-IsvExpTools | b0208c9d-08ff-4cfb-93f7-f64e487561a6 | PowerPlatform-BuildTools     | 53aae833-dd77-4add-9b55-5e567c95417f |
| `az devops extension search --search-query "xrm-ci-framework-build-tasks"` | WaelHamze             | b6b5f3ed-43b6-4ff4-a7ad-86bb89af87d4 | xrm-ci-framework-build-tasks | 16fcf456-c1af-45d9-b17f-b5e312a1b258 |
| `az devops extension search --search-query "colinsalmcorner-buildtasks"`   | colinsalmcorner       | 6ab572e9-5b46-45b9-8e4c-001d34489be1 | colinsalmcorner-buildtasks   | 3ba967cd-d565-4e27-ab34-67091eb87998 |
| `az devops extension search --search-query "regexreplace-task"`            | knom                  | b5a17125-f7c5-4e15-9b95-ebac80539fac | regexreplace-task            | 6c5afea6-b92f-41e8-8fa0-a6ec2b21448d |
| `az devops extension search --search-query "variablehydration"`            | nkdagility            | e9689a60-f618-4d26-a565-a33e66955785 | variablehydration            | 49fe8e23-456c-4bb1-8369-e2d48bc39a4a |
| `az devops extension search --search-query "sariftoolsF`                   | sariftools            | 5b63d488-3794-468f-8239-d7bb125c6730 | scans                        | 16216759-1619-4451-8f8c-e6a2bf8476a2 |

### New-AzureDevOpsProject

Create an Azure DevOps project if it does not exist (*search based on the project name provided*).

#### Persona: Azure DevOps Project Collection Administrator

User member of the **Project Collection Administrators** group at the organization level, or with the **Create new projects** permission set to **Allow**.

#### Prerequisites

- You need to have the [**Azure CLI**](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed to be able to use this function
- The **New-AzureDevOpsProject** function requires a file with the details of the Azure DevOps project to create. You can use the **AzureDevOpsProjectConfiguration.txt** file as a template.

| Parameter     | Allowed values               |
| ------------- | ---------------------------- |
| process       | Scrum / Agile / Basic / CMMI |
| sourceControl | git / tfvc                   |
| visibility    | private / public             |

- You need to be authenticated using the [**az login**](https://docs.microsoft.com/en-us/cli/azure/reference-index?view=azure-cli-latest#az_login) (*Azure CLI*) command with a user account member of the **Project Collection Administrators** group at the organization level, or with the **Create new projects** permission set to **Allow**, to be able to use this function.

#### Examples of command execution

- `New-AzureDevOpsProject -OrganizationUrl "https://dev.azure.com/demonstration" -ProjectName "Demonstration" -ConfigurationFilePath ".\AzureDevOpsProjectConfiguration.txt"`
- `New-AzureDevOpsProject -OrganizationUrl "https://dev.azure.com/demonstration" -ProjectName "Demonstration" -ProjectDescription "Description of the project" -ConfigurationFilePath ".\AzureDevOpsProjectConfiguration.txt"`

### New-ApplicationUserInDataverseEnvironment

> This function does not work for now with PowerShell 7 (*Error when executing `Import-Module Microsoft.Xrm.Data.Powershell` command: Import-Module: Could not load type 'System.Management.Automation.PSSnapIn'*).

> You do not need to execute this function targeting a Dataverse environment created connected with the consider Azure AD application registration.

Create an application user in a Dataverse environment if it does exist (*search based on the Application ID provided*).

#### Persona: Dataverse environment system administrator

User with the **System administrator** security role in the targeted Dataverse environment.

#### Prerequisites

- You need to have the [**Microsoft.Xrm.Data.Powershell**](https://github.com/seanmcne/Microsoft.Xrm.Data.PowerShell) PowerShell module installed to be able to use this function
- You need to be authenticated using the [**connect-crmonline**](https://github.com/seanmcne/Microsoft.Xrm.Data.PowerShell#how-microsoftxrmdatapowershell-works) command with a user account with the **System Administrator** security role in the considered Dataverse environment

#### Examples of command execution

- `New-ApplicationUserInDataverseEnvironment -ApplicationId "00000000-0000-0000-0000-000000000000" -DataverseEnvironmentDomainName "demonstration"`
- `New-ApplicationUserInDataverseEnvironment -ApplicationId "00000000-0000-0000-0000-000000000000" -DataverseEnvironmentDomainName "demonstration" -SecurityRoleName "Solution Manager"`