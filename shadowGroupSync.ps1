#Author: Dave Green (david.green@tookitaway.co.uk)
#Version 4 - 25/10/2012

#--CSV Format--

#Domain,ObjType,SourceOU,DestOU,GroupName
#"contoso.com","computer","OU=A1,OU=A_Block,OU=Computers,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Block-A1"
#"contoso.com","computer","OU=A2,OU=A_Block,OU=Computers,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Block-A2"
#"contoso.com","computer","OU=A1,OU=A_Block,OU=Computers,DC=contoso,DC=com;OU=A2,OU=A_Block,OU=Computers,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Block-A1-A2"
#"contoso.com","user","OU=A1Users,OU=Users,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Users-A1"
#"child.contoso.com","mailuser","OU=A2Users,DC=child,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Users-A2"

param([string]$file)
$currentdir = Get-Location
$csvfound = $false
$csvfile = $null

#If this script is called as "C:\path\to\shadowGroupSync.ps1 -file 'C:\path\to\csv'", or a relative path to the csv.
if ($file -or $args[0])
{
  if (Test-Path -LiteralPath $file)
  {
    $csvfile = $file
    $csvfound = $true
  }

  #Alternatively, if the script is called as "./shadowGroupSync.ps1 'C:\path\to\csv'"
  elseif ((Test-Path -LiteralPath $args[0]) -and ($csvfound -eq $null))
  {
    $csvfile = $args[0]
    $csvfound = $true
  }

  if (($csvfile -eq $null) -and ($csvfound -eq $null))
  {
    Write-Output "Error: No CSV file has been specified."
    Write-Output "Usage: ./shadowGroupSync.ps1 'C:\path\to\csv' or C:\path\to\shadowGroupSync.ps1 -file 'C:\path\to\csv'"
    Exit
  }
}

else
{
  Write-Output "Error: No CSV file has been specified."
  Write-Output "Usage: ./shadowGroupSync.ps1 'C:\path\to\csv' or C:\path\to\shadowGroupSync.ps1 -file 'C:\path\to\csv'"
  Exit
}

$csv = Import-Csv $csvfile

#For logging, Run with: powershell.exe -file "c:\path\shadowGroupSync.ps1" | tee -file ('c:\path\log\shadowGroupSync-'+ (Get-Date -format d.M.yyyy.HH.mm) + '.log')
Import-Module ActiveDirectory -ErrorAction Stop

#Gets AD objects from the specified OU or OUs and returns the collection.
Function Get-SourceObjects($searchbase, $domain, $type)
{
  $obj = $null
  
  $bases = $searchbase.Split(";")
  #If the searchbase is an array of searchbases, recall the function, concatenate the results and pass back the complete set.
  if ($bases.Count -gt 1)
  {
    foreach ($base in $bases)
    {
      $multiobj += Get-SourceObjects $base $domain $type
    }
    return $multiobj
  }
  else
  {
    Try
    {
      #You can add you own types here and reference them in the csv.
      #'$obj' must be a collection of AD objects with a Name and an ObjectGUID property.
      switch ($type)
      {
        "computer" {$obj = Get-ADComputer -Filter {name -like '*' -and Enabled -eq $true} -SearchBase $searchbase -SearchScope 2 -server $domain -ErrorAction Stop}
        "mailuser" {$obj = Get-ADUser -Filter {Mail -like '*' -and Enabled -eq $true} -SearchBase $searchbase -SearchScope 2 -server $domain -ErrorAction Stop}
        "user" {$obj = Get-ADUser -Filter {Enabled -eq $true} -SearchBase $searchbase -SearchScope 2 -server $domain -ErrorAction Stop}
        default 
        {
          Write-Output "Invalid type specified"
          Exit
        }
      }
    }
  
    Catch
    {
      Write-Output ("Error:" + $_)
      Exit
    } 
    return $obj
  }
}

#Gets the members from the shadow group. If the group does not exist, create it.
Function Get-ShadowGroupMembers($groupname, $domain, $destou)
{
  if (!(Get-ADGroup -Filter {SamAccountName -eq $groupname} -SearchBase $destou -Server $domain))
  {
    #For use with Fine Grained Password Policies, the GroupScope should be Global.
    #If you are using this script with child domains, it may need to be set to Universal.
    New-ADGroup -Name $groupname -SamAccountName $groupname -Path $destou -Server $domain -Groupcategory Security -GroupScope Global
  }
  
  $groupmembers = Get-ADGroupMember -Identity $groupname -Server $domain
  return $groupmembers
}

#Adds the specified object to the group.
Function Add-ShadowGroupMember($domain, $group, $memberguid)
{
  Add-ADGroupMember -Identity $group -Member $memberguid -Server $domain
}

#Removes the specified object from the group.
Function Remove-ShadowGroupMember($domain, $group, $memberguid)
{
  Remove-ADGroupMember -Identity $group -Member $memberguid -Server $domain -Confirm:$false
}

#Iterate through the CSV and action each shadow group.
foreach ($cs in $csv)
{
  Write-Output ("`n--------------------------------------------------------`n")
  Write-Output $cs
  
  #Populate the source and destination set for comparison.
  $obj = Get-SourceObjects $cs.SourceOU $cs.Domain $cs.ObjType
  $groupmembers = Get-ShadowGroupMembers $cs.Groupname $cs.Domain $cs.Destou
  
  #If the group is empty, populate the group.
  if ((!$groupmembers) -and ($obj))
  {
    Write-Output ("Group """ + ($cs.GroupName) + """ is empty")
    foreach ($o in $obj)
    {
      Write-Output ("Adding " + $o.Name)
      Add-ShadowGroupMember $cs.Domain $cs.GroupName $o.objectGUID
    }
  }
  
  #If there are no members to sync, empty the group.
  elseif (($obj -eq $null) -and ($groupmembers))
  {
    foreach ($member in $groupmembers)
    {
      Write-Output ("Removing " + ($member.Name))
      Remove-ShadowGroupMember $cs.Domain $cs.GroupName $member.objectGUID
    }
  }
  
  #If the group has members, get the group members to mirror the OU contents.
  elseif (($groupmembers) -and ($obj))
  {
    switch (Compare-Object -ReferenceObject $groupmembers -DifferenceObject $obj -property objectGUID, Name)
    {
      {$_.SideIndicator -eq "=>"}
      {
        Write-Output ("Adding   " + ($_.Name))
        Add-ShadowGroupMember $cs.Domain $cs.GroupName $_.objectGUID
      }
      
      {$_.SideIndicator -eq "<="} 
      {
        Write-Output ("Removing " + ($_.Name))
        Remove-ShadowGroupMember $cs.Domain $cs.GroupName $_.objectGUID
      }
    }
  }
  
  Write-Output ("Sync for """ + ($cs.GroupName) + """ complete!`n")
}