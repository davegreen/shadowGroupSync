Function New-ShadowGroup
{
	[CmdletBinding()]
	param (
		[parameter()]
		[string]$Name
	)
	
	BEGIN{}
	PROCESS{}
	END{}
	
	<#

	.SYNOPSIS 
	
	Creates an Active Directory shadow group.
	
	.DESCRIPTION 
	
	The New-ADGroup cmdlet creates a new Active Directory group object. Many object properties 
	are defined by setting cmdlet parameters.
	
	.PARAMETER  <Parameter-Name>
	
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
