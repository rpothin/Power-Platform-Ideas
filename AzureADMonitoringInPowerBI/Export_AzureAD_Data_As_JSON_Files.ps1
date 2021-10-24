# Copyright (c) 2020 Raphael Pothin.
# Licensed under the MIT License.

# Login to azure (interactive)
Write-Host "Login - Start"
az login
Write-Host "Login - End"

# List Users
Write-Host "List Users - Start"
az ad user list | Out-File -FilePath .\AzureAD_Users.json
Write-Host "List Users - End"

# List Groups
Write-Host "List Groups - Start"
az ad group list | Out-File -FilePath .\AzureAD_Groups.json
Write-Host "List Groups - End"

# List Groups Owners & List Groups Members
Write-Host "List Groups Owners & Members - Start"
$groupsJson = az ad group list
$groups = $groupsJson | ConvertFrom-Json

## Initialize a variable to store the Groups Owners
$groupsOwnersJSON = @"
[
]
"@
$groupsOwners = $groupsOwnersJson | ConvertFrom-Json

## Initiliaze a variable to store the Groups Members
$groupsMembersJson = @"
[
]
"@
$groupsMembers = $groupsMembersJson | ConvertFrom-Json

## For all the Groups,
$groups.foreach(
    {
        ### Put the Group ID and the Group Display Name in variables
        $groupId = $_.objectId
        $groupName = $_.displayName

        ### Get the Group Owners
        $groupOwnersJson = az ad group owner list -g $groupId
        $groupOwners = $groupOwnersJson | ConvertFrom-Json

        ### Add each Group Owner to the "groupsOwners" variable
        $groupOwners | ForEach-Object -Begin $null -Process {$_ | Add-Member -NotePropertyName groupId -NotePropertyValue $groupId}, {$_ | Add-Member -NotePropertyName groupName -NotePropertyValue $groupName}, {$groupsOwners += $_} -End $null

        ### Get the Group Members
        $groupMembersJson = az ad group member list -g $groupId
        $groupMembers = $groupMembersJson | ConvertFrom-Json

        ### Add each Group Member to the "groupsMembers" variable
        $groupMembers | ForEach-Object -Begin $null -Process {$_ | Add-Member -NotePropertyName groupId -NotePropertyValue $groupId}, {$_ | Add-Member -NotePropertyName groupName -NotePropertyValue $groupName}, {$groupsMembers += $_} -End $null
    }
)

## Convert the variables to JSON
$groupsOwnersJson = $groupsOwners | ConvertTo-Json
$groupsMembersJson = $groupsMembers | ConvertTo-Json

## Create files with Groups Owners and Groups Members
$groupsOwnersJson | Out-File -FilePath .\AzureAD_GroupsOwners.json
$groupsMembersJson | Out-File -FilePath .\AzureAD_GroupsMembers.json
Write-Host "List Groups Owners & Members - End"

# List Apps
Write-Host "List Apps - Start"
az ad app list | Out-File -FilePath .\AzureAD_Apps.json
Write-Host "List Apps - End"

# List Service Principals
Write-Host "List Service Principals - Start"
az ad sp list --all | Out-File -FilePath .\AzureAD_ServicePrincipals.json
Write-Host "List Service Principals - End"

# List Service Principals Owners
Write-Host "List Service Principals Owners - Start"
$servicePrincipalsJson = az ad sp list --all
$servicePrincipals = $servicePrincipalsJson | ConvertFrom-Json

## Initiliaze a variable to store the Service Principals Owners
$servicePrincipalsOwnersJson = @"
[
]
"@
$servicePrincipalsOwners = $servicePrincipalsOwnersJson | ConvertFrom-Json

## For all the Service Principals,
$servicePrincipalsOwners.foreach(
    {
        ### Put the Service Principal ID and the Service Principal Display Name in variables
        $servicePrincipalId = $_.objectId
        $servicePrincipalName = $_.displayName

        ### Get the Service Principal Owners
        $servicePrincipalOwnersJson = az ad sp owner list --id $servicePrincipalId
        $servicePrincipalOwners = $servicePrincipalOwnersJson | ConvertFrom-Json

        ### Add each Service Principal Owner to the "servicePrincipalsOwners" variable
        $servicePrincipalOwners | ForEach-Object -Begin $null -Process {$_ | Add-Member -NotePropertyName servicePrincipalId -NotePropertyValue $servicePrincipalId}, {$_ | Add-Member -NotePropertyName servicePrincipalName -NotePropertyValue $servicePrincipalName}, {$servicePrincipalsOwners += $_} -End $null
    }
)

## Convert the "servicePrincipalsOwners" variable to JSON
$servicePrincipalsOwnersJson = $servicePrincipalsOwners | ConvertTo-Json

## Create a file with Service Principals Owners
$servicePrincipalsOwnersJson | Out-File -FilePath .\AzureAD_ServicePrincipalsOwners.json
Write-Host "List Service Principals Owners - End"