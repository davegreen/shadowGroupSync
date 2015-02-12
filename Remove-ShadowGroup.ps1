Function Remove-ShadowGroup
{
	[CmdletBinding()]
	param (
		[parameter(ValueFromPipeline=$true,
		ValueFromPipelineByPropertyName=$true)]
		[string]$Identity
	)
	
	BEGIN{}
	PROCESS{}
	END{}
	
	<#

	.SYNOPSIS 
	
	Removes an Active Directory shadow group.
	
	.DESCRIPTION
	
	.PARAMETER  <Parameter-Name>
	
	.EXAMPLE
	
	.INPUTS
	
	.OUTPUTS
	
	.NOTES

    Name  : Remove-ShadowGroup
    Author: David Green (http://www.tookitaway.co.uk/, https://github.com/davegreen/shadowGroupSync.git)
    
	.LINK
	
    New-ShadowGroup
    Get-ShadowGroup
    Update-ShadowGroup
    
	#>
}
