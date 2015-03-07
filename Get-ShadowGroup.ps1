Function Get-ShadowGroup
{
	[CmdletBinding(DefaultParameterSetName = "Filter")]
	param (
		[parameter(ParameterSetName ="Identity", Mandatory=$false, ValueFromPipeline=$true)]
		[Microsoft.ActiveDirectory.Management.ADGroup]$Identity,
		[parameter(ParameterSetName = "Filter", Mandatory=$true)]
		[string]$Filter,
		[parameter(ParameterSetName = "Filter", Mandatory=$false)]
		[string]$SearchBase = (Get-ADDomain).DistinguishedName,
		[parameter(Mandatory=$false)]
		[string]$Prefix = "SG_",
		[parameter(Mandatory=$false)]
		[string]$Properties
	)

    BEGIN
    {
        $Output = @()
    }

	PROCESS
	{
		$ADGroup = @()

		if ($PSCmdlet.ParameterSetName -eq "Identity")
		{
			if (!$Properties)
			{
				$ADGroup = Get-ADGroup $Identity
			}

			else
			{
				$ADGroup = Get-ADGroup $Identity -Properties $Properties
			}
		}

		else
		{
			if (!$Properties)
			{
				$ADGroup = Get-ADGroup -Filter $Filter -SearchBase $SearchBase
			}

			else
			{
				$ADGroup = Get-ADGroup -Filter $Filter -SearchBase $SearchBase -Properties $Properties
			}
		}
        
        $Output += $ADGroup | Where-Object {$_.Name -like "$Prefix*"}
	}

    END
    {
        Write-Output $Output
    }
    
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
	
	.PARAMETER -Identity <ADGroup>
	
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

	.PARAMETER -Filter <String>

	Specifies a query string that retrieves Active Directory objects. This string uses the PowerShell Expression Language syntax. The following examples show how to use this syntax with this cmdlet.

	To get all objects of the type specified by the cmdlet, use the asterisk wildcard:
		Get-ShadowGroup -Filter *

	To get all objects with a name containing the word 'Finance'
		Get-ShadowGroup -Filter {Name -like "*Finance*"}

	Note: PowerShell wildcards other than "*", such as "?" are not supported by the Filter syntax.

	.PARAMETER -SearchBase <DistinguishedName>

	Specifies an Active Directory path to search under.

	If this is not specified, the root of the domain is used for searches.

	The following example shows how to set this parameter to search under an OU.
		Get-ShadowGroup -Filter * -SearchBase "OU=Groups,DC=contoso,DC=com"

	.PARAMETER -Prefix <String>

	.PARAMETER -Properties <String[]>

	Specifies the properties of the output object to retrieve. Use this parameter to retrieve properties that are not included in the default set. Properties must be specified as a comma seperated list.
	To display all of the attributes that are set on the object, specify * (asterisk).

	The following example shows how to return the description property.
		Get-ShadowGroup -Filter * -Properties description

	.EXAMPLE
	
	.INPUTS
	
	None or Microsoft.ActiveDirectory.Management.ADGroup
	
	A group object is received by the Identity parameter.
	
	.OUTPUTS
	
	.NOTES

	Name  : Get-ShadowGroup
	Author: David Green (http://www.tookitaway.co.uk/, https://github.com/davegreen/shadowGroupSync.git)
	
	.LINK
	
	New-ShadowGroup
	Update-ShadowGroup
	Remove-ShadowGroup
	
	#>
}
