Function New-ShadowGroup
{
	[CmdletBinding()]
	param (
		[parameter(ValueFromPipeline=$true,
		ValueFromPipelineByPropertyName=$true)]
		[Microsoft.ActiveDirectory.Management.ADGroup]$Identity
	)
	
	BEGIN{}
	PROCESS{}
	END{}
	
	<#

	.SYNOPSIS 
	
	Gets one or more Active Directory shadow groups.
	
	.DESCRIPTION 
	
	The Get-ShadowGroup cmdlet gets a shadow group or performs a search to retrieve multiple 
	shadow groups from an Active Directory.
	
	The Identity parameter specifies the shadow group to get. This is done in the same 
	way as the Get-ADGroup cmdlet in the Microsoft ActiveDirectory module. 
	
	You can identify a group by its distinguished name (DN), GUID, security identifier (SID), 
	Security Accounts Manager (SAM) account name, or canonical name. You can also specify group 
	object variable, such as $<localGroupObject>. This method of getting a group is identical to 
	the Get-ADGroup cmdlet in the Microsoft ActiveDirectory module, as this is a prerequisite.
	
	.PARAMETER  -Identity <ADGroup>
	
	Specifies an Active Directory group object by providing one of the following values. 
	The identifier in parentheses is the LDAP display name for the attribute.

	Distinguished Name (distinguishedName)
		Example: CN=examplegroup,OU=groups,DC=contoso,DC=com
	GUID (objectGUID)
		Example: 88fb5b65-6a57-45ca-9803-87a48cfe7352
	Security Identifier (objectSid)
		Example: S-1-5-21-450053616-922836960-1990678075-13371
	Security Accounts Manager (SAM) Account Name (sAMAccountName)
		Example: examplegroup
	
	.EXAMPLE
	
	.INPUTS
    
    None or Microsoft.ActiveDirectory.Management.ADGroup
    
    A group object is received by the Identity parameter.
	
	.OUTPUTS
	
	.NOTES

    Name  : New-ShadowGroup
    Author: David Green (http://www.tookitaway.co.uk/, https://github.com/davegreen/shadowGroupSync.git)
    
	.LINK
	
    Get-ShadowGroup
    Update-ShadowGroup
    Remove-ShadowGroup
    
	#>
}
