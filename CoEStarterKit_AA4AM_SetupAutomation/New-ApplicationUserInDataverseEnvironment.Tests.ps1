BeforeAll {
    # Import Microsoft.Xrm.Data.Powershell module
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    Install-Module Microsoft.Xrm.Data.PowerShell -Scope CurrentUser -Force

    # Import New-ApplicationUserInDataverseEnvironment function
    Import-Module .\New-ApplicationUserInDataverseEnvironment.ps1 -Force
}

# New-ApplicationUserInDataverseEnvironment tests without integrations with other modules
Describe "New-ApplicationUserInDataverseEnvironment Unit Tests" -Tag "UnitTests" {
    Context "Parameters configuration verification" {
        It "Given the Mandatory attribute of the ApplicationId parameter, it should be equal to true" {
            (Get-Command New-ApplicationUserInDataverseEnvironment).Parameters['ApplicationId'].Attributes.Mandatory | Should -Be $true
        }

        It "Given the Mandatory attribute of the DataverseEnvironmentDomainName parameter, it should be equal to true" {
            (Get-Command New-ApplicationUserInDataverseEnvironment).Parameters['DataverseEnvironmentDomainName'].Attributes.Mandatory | Should -Be $true
        }
    }

    Context "Behavior verification regarding Dataverse environment verification results" {
        BeforeEach{
            # Simulate the behavior of the execution of the 'Invoke-CrmWhoAmI' command
            $crmWhoAmIOutputMock = [PSCustomObject]@{
                BusinessUnitId = "00000000-0000-0000-0000-000000000000"
            }

            Mock Invoke-CrmWhoAmI { $crmWhoAmIOutputMock }

            # Simulate the behavior of the execution of the 'Get-CrmSystemSettings' command
            $crmSystemSettingsOutputMock = [PSCustomObject]@{
                Name = "demonstration"
            }

            Mock Get-CrmSystemSettings { $crmSystemSettingsOutputMock }

            # Simulate the behavior of the execution of the 'Get-CrmRecordsByFetch' command for application users
            $fetchApplicationUsers = @"
<fetch version="1.0" output-format="xml-platform" mapping="logical" distinct="false" no-lock="true">
    <entity name="systemuser">
        <attribute name="applicationid" />
        <filter type="and">
            <condition attribute="applicationid" operator="eq" value="{0}" />
        </filter>
    </entity>
</fetch>
"@

            $fetchApplicationOneUserMock = $fetchApplicationUsers -F "00000000-0000-0000-0000-000000000001"
            
            $getApplicationUsersOneUserOutputMock = [PSCustomObject]@{
                CrmRecords = @()
                Count = 1
            }
            $onlyApplicationUser = [PSCustomObject]@{}
            $onlyApplicationUserApplicationId = [PSCustomObject]@{
                Guid = "00000000-0000-0000-0000-000000000001"
            }
            $onlyApplicationUserSystemuserId = [PSCustomObject]@{
                Guid = "00000000-0000-1000-0000-000000000000"
            }
            $onlyApplicationUser | Add-Member -MemberType NoteProperty -Name "applicationid" -Value $onlyApplicationUserApplicationId
            $onlyApplicationUser | Add-Member -MemberType NoteProperty -Name "systemuserid" -Value $onlyApplicationUserSystemuserId
            $getApplicationUsersOneUserOutputMock.CrmRecords += $onlyApplicationUser
            
            Mock Get-CrmRecordsByFetch { $getApplicationUsersOneUserOutputMock } -ParameterFilter { $Fetch -eq $fetchApplicationOneUserMock }

            # Definition of the exepcted results of the tests of the this context
            $expectedResultExistingApplicationUserFound = [PSCustomObject]@{
                ApplicationId = "00000000-0000-0000-0000-000000000001"
                SystemUserId = "00000000-0000-1000-0000-000000000000"
                Type = "Existing"
            }

            $expectedResultMultipleApplicationUsersFound = [PSCustomObject]@{
                Error = "Logged in to demonstration Dataverse environment - Targeted environment: wrongEnvironment"
            }
        }

        It "Given a Dataverse environment domain name corresponding to the environment the user is logged in and an application id associated to an existing application user, it should return the information of the existing application user" {
            (New-ApplicationUserInDataverseEnvironment -ApplicationId "00000000-0000-0000-0000-000000000001" -DataverseEnvironmentDomainName "demonstration" | ConvertTo-Json) | Should -Be ($expectedResultExistingApplicationUserFound | ConvertTo-Json)
        }

        It "Given a Dataverse environment domain name not corresponding to the environment the user is logged in and an application id associated to an existing application user, it should return an error indicating inconsistency in environments" {
            (New-ApplicationUserInDataverseEnvironment -ApplicationId "00000000-0000-0000-0000-000000000001" -DataverseEnvironmentDomainName "wrongEnvironment" | ConvertTo-Json) | Should -Be ($expectedResultMultipleApplicationUsersFound | ConvertTo-Json)
        }
    }

    Context "Behavior verification regarding application users search results" {
        BeforeEach{
            # Simulate the behavior of the execution of the 'Invoke-CrmWhoAmI' command
            $crmWhoAmIOutputMock = [PSCustomObject]@{
                BusinessUnitId = "00000000-0000-0000-0000-000000000000"
            }

            Mock Invoke-CrmWhoAmI { $crmWhoAmIOutputMock }

            # Simulate the behavior of the execution of the 'Get-CrmSystemSettings' command
            $crmSystemSettingsOutputMock = [PSCustomObject]@{
                Name = "demonstration"
            }

            Mock Get-CrmSystemSettings { $crmSystemSettingsOutputMock }

            # Simulate the behavior of the execution of the 'Get-CrmRecordsByFetch' command for application users
            $fetchApplicationUsers = @"
<fetch version="1.0" output-format="xml-platform" mapping="logical" distinct="false" no-lock="true">
    <entity name="systemuser">
        <attribute name="applicationid" />
        <filter type="and">
            <condition attribute="applicationid" operator="eq" value="{0}" />
        </filter>
    </entity>
</fetch>
"@

            $fetchApplicationNoUserMock = $fetchApplicationUsers -F "00000000-0000-0000-0000-000000000000"
            $fetchApplicationOneUserMock = $fetchApplicationUsers -F "00000000-0000-0000-0000-000000000001"
            $applicationIdMutipleUsersMock = "00000000-0000-0000-0000-000000000002"
            $fetchApplicationMultipleUsersMock = $fetchApplicationUsers -F $applicationIdMutipleUsersMock

            $getApplicationUsersNoUserOutputMock = [PSCustomObject]@{
                Count = 0
            }

            $getApplicationUsersOneUserOutputMock = [PSCustomObject]@{
                CrmRecords = @()
                Count = 1
            }
            $onlyApplicationUser = [PSCustomObject]@{}
            $onlyApplicationUserApplicationId = [PSCustomObject]@{
                Guid = "00000000-0000-0000-0000-000000000001"
            }
            $onlyApplicationUserSystemuserId = [PSCustomObject]@{
                Guid = "00000000-0000-1000-0000-000000000000"
            }
            $onlyApplicationUser | Add-Member -MemberType NoteProperty -Name "applicationid" -Value $onlyApplicationUserApplicationId
            $onlyApplicationUser | Add-Member -MemberType NoteProperty -Name "systemuserid" -Value $onlyApplicationUserSystemuserId
            $getApplicationUsersOneUserOutputMock.CrmRecords += $onlyApplicationUser
            
            $getApplicationUsersMultipleUsersOutputMock = [PSCustomObject]@{
                Count = 2
            }

            Mock Get-CrmRecordsByFetch { $getApplicationUsersNoUserOutputMock } -ParameterFilter { $Fetch -eq $fetchApplicationNoUserMock }
            Mock Get-CrmRecordsByFetch { $getApplicationUsersOneUserOutputMock } -ParameterFilter { $Fetch -eq $fetchApplicationOneUserMock }
            Mock Get-CrmRecordsByFetch { $getApplicationUsersMultipleUsersOutputMock } -ParameterFilter { $Fetch -eq $fetchApplicationMultipleUsersMock }

            # Simulate the behavior of the execution of the 'New-CrmRecord' command
            $applicationUserCreatedMock = [PSCustomObject]@{
                Guid = "10000000-0000-0000-0000-000000000000"
            }
            
            Mock New-CrmRecord { $applicationUserCreatedMock }
            
            # Simulate the behavior of the execution of the 'Get-CrmRecordsByFetch' command for security roles
            $fetchSecurityRoles = @"
<fetch version="1.0" output-format="xml-platform" mapping="logical" distinct="false" no-lock="true">
    <entity name="role">
        <attribute name="roleid" />
        <filter type="and">
            <condition attribute="name" operator="eq" value="{0}" />
            <condition attribute="businessunitid" operator="eq" value="{1}" />
        </filter>
    </entity>
</fetch>
"@

            $fetchSecurityRoles = $fetchSecurityRoles -F "System Administrator", $crmWhoAmIOutputMock.BusinessUnitId

            $getSecurityRolesOutputMock = [PSCustomObject]@{
                CrmRecords = @()
                Count = 1
            }
            $onlySecurityRole = [PSCustomObject]@{}
            $onlySecurityRoleRoleId = [PSCustomObject]@{
                Guid = "00000000-1000-0000-0000-000000000000"
            }
            $onlySecurityRole | Add-Member -MemberType NoteProperty -Name "roleid" -Value $onlySecurityRoleRoleId
            $getSecurityRolesOutputMock.CrmRecords += $onlySecurityRole
            
            Mock Get-CrmRecordsByFetch { $getSecurityRolesOutputMock } -ParameterFilter { $Fetch -eq $fetchSecurityRoles }

            # Simulate the behavior of the execution of the 'Add-CrmSecurityRoleToUser' command
            Mock Add-CrmSecurityRoleToUser { }

            # Definition of the exepcted results of the tests of the this context
            $expectedResultExistingApplicationUserFound = [PSCustomObject]@{
                ApplicationId = "00000000-0000-0000-0000-000000000001"
                SystemUserId = "00000000-0000-1000-0000-000000000000"
                Type = "Existing"
            }

            $expectedResultNoApplicationUserFound = [PSCustomObject]@{
                ApplicationId = "00000000-0000-0000-0000-000000000000"
                SystemUserId = "10000000-0000-0000-0000-000000000000"
                Type = "Created"
            }


            $expectedResultMultipleApplicationUsersFound = [PSCustomObject]@{
                Error = "Multiple application users found for the following application ID: $applicationIdMutipleUsersMock"
            }
        }

        It "Given an application Id with an existing application user, it should return the information of the existing application user" {
            (New-ApplicationUserInDataverseEnvironment -ApplicationId "00000000-0000-0000-0000-000000000001" -DataverseEnvironmentDomainName "demonstration" | ConvertTo-Json) | Should -Be ($expectedResultExistingApplicationUserFound | ConvertTo-Json)
        }

        It "Given an application Id without an existing application user, it should return the information of the created application user" {
            (New-ApplicationUserInDataverseEnvironment -ApplicationId "00000000-0000-0000-0000-000000000000" -DataverseEnvironmentDomainName "demonstration" | ConvertTo-Json) | Should -Be ($expectedResultNoApplicationUserFound | ConvertTo-Json)
        }

        It "Given an application Id with multiple existing application users, it should return an error for mutliple application users found" {
            (New-ApplicationUserInDataverseEnvironment -ApplicationId "00000000-0000-0000-0000-000000000002" -DataverseEnvironmentDomainName "demonstration" | ConvertTo-Json) | Should -Be ($expectedResultMultipleApplicationUsersFound | ConvertTo-Json)
        }
    }

    Context "Behavior verification regarding security roles search results" {
        BeforeEach{
            # Simulate the behavior of the execution of the 'Invoke-CrmWhoAmI' command
            $crmWhoAmIOutputMock = [PSCustomObject]@{
                BusinessUnitId = "00000000-0000-0000-0000-000000000000"
            }
            $businessUnitId = $crmWhoAmIOutputMock.BusinessUnitId

            Mock Invoke-CrmWhoAmI { $crmWhoAmIOutputMock }

            # Simulate the behavior of the execution of the 'Get-CrmSystemSettings' command
            $crmSystemSettingsOutputMock = [PSCustomObject]@{
                Name = "demonstration"
            }

            Mock Get-CrmSystemSettings { $crmSystemSettingsOutputMock }

            # Simulate the behavior of the execution of the 'Get-CrmRecordsByFetch' command for application users
            $fetchApplicationUsers = @"
<fetch version="1.0" output-format="xml-platform" mapping="logical" distinct="false" no-lock="true">
    <entity name="systemuser">
        <attribute name="applicationid" />
        <filter type="and">
            <condition attribute="applicationid" operator="eq" value="{0}" />
        </filter>
    </entity>
</fetch>
"@

            $fetchApplicationNoUserMock = $fetchApplicationUsers -F "00000000-0000-0000-0000-000000000000"

            $getApplicationUsersNoUserOutputMock = [PSCustomObject]@{
                Count = 0
            }

            Mock Get-CrmRecordsByFetch { $getApplicationUsersNoUserOutputMock } -ParameterFilter { $Fetch -eq $fetchApplicationNoUserMock }

            # Simulate the behavior of the execution of the 'New-CrmRecord' command
            $applicationUserCreatedMock = [PSCustomObject]@{
                Guid = "10000000-0000-0000-0000-000000000000"
            }
            
            Mock New-CrmRecord { $applicationUserCreatedMock }
            
            # Simulate the behavior of the execution of the 'Get-CrmRecordsByFetch' command for security roles
            $fetchSecurityRoles = @"
<fetch version="1.0" output-format="xml-platform" mapping="logical" distinct="false" no-lock="true">
    <entity name="role">
        <attribute name="roleid" />
        <filter type="and">
            <condition attribute="name" operator="eq" value="{0}" />
            <condition attribute="businessunitid" operator="eq" value="{1}" />
        </filter>
    </entity>
</fetch>
"@

            $fetchSecurityRolesOneResultMock = $fetchSecurityRoles -F "System Administrator", $businessUnitId
            $securityRoleNoResultMock = "System Administrator0"
            $fetchSecurityRolesNoResultMock = $fetchSecurityRoles -F $securityRoleNoResultMock, $businessUnitId
            $securityRoleMultipleResultsMock = "System Administrator2"
            $fetchSecurityRolesManyResultsMock = $fetchSecurityRoles -F $securityRoleMultipleResultsMock, $businessUnitId

            $getSecurityRolesOneResultOutputMock = [PSCustomObject]@{
                CrmRecords = @()
                Count = 1
            }
            $onlySecurityRole = [PSCustomObject]@{}
            $onlySecurityRoleRoleId = [PSCustomObject]@{
                Guid = "00000000-1000-0000-0000-000000000000"
            }
            $onlySecurityRole | Add-Member -MemberType NoteProperty -Name "roleid" -Value $onlySecurityRoleRoleId
            $getSecurityRolesOneResultOutputMock.CrmRecords += $onlySecurityRole
            
            $getSecurityRolesNoResultOutputMock = [PSCustomObject]@{
                Count = 0
            }
            
            $getSecurityRolesManyResultsOutputMock = [PSCustomObject]@{
                Count = 2
            }

            Mock Get-CrmRecordsByFetch { $getSecurityRolesOneResultOutputMock } -ParameterFilter { $Fetch -eq $fetchSecurityRoles }
            Mock Get-CrmRecordsByFetch { $getSecurityRolesNoResultOutputMock } -ParameterFilter { $Fetch -eq $fetchSecurityRolesNoResultMock }
            Mock Get-CrmRecordsByFetch { $getSecurityRolesManyResultsOutputMock } -ParameterFilter { $Fetch -eq $fetchSecurityRolesManyResultsMock }

            # Simulate the behavior of the execution of the 'Add-CrmSecurityRoleToUser' command
            Mock Add-CrmSecurityRoleToUser { }

            # Definition of the exepcted results of the tests of the this context
            $expectedResultSecurityRoleFound = [PSCustomObject]@{
                ApplicationId = "00000000-0000-0000-0000-000000000000"
                SystemUserId = "10000000-0000-0000-0000-000000000000"
                Type = "Created"
            }

            $expectedResultNoSecurityRoleFound = [PSCustomObject]@{
                Error = "No security role found with the following information: SecurityRoleName is $securityRoleNoResultMock and BusinessUnitId is $businessUnitId"
            }

            $expectedResultMutipleSecurityRolesFound = [PSCustomObject]@{
                Error = "More than one security role found with the following information: SecurityRoleName is $securityRoleMultipleResultsMock and BusinessUnitId is $businessUnitId"
            }
        }

        It "Given an application Id without an existing application user and only one security role found, it should return the information of the existing application user" {
            (New-ApplicationUserInDataverseEnvironment -ApplicationId "00000000-0000-0000-0000-000000000000" -DataverseEnvironmentDomainName "demonstration" -SecurityRoleName "System Administrator" | ConvertTo-Json) | Should -Be ($expectedResultSecurityRoleFound | ConvertTo-Json)
        }

        It "Given an application Id without an existing application user and no security role found, it should return an error for no security role found" {
            (New-ApplicationUserInDataverseEnvironment -ApplicationId "00000000-0000-0000-0000-000000000000" -DataverseEnvironmentDomainName "demonstration" -SecurityRoleName "System Administrator0" | ConvertTo-Json) | Should -Be ($expectedResultNoSecurityRoleFound | ConvertTo-Json)
        }

        It "Given an application Id without an existing application user and multiple security roles found, it should return an error for multiple security roles found" {
            (New-ApplicationUserInDataverseEnvironment -ApplicationId "00000000-0000-0000-0000-000000000000" -DataverseEnvironmentDomainName "demonstration" -SecurityRoleName "System Administrator2" | ConvertTo-Json) | Should -Be ($expectedResultMutipleSecurityRolesFound | ConvertTo-Json)
        }
    }
}

# New-ApplicationUserInDataverseEnvironment tests with integrations with other modules
#   Prerequisites: to execute the following tests you need to
#       - be authenticated using the 'connect-crmonline' command
#       - to have a $ApplicationId initialized with a valid application registration ID
#       - to have a $DataverseEnvironmentDomainName initialized with a valid application Dataverse environment domain name
Describe "New-ApplicationUserInDataverseEnvironment Integration Tests" -Tag "IntegrationTests" {
    Context "Integration tests with the commands of the Microsoft.Xrm.Data.Powershell module" {
        BeforeEach{
            # Init variables
            $incorrectFormatApplicationId = "test"
            $unknownApplicationId = "00000000-0000-0000-0000-000000000000"
    
            # Definition of the exepcted results of the tests of the this context
            $expectedResultWrongApplicationId = [PSCustomObject]@{
                Error = "Error in the convertion of the following ApplicationId parameter to a Guid variable: $incorrectFormatApplicationId"
            }
            
            $expectedResultUnknowApplicationId = [PSCustomObject]@{
                Error = "Error in the creation of the new application user: ************ FaultException1 - Create : systemuser |=> We didnt find that application ID $unknownApplicationId in your Azure Active Directory"
            }
        }
            
        It "Given a wrong formatted application Id, it should return an error regarding the convertion of the application id parameter to the Guid format" {
            (New-ApplicationUserInDataverseEnvironment -ApplicationId $incorrectFormatApplicationId -DataverseEnvironmentDomainName $DataverseEnvironmentDomainName | ConvertTo-Json) | Should -Be ($expectedResultWrongApplicationId | ConvertTo-Json)
        }
            
        It "Given an unknown application Id, it should return an error about the fact the application Id is unknown in Azure AD" {
            (New-ApplicationUserInDataverseEnvironment -ApplicationId $unknownApplicationId -DataverseEnvironmentDomainName $DataverseEnvironmentDomainName).Error.Substring(0,209).Replace('`', '').Remove(113,1) | Should -Be $expectedResultUnknowApplicationId.Error
        }
            
        It "Given a correct application Id of a non existing application user and a correct Dataverse environment domain name, it should return the information of the new application user created" {
            $newApplicationUser = New-ApplicationUserInDataverseEnvironment -ApplicationId $ApplicationId -DataverseEnvironmentDomainName $DataverseEnvironmentDomainName
            
            $newApplicationUser.ApplicationId | Should -Be $ApplicationId
            $newApplicationUser.SystemUserId | Should -Not -BeNullOrEmpty
            $newApplicationUser.Type | Should -Be "Created"
        }
            
        It "Given a correct application Id of an existing application user and a correct Dataverse environment domain name, it should return the information of the new application user created" {
            $newApplicationUser = New-ApplicationUserInDataverseEnvironment -ApplicationId $ApplicationId -DataverseEnvironmentDomainName $DataverseEnvironmentDomainName
            
            $newApplicationUser.ApplicationId | Should -Be $ApplicationId
            $newApplicationUser.SystemUserId | Should -Not -BeNullOrEmpty
            $newApplicationUser.Type | Should -Be "Existing"
        }
    }
}