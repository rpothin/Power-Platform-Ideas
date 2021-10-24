Function New-ApplicationUserInDataverseEnvironment {
    <#
        .SYNOPSIS
            Create a new application user in a Dataverse environment if it does not exist.

        .DESCRIPTION
            Search an application user environment with the application (client) ID provided.
            If no application user found, create a new one.

        .PARAMETER ApplicationId
            Specifies the application (client) ID of the Azure AD application registration you want to add as an application user in the considered Dataverse environment.

        .PARAMETER DataverseEnvironmentDomainName
            Specifies the domain name (part between the "https://" and the ".crmX.dynamics.com") of the considered Dataverse environment to verify we are connected to the right environment.

        .PARAMETER SecurityRoleName
            Specifies the security role name we want to assign to the application user we will create in the considered Dataverse environment.

        .INPUTS
            None. You cannot pipe objects to New-ApplicationUserInDataverseEnvironment.

        .OUTPUTS
            Object. New-ApplicationUserInDataverseEnvironment returns the details of the application user found or created.

        .EXAMPLE
            PS> New-ApplicationUserInDataverseEnvironment -ApplicationId "00000000-0000-0000-0000-000000000000" -DataverseEnvironmentDomainName "demonstration"
            ApplicationId                            : 00000000-0000-0000-0000-000000000000
            SystemUserId                             : 00000000-0000-0000-0000-000000000000
            Type                                     : Created

        .EXAMPLE
            PS> New-ApplicationUserInDataverseEnvironment -ApplicationId "00000000-0000-0000-0000-000000000000" -DataverseEnvironmentDomainName "demonstration"
            ApplicationId                            : 00000000-0000-0000-0000-000000000000
            SystemUserId                             : 00000000-0000-0000-0000-000000000000
            Type                                     : Existing

        .LINK
            README.md: https://github.com/microsoft/coe-starter-kit/tree/main/PowerPlatformDevOpsALM/SetupAutomation

        .NOTES
            * This function does not work for now whith PowerShell 7
            * You need to be authenticated using the "connect-crmonline" (Microsoft.Xrm.Data.PowerShell) command with an account with the "System Administrator" security role in the considered Dataverse environment to be able to use this function
            * The busniess unit considered for the assignment of the security role will be the one of the logged in account and should be the main business unit on the considered Dataverse environment
    #>

    [CmdletBinding()]
    Param (
        # Application ID associated to the application user to create
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ApplicationId,

        # Domain name of the considered Dataverse environment
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$DataverseEnvironmentDomainName,

        # Name of the security role to assigne to the application user
        [Parameter()]
        [String]$SecurityRoleName="System Administrator"
    )

    Begin{}

    Process{
        #region VariablesInitialization
        Write-Verbose "Variables initialization."

        # Create an appId variable of type "Guid" from the ApplicationId parameter value
        try {
            Write-Verbose "Try to convert the following ApplicationId parameter to a Guid variable: $ApplicationId"
            Write-Debug "Before the type convertion.."
            $appId = [Guid]$ApplicationId
        }
        catch {
            Write-Verbose "Error in the convertion of the following ApplicationId parameter to a Guid variable: $ApplicationId"
            $applicationUser = [PSCustomObject]@{
                Error = "Error in the convertion of the following ApplicationId parameter to a Guid variable: $ApplicationId"
            }
        }

        # Get the business unit ID of the of the account used to logged in
        Write-Verbose "Get the business unit ID of the of the account used to logged in"
        Write-Debug "Before the call to the Invoke-CrmWhoAmI command..."
        $businessUnitId = (Invoke-CrmWhoAmI).BusinessUnitId

        # Set Fetch query variable for the search of an existing application user
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

        $fetchApplicationUsers = $fetchApplicationUsers -F $ApplicationId

        # Set Fetch query variable for the search the security role details for the business unit of the account used to logged in
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

        $fetchSecurityRoles = $fetchSecurityRoles -F $SecurityRoleName, $businessUnitId

        #endregion VariablesInitialization

        # Continue if no convertion error on the ApplicationId parameter
        if ($applicationUser.Error -eq $null){
            # Verify that the targeted Dataverse environment is the one we are logged in
            Write-Verbose "Verification that we are logged in to the following Dataverse environment: $DataverseEnvironmentDomainName"
            Write-Debug "Before the call to the Get-CrmSystemSettings command..."
            $dataverseEnvironment = Get-CrmSystemSettings
            $dataverseEnvironmentName = $dataverseEnvironment.Name

            # Case we are logged in to the targeted Dataverse environment
            if ($dataverseEnvironmentName -eq $DataverseEnvironmentDomainName) {
                # Search for an existing application user with the application ID provided
                Write-Verbose "Search application user with the following application ID: $ApplicationId"
                Write-Debug "Before the call to the Get-CrmRecordsByFetch command..."
                $applicationUsers = Get-CrmRecordsByFetch -Fetch $fetchApplicationUsers

                # Case only one application user found for the provided application ID
                if ($applicationUsers.Count -eq 1) {
                    Write-Verbose "Only one application user found - Do nothing"
                    $applicationUser = [PSCustomObject]@{
                        ApplicationId = $applicationUsers.CrmRecords[0].applicationid.Guid
                        SystemUserId = $applicationUsers.CrmRecords[0].systemuserid.Guid
                        Type = "Existing"
                    }
                }

                # Case no application user found for the provided application ID
                if ($applicationUsers.Count -eq 0) {
                    Write-Verbose "Create a new application user for the following application ID: $ApplicationId"
                    try {
                        Write-Verbose "Try to call the New-CrmRecord command."
                        Write-Debug "Before the call to the New-CrmRecord command..."
                        $userId= New-CrmRecord -EntityLogicalName systemuser -Fields @{
                            "applicationid"=$appId;
                            "businessunitid"=(New-CrmEntityReference -Id $businessUnitId -EntityLogicalName systemuser)
                        } -ErrorVariable applicationUserCreationError -ErrorAction Stop

                        $applicationUser = [PSCustomObject]@{
                            ApplicationId = $ApplicationId
                            SystemUserId = $userId.Guid
                        }
                    }
                    catch {
                        Write-Verbose "Error in the creation of the new application user for the following ApplicationId: $ApplicationId"
                        $applicationUser = [PSCustomObject]@{
                            Error = "Error in the creation of the new application user: $applicationUserCreationError"
                        }
                    }

                    # Continue to security role assignment if no error in the creation of the application user
                    if ($applicationUser.Error -eq $null){
                        # Search for security role in the business unit of the application user
                        Write-Verbose "Search security role with the following information: SecurityRoleName is $SecurityRoleName and BusinessUnitId is $businessUnitId"
                        Write-Debug "Before the call to the Get-CrmRecordsByFetch command..."
                        $securityRoles = Get-CrmRecordsByFetch -Fetch $fetchSecurityRoles

                        if ($securityRoles.Count -eq 1) {
                            $securityRoleId = $securityRoles.CrmRecords[0].roleid.Guid

                            Write-Verbose "Assign the $SecurityRoleName security role in the context of the $businessUnitId business unit to the new application user"
                            try {
                                Write-Verbose "Try to call the Add-CrmSecurityRoleToUser command."
                                Write-Debug "Before the call to the Add-CrmSecurityRoleToUser command..."
                                Add-CrmSecurityRoleToUser -UserId $userId -SecurityRoleId $securityRoleId -ErrorVariable securityRoleAssignmentError -ErrorAction Stop

                                $applicationUser | Add-Member -MemberType NoteProperty -Name "Type" -Value "Created"
                            }
                            catch {
                                Write-Verbose "Error in the assignemnt of the $SecurityRoleName security role to the new application user."
                                $applicationUser = [PSCustomObject]@{
                                    Error = "Error in the assignemnt of the security role to the new application user: $securityRoleAssignmentError"
                                }
                            }
                        }
                        elseif ($securityRoles.Count -eq 0) {
                            Write-Verbose "No security role found with the following information: SecurityRoleName is $SecurityRoleName and BusinessUnitId is $businessUnitId"
                            $applicationUser = [PSCustomObject]@{
                                Error = "No security role found with the following information: SecurityRoleName is $SecurityRoleName and BusinessUnitId is $businessUnitId"
                            }
                        }
                        else {
                            Write-Verbose "More than one security role found with the following information: SecurityRoleName is $SecurityRoleName and BusinessUnitId is $businessUnitId"
                            $applicationUser = [PSCustomObject]@{
                                Error = "More than one security role found with the following information: SecurityRoleName is $SecurityRoleName and BusinessUnitId is $businessUnitId"
                            }
                        }
                    }
                }

                # Case multiple application users found for the provided application ID
                if ($applicationUsers.Count -gt 1) {
                    Write-Verbose "Multiple application users found for the following application ID: $ApplicationId"
                    $applicationUser = [PSCustomObject]@{
                        Error = "Multiple application users found for the following application ID: $ApplicationId"
                    }
                }
            }

            # Case we are not logged in to the targeted Dataverse environment
            else {
                Write-Verbose "Logged in to $dataverseEnvironmentName Dataverse environment - Targeted environment: $DataverseEnvironmentDomainName"
                $applicationUser = [PSCustomObject]@{
                    Error = "Logged in to $dataverseEnvironmentName Dataverse environment - Targeted environment: $DataverseEnvironmentDomainName"
                }
            }
        }

        # Return the considered application user (found or created)
        Write-Verbose "Return the application user found or created."
        Write-Debug "Before sending the output..."
        $applicationUser
    }

    End{}
}