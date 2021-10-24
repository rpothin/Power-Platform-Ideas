# Azure DevOps Custom Connector

The **PowerPlatformDevOpsStarterKit_1_0_0.zip** contains only a custom connector with the following actions:
- List all the projects in an organization
- List all the service endpoints in a project
- Create a Power Platform service endpoint
- Get the details of a service endpoint
- Delete a service endpoint
- Enable a service endpoint for all the pipelines

# How to use this solution
## Prerequisites

To use this solution you will need:
- A Power Platform environment with a Dataverse database
- An Authorized OAuth App in Azure DevOps

To register an **Authorized OAuth App** in Azure DevOps follow the steps below:
1. Open the [Register (Azure DevOps) application](https://aex.dev.azure.com/app/register/) page
2. Complete the form (example below)
   - Company Name: Demo Corp.
   - Application name: AzureDevOps_App_For_PowerAutomate
   - Application website: https://www.gooogle.com
   - Authorization callback URL (*this one is important*): https://global.consent.azure-apim.net/redirect
3. For the **Authorized scopes**, you should select everything, because I do not really no wich option allows to enable a service endpoint for all pipelines
4. Save the following informations somewhere safe, you will need them for the configuration of the custom connector
    - URL of your app page: https://aex.dev.azure.com/app/view?clientId=<AppID>
    - ID of your application
    - Client Secret
    - Authorized Scopes

## Quick installation guide

1. Import the **PowerPlatformDevOpsStarterKit_1_0_0.zip** solution
2. Open the **Azure DevOps Service Endpoints** custom connector
3. Click on **Edit**
4. Go to the **Security** tab
5. In the **Client id** field enter the **App ID** of your **Authorized OAuth App**
6. In the **Client secret** field enter the **Client Secret** of your **Authorized OAuth App**
7. In the **Scope** field enter the **Authorized Scopes** of your **Authorized OAuth App**
8. Click on **Update connector**
9. Go to the **Test** tab
10. Click on **+ New connection** and verify you are able to create a connection

# Details about some actions
## Create a Power Platform service endpoint

- **URL:** https://dev.azure.com/{organization}/{project}/_apis/serviceendpoint/endpoints?api-version=6.0-preview.4
- **Verb:** POST
- **Request body for the creation of a Power Platform service endpoint:**

```
{
  "administratorsGroup": null,
  "authorization": {
    "scheme": "None",
    "parameters": {
      "tenantId": "<TenantId>",
      "applicationId": "<ApplicationId>",
      "clientSecret": "<ClientSecret>"
    }
  },
  "createdBy": null,
  "data": {},
  "description": "",
  "groupScopeId": null,
  "name": "<ServiceEndpointName>",
  "operationStatus": null,
  "readersGroup": null,
  "serviceEndpointProjectReferences": [
    {
      "description": "",
      "name": "<ServiceEndpointName>",
      "projectReference": {
        "id": "<ProjectId>",
        "name": "<ProjectName>"
      }
    }
  ],
  "type": "powerplatform-spn",
  "url": "<PowerPlatformEnvironmentURL>",
  "isShared": false,
  "owner": "library"
}
```
## Enable a service endpoint for all the pipelines

- **URL:** https://dev.azure.com/{organisation}/{project}/_apis/build/authorizedresources?api-version=5.0-preview.1
- **Verb:** POST
- **Request body to enable a service endpoint for all the pipelines:**

```
[
  {
    "type": "endpoint",
    "id": "<ServiceEndpointID>",
    "authorized": true
  }
]
```

## Delete a service endpoint

- **api-version:** 4.1-preview.1
- **Content-Type:** application/json