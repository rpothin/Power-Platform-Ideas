The **AzureADMonitoringInPowerBi** contains elements to generate a Power BI report with data exported from Azure Active Directory.

# How to use this solution
## Prerequisites

To build this Power BI report, you will need
- an account with read permissions on the Azure AD of the considered tenant
- Azure CLI installed

## Quick configuration guide

1. Execute the **Export_AzureAD_Data_As_JSON_Files.ps1** PowerShell script
2. Check the files generated in the **AzureAD_Data** folder
3. Open the **AzureAD_Monitoring.pbix** in Power BI Desktop
4. In the Power Query Editor, udpate the value of the **AzureAD_Data_Folder_Absolute_Path** query with the absolute path to the **AzureAD_Data** folder (ex: `C:\YourPath\Power-Platform-Ideas\AzureADMonitoringInPowerBI\AzureAD_Data\`)
5. Apply the changes, verify the result and save your report