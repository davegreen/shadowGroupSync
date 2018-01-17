shadowGroupSync
====================

Description
---------------------

A PowerShell script that provides an easy way to manage Active Directory shadow groups.
This script requires the [PowerShell Active Directory module](http://technet.microsoft.com/en-us/library/ee617195.aspx) from Microsoft.

### Features

- Sync user or computer objects from one or more OUs to a single group.
- Ability to filter objects included in the shadow group using the [PowerShell Active Directory Filter](http://technet.microsoft.com/en-us/library/hh531527).
- Ability to choose shadow group type (Security/Distribution).

Setting Up
---------------------

### Installing the Active Directory PowerShell Module

If you plan to run this script on a Server 2008 R2 or Server 2012 Domain Controller, the Active Directory PowerShell module should already be installed.

Alternatively, if you wish to run this script from a Server 2008 R2 or Server 2012 member server, you will need to install the ActiveDirectory PowerShell module first. To do this, run PowerShell as an Administrator, then run the following commands:

> Import-Module ServerManager

> Add-WindowsFeature RSAT-AD-PowerShell

If you are running Windows 7, the module can be installed with the [Microsoft Remote Server Administration Tools For Windows 7](http://www.microsoft.com/en-us/download/details.aspx?id=7887).
You will then need to enable it from:

> Control Panel -> Programs -> Turn Windows Features On or Off

You can also use the Add-WindowsFeature cmdlet as shown above.

With Windows 8, installing the [Microsoft Remote Server Administration Tools For Windows 8](http://www.microsoft.com/en-gb/download/details.aspx?id=28972) is enough, as all of the features are automatically enabled when the update is installed.

### [Enabling scripts in PowerShell](http://technet.microsoft.com/en-us/library/hh849812.aspx)

By default, PowerShell will not let you run scripts and will only work in interactive mode. In order to run the shadowGroupSync script from a local drive, you will need to alter this behaviour. To do this, run PowerShell as an Administrator, then run the following command:

> Set-ExecutionPolicy RemoteSigned

This will allow scripts that are stored locally and not signed by a trusted publisher to be run.

### Creating the CSV

Once you have downloaded the script, you will need to create the CSV file where you specify the shadow groups you want to create. Here is a sample CSV file:

> Domain,ObjType,SourceOU,DestOU,GroupName,GroupType,Recurse,Description
> "contoso.com","computer","OU=A1,OU=A_Block,OU=Computers,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Block-A1","Security","SubTree","A Description"
> "contoso.com","computer","OU=A2,OU=A_Block,OU=Computers,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Block-A2","Security","SubTree"
> "contoso.com","computer","OU=A1,OU=A_Block,OU=Computers,DC=contoso,DC=com;OU=A2,OU=A_Block,OU=Computers,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Block-A1-A2","Security","Base"
> "contoso.com","user","OU=A1Users,OU=Users,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Users-A1","Distribution","SubTree","Another Description"
> "child.contoso.com","user-mail-enabled","OU=A2Users,DC=child,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Users-A2","Distribution","OneLevel",""

- Domain specifies the domain to query for the source AD objects.
- ObjType is a query type that can be specified in the script to filter for objects. This can be easily extended in the script.
- SourceOU is the OU (or OUs, separated by a semicolon) to query for source objects for the shadow group.
- DestOU is the OU where you would like the shadow group to be created.
- GroupName specifies the name of the shadow group.
- GroupType specifies whether a Security or Distribution group will be created. The default is Security.
- Recurse specifies how to search the SourceOU for objects. [This can be "OneLevel" or "SubTree"](http://technet.microsoft.com/en-us/library/ee617241.aspx).
- Description is the description you'd like to give the group.

You can place the CSV file anywhere on the system, as long as the script can be told where to find it.

Usage
---------------------

You can run the script in a couple of ways. In most production environments, you can use a scheduled task to run the script.

### Standard
If you want to run the script normally, you can call the PowerShell script either with or without the '-file' argument.

> ./shadowGroupSync.ps1 'C:\path\to\csv'

> ./shadowGroupSync.ps1 -file 'C:\path\to\csv'

### With Logging
The following command will run the script and log the output to a specific directory.

PowerShell 3 (Windows Server 2012 and later).
> powershell.exe -NoProfile -ExecutionPolicy Bypass -command "c:\path\shadowGroupSync.ps1 -file c:\path\ShadowGroups.csv | tee -file ('c:\path\shadowGroupSync-'+ (Get-Date -format yyyy.M.d-HH.mm) + '.log')"

PowerShell 2 (Windows Server 2008 R2)
> powershell.exe -NoProfile -ExecutionPolicy Bypass -command ""c:\path\shadowGroupSync.ps1 -verbose -file "c:\path\ShadowGroups.csv" 2>&1 > "c:\path\shadowGroupSync.log"

### Scheduled Task

If running as a scheduled task, it is recommended to use a service account with limited privleges to the domain.
The following steps should produce the desired results:

1. Create a service account (i.e. `svcShadowGroups`)
  * Set a secure password that does not expire
2. Add the account to a `Service Accounts` security group
3. Add the account to a `Group Operators` security group
  * Give this group `Create/Delete Groups` permission to desired areas
  * Also give `List, Read, Write, Delete` permission to `Descendant Groups`
4. Add Group Policy to relevant servers/computers to allow `Run as` permissions
  * Under `Computer Configuration -> Windows Settings -> Security Settings -> Local Policies -> User Rights Assignment`:
  * Configure `Logon as a batch job` and 'Logon as a service' to include `Service Accounts`
  * It is also recommended to include Administrators and Backup Operators
5. Create a scheduled task on a server or computer
  * `Change User or Group` to service acconut
  * Run whether the user is logged on or not
  * Set triggers for desired schedule
  * Create an action to call script

It may be easiest to put the call to the script in a batch file and call the batch file from the scheduled task, as the task scheduler GUI doesn't do too well with PowerShell scripts.

### Note
If you are using this script with child domains, you may need to change the GroupScope of created shadow groups to Universal.

Contact
---------------------

For help, feedback, suggestions or bugfixes please check out [http://tookitaway.co.uk/](http://tookitaway.co.uk/) or contact david.green@tookitaway.co.uk.

Thanks
---------------------

- i3laze - Updated the script to deal with syncing mail-enabled users and child domains.
- Dmitry - Submitted a correction when using the script to generate groups for [Fine-Grained Password Policies](http://technet.microsoft.com/en-us/library/cc770394).
- Alex - Highlighted some bugs that needed fixing.
- inarius - Highlighted some compatibility issues.
- [wikijm](https://github.com/wikijm) - Idea to add description for each group.