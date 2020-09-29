# Teams Creation Automation Solution (with Power Automate)

> **Important**
> This solution is not production ready, so it should not be used on a production environment without some tests.
> Moreover, it is an unmanaged solution and we all know we should not have unmanaged solutions in production 😉.

## Content of the Release package
* **README.md**: This README.md file
* **TeamsCreation.zip**: The unmanaged version of the solution
* **Source Code.zip**: Source Code in this GitHub repository as a zip file
* **Source Code.tar.gz**: Source Code in this GitHub repository as a tar.gz file

## Prerequisites

To be able to use this solution, you will need to register an application in Azure Active Directory in your tenant with the following **MS Graph** permissions:
* Group.ReadWrite.All
* Team.Create
* Team.ReadBasic.All
* TeamMember.ReadWrite.All
* User.ReadWrite.All

When the application is registered with those permissions, generate a **Client Secret**.

Be sure to keep the **Application (client) ID** and the **Client Secret** of the application you created somewhere safe, you will need during the configuration of the solution.

## Configuration of the solution

1. Download the **TeamsCreation.zip** file from the latest [**TeamsCreation Release**](https://github.com/rpothin/Power-Platform-Ideas/releases/tag/TeamsCreation_20200928_10)
2. Import it to the targeted environment
3. Open the **MS Graph - Teams** custom connector in the **Teams Creation** solution
4. Click on the **Edit** button
5. Go to the **Security** tab
6. Click on **Edit** in the **Authenticate type** section
7. Update the security information as described below:

   1. Client id = Application (client) ID of the application registered in the Prerequisites
   2. Client secret = Client Secret of the application registered in the Prerequisites
   3. Resource URL = https://graph.microsoft.com

8. Click on the **Update connector** button
9. Close the tab
10. Do the same steps (4 to 9) for the **MS Graph - Beta - Teams** custom connector
11. Open the **Clone a Team to create a new one** flow
12. Click on the **Edit** button
13. Update the actions with missing connection
14. Update the last action of the flow putting a existing user in your tenant
15. Click on the **Save** button
16. Go back to the overview page of the flow
17. Turn the flow on
18. Close the tab
19. Repeat the same steps (12 to 18) for the other flows in the solution: **Create an Office 365 Group and add a Team to it** and **Team Creation - Beta version**
20. Make a publish of all the customizations

## Test the flows in the solution

All the flows in the solution can be manually run.
To test the **Clone a Team to create a new one** flow, you will need the id of an existing template Team.
