<#
  .Synopsis
  A PowerShell script that provides an easy way to manage Active Directory shadow groups.

  .Description
  A PowerShell script that provides an easy way to manage Active Directory shadow groups. This script requires the PowerShell Active Directory module from Microsoft.

  .Parameter File
  The location of the shadow group file to parse.

  .Example
  .\shadowGroupSync.ps1 -File "C:\path\to\csv"
  Run shadowGroupSync with the CSV as the source.

  .Notes
  Name  : shadowGroupSync
  Author: David Green

  .Link
  http://www.tookitaway.co.uk
  https://github.com/davegreen/shadowGroupSync.git
#>

#--CSV Format--
#Domain,ObjType,SourceOU,DestOU,GroupName,GroupType,Recurse,Description
#"contoso.com","computer","OU=A1,OU=A_Block,OU=Computers,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Block-A1","Security","SubTree","A Description"
#"contoso.com","computer","OU=A2,OU=A_Block,OU=Computers,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Block-A2","Security","SubTree"
#"contoso.com","computer","OU=A1,OU=A_Block,OU=Computers,DC=contoso,DC=com;OU=A2,OU=A_Block,OU=Computers,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Block-A1-A2","Security","Base"
#"contoso.com","user","OU=A1Users,OU=Users,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Users-A1","Distribution","SubTree","Another Description"
#"child.contoso.com","user-mail-enabled","OU=A2Users,DC=child,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Users-A2","Distribution","OneLevel",""

#Grab the CSV file from args
param(
    [parameter(
        Mandatory = $true,
        Position = 1,
        HelpMessage = 'The location of the shadowGroupSync definition CSV.'
    )]
    [string]
    $File
)

$csv = Import-Csv $File

#For logging, Run with: powershell.exe -command "c:\path\shadowGroupSync.ps1 -File c:\path\ShadowGroups.csv | tee -file ('c:\path\shadowGroupSync-'+ (Get-Date -format d.M.yyyy.HH.mm) + '.log')"
Import-Module ActiveDirectory -ErrorAction Stop

#Gets AD objects from the specified OU or OUs and returns the collection.
#Param1: $searchbase - The base OU DistinguishedName of to search for objects.
#        Multiples can be specified and chained together with a semicolon.
#        Example: "OU=Computers,DC=contoso,DC=com" or "OU=MainOffice,OU=Users,DC=contoso,DC=com;OU=OtherOffice,OU=Users,DC=contoso,DC=com"
#Param2: $domain - The domain or server to query for source objects.
#        Example: "contoso.com"
#Param3: $type - The type of search to do, the built in supported types can be seen below.
#        Example: "computer"
#Param4: $scope - The scope of the search for objects.
#        Example: 0 or "Base", 1 or "OneLevel", 2 or "SubTree"
Function Get-SourceObjects($searchbase, $domain, $type, $scope) {
    $multiobj = @()
    $obj = $null
    $bases = $searchbase.Split(";")

    #If the searchbase is an array of searchbases, recall the function, concatenate the results and pass back the complete set.
    if ($bases.Count -gt 1) {
        foreach ($base in $bases) {
            $multiobj += Get-SourceObjects $base $domain $type $scope
        }

        return $multiobj
    }
    else {
        Try {
            #You can add you own types here and reference them in the csv.
            #'$obj' must be a collection of AD objects with a Name and an ObjectGUID property.
            $obj = switch ($type) {
                "computer" { Get-ADComputer -Filter { Enabled -eq $true } -SearchBase $searchbase -SearchScope $scope -server $domain -ErrorAction Stop }
                "computer-name-valid" { Get-ADComputer -Filter { Name -match "^[a-z]{5}-[0-9]{5}$" } -SearchBase $searchbase -SearchScope $scope -server $domain -ErrorAction Stop }
                "user-mail-enabled" { Get-ADUser -Filter { Mail -like '*' -and Enabled -eq $true } -SearchBase $searchbase -SearchScope $scope -server $domain -ErrorAction Stop }
                { ($_ -eq "user") -or ($_ -eq "user-enabled") } { Get-ADUser -Filter { Enabled -eq $true } -SearchBase $searchbase -SearchScope $scope -server $domain -ErrorAction Stop }
                "user-disabled" { Get-ADUser -Filter { Enabled -eq $false } -SearchBase $searchbase -SearchScope $scope -server $domain -ErrorAction Stop }

                default {
                    Write-Error "Invalid type specified"
                    Exit
                }
            }
        }

        Catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
            Write-Warning "The OU $searchbase does not appear to exist."
        }

        Catch {
            Write-Error $_
            Exit
        }

        return $obj
    }
}

#Gets the members from the shadow group. If the group does not exist, create it.
#Param1: $groupname - The shadowgroup name to get members from.
#        Example: "ShadowGroup-1"
#Param2: $destou - The OU the shadowgroup exists in.
#        Example: "OU=ShadowGroups,DC=contoso,DC=com"
#Param3: $scope - The grouptype the shadowgroup should be created as (If it doesn't exist)
#        Example: 0 (Distribution) or 1 (Security)
Function Get-ShadowGroupMembers($groupname, $destou, $grouptype, $description) {
    $adgroup = Get-ADGroup -Filter { SamAccountName -eq $groupname } -Properties Description -SearchBase $destou
    if ( -not ($adgroup)) {
        #For use with Fine Grained Password Policies, the GroupScope should be Global.
        #If you are using this script with child domains, it may need to be set to Universal.
        New-ADGroup -Name $groupname -SamAccountName $groupname -Description $description -Path $destou -Groupcategory $grouptype -GroupScope Global
    }
    elseif ($adgroup.Description -ne $description) {
        Set-ADGroup -Identity $adgroup -Description $description
    }

    $groupmembers = Get-ADGroupMember -Identity $groupname
    return $groupmembers
}

#Adds the specified object to the group.
#Param1: $groupname - The shadowgroup to add the member to.
#        Example: "ShadowGroup-1"
#Param2: $member - The member to add to the shadowgroup, can be a SAMAccountName, ObjectGUID or an AD user object.
#        Example: "SmithJ" (SAMAccountName for John Smith)
Function Add-ShadowGroupMember($group, $member) {
    Try {
        Write-Verbose "Adding $($member.Name)"
        Add-ADGroupMember -Identity $group -Members $member.objectGUID -ErrorAction Stop
    }

    Catch {
        Write-Warning "Failed to add $member to group $group"
        Write-Error $_
    }
}

#Removes the specified object from the group.
#Param1: $groupname - The shadowgroup to remove the member from.
#        Example: "ShadowGroup-1"
#Param2: $member - The member to remove from the shadowgroup, can be a SAMAccountName, ObjectGUID or an AD user object.
#        Example: "SmithJ" (SAMAccountName for John Smith)
Function Remove-ShadowGroupMember($group, $member) {
    Try {
        Write-Verbose "Removing $($member.Name)"
        Remove-ADGroupMember -Identity $group -Members $member.objectGUID -Confirm:$false -ErrorAction Stop
    }

    Catch {
      Write-Warning "Failed to remove $member from group $group"
      Write-Error $_
    }
}

#Resolve the group category to be used with Get-ShadowGroupMembers, returns 1 for Security if unknown.
#Param1: $groupcategory - The group category to be used to create the group in Get-ShadowGroupMembers
#        Example: "Security"
Function Check-GroupCategory($groupcategory) {
    $category = switch ($groupcategory) {
        "Distribution" { 0 }
        "Security"     { 1 }
        default        { 1 }
    }

    return $category
}

#Resolve the search scope to be used with Get-SourceObjects, returns 2 for SubTree if unknown.
#Param1: $scope - The scope to be used to search for source objects in Get-SourceObjects
#        Example: 0 or "Base", 2 or "SubTree", etc.
Function Check-SourceScope($scope) {
    $s = switch ($scope) {
        { ($_ -eq "Base") -or ($_ -eq 0) }     { 0 }
        { ($_ -eq "OneLevel") -or ($_ -eq 1) } { 1 }
        { ($_ -eq "Subtree") -or ($_ -eq 2) }  { 2 }
        default                                { 2 }
    }

    return $s
}

#Confirm that the destination OU and Group can be created in the domain.
#Param1: $destou - The OU the shadowgroup should exist in.
#        Example: "OU=ShadowGroups,DC=contoso,DC=com"
#Param2: $groupname - The shadowgroup name to put members in.
#        Example: "ShadowGroup-1"
Function Confirm-Destination($destou, $groupname) {
    #Check that the destination OU exists, otherwise we won't be able to create the shadow group at all
    Try {
        Get-ADOrganizationalUnit -Identity $destou -ErrorAction Continue | Out-Null
    }

    Catch {
        if ($_.Exception.GetType().Name -eq "ADIdentityNotFoundException") {
            Write-Error "Skipping sync of $groupname, destination OU does not exist: $destou"
            return $false
        }

        else {
          throw
        }
    }

    #Check that a group with the same SAM Account Name as our destination group does not exist elsewhere in AD - this attribute must be unique within a domain
    $adGroup = Get-ADGroup -Filter {SamAccountName -eq $groupname} -ErrorAction Continue

    #If group already exists ensure it's in the expected OU
    if($adGroup -and (([string]([ADSI]"LDAP://$adgroup").PSBase.Parent.distinguishedName) -ne $destou)) {
        Write-Error "Skipping sync of $groupname, a group with the same SAM Account Name already exists in a different part of the hierarchy: $($adGroup.DistinguishedName)"
        return $false
    }

    return $true
}

#Iterate through the CSV and action each shadow group.
foreach ($cs in $csv) {
    Write-Debug $cs

    if ( -not (Confirm-Destination $cs.DestOU $cs.GroupName)) {
        continue
    }

    #Populate the source and destination set for comparison.
    $obj          = Get-SourceObjects $cs.SourceOU $cs.Domain $cs.ObjType (Check-SourceScope $cs.Recurse)
    $groupmembers = Get-ShadowGroupMembers $cs.Groupname $cs.Destou (Check-GroupCategory $cs.GroupType) $cs.Description

    #If the group is empty, populate the group.
    if ( -not ($groupmembers) -and ($obj)) {
        Write-Verbose "$($cs.GroupName) is empty"

        foreach ($o in $obj) {
            Add-ShadowGroupMember $cs.GroupName $o
        }
    }

    #If there are no members in the sync source, empty the group.
    elseif (($obj -eq $null) -and ($groupmembers)) {
        Write-Verbose "Emptying $($cs.GroupName)"

        foreach ($member in $groupmembers) {
          Remove-ShadowGroupMember $cs.GroupName $member
        }
    }

    #If the group has members, get the group members to mirror the OU contents.
    elseif (($groupmembers) -and ($obj)) {
        switch (Compare-Object -ReferenceObject $groupmembers -DifferenceObject $obj -property objectGUID, Name) {
            { $_.SideIndicator -eq "=>" } { Add-ShadowGroupMember $cs.GroupName $_ }
            { $_.SideIndicator -eq "<=" } { Remove-ShadowGroupMember $cs.GroupName $_ }
        }
    }

    Write-Verbose "$($cs.GroupName) sync complete."
}