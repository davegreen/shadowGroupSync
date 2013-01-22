Readme - shadowGroupSync
====================

Description
---------------------

A PowerShell script that provides an easy way to manage Active Directory shadow groups. 
This script requires the [Active Directory PowerShell module](http://technet.microsoft.com/en-us/library/ee617195.aspx) from Microsoft.

### Features

- Sync user or computer objects from one or more OUs to a single group.
- Ability to filter objects included in the shadow group using the [PowerShell AD object filter](http://technet.microsoft.com/en-us/library/hh531527).
- Ability to choose shadow group type (Security/Distribution).
- Supports child domains.

Setting Up
---------------------

### Installing the Active Directory PowerShell Module

If you plan to run this script on a Server 2008R2 Domain Controller, the Active Directory PowerShell module should already be installed.

Alternatively, if you wish to run this script from a Server 2008R2 member server, you will need to install the AD-PowerShell module first. To do this, run PowerShell as an Administrator, then run the following two commands:

> Import-Module ServerManager

> Add-WindowsFeature RSAT-AD-PowerShell

Finally, if you are running Windows 7, the module can be installed with the [Microsoft Remote Server Administration Tools](http://www.microsoft.com/en-us/download/details.aspx?id=7887). You will then need to enable it from 'Control Panel -> Programs -> Turn Windows Features On or Off'.

### [Enabling scripts in PowerShell](http://technet.microsoft.com/en-us/library/hh849812.aspx)

By default, PowerShell will not let you run scripts and will only work in interactive mode. In order to run the shadowGroupSync script, you will need to alter this behaviour. To do this, run PowerShell as an Administrator, then run the following command:

> Set-ExecutionPolicy RemoteSigned

### Creating the CSV

Once you have downloaded the script, you will need to create the CSV file where you specify the shadow groups you want to create. Here is a sample CSV file:

> Domain,ObjType,SourceOU,DestOU,GroupName,GroupType
> "contoso.com","computer","OU=A1,OU=A_Block,OU=Computers,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Block-A1","Security"
> "contoso.com","computer","OU=A2,OU=A_Block,OU=Computers,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Block-A2","Security"
> "contoso.com","computer","OU=A1,OU=A_Block,OU=Computers,DC=contoso,DC=com;OU=A2,OU=A_Block,OU=Computers,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Block-A1-A2","Security"
> "contoso.com","user","OU=A1Users,OU=Users,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Users-A1","Distribution"
> "child.contoso.com","mailuser","OU=A2Users,DC=child,DC=contoso,DC=com","OU=ShadowGroups,DC=contoso,DC=com","Users-A2","Distribution"

- Domain specifies the domain to query for the source AD objects.
- ObjType is a query type that can be specified in the script to filter for objects.
- SourceOU is the OU (or OUs, separated by a semicolon) to query for source objects for the shadow group.
- DestOU is the OU where you would like the shadow group to be created.
- GroupName specifies the name of the shadow group.
- GroupType specifies the type of group to create (Security/Distribution)

You can place the CSV file anywhere on the system, as long as the script can be told where to find it.

Usage
---------------------

You can run the script in a couple of ways. In most production environments, you can use a scheduled task to run the script.

The following command will run the script and log the output to a specific directory.
> powershell.exe -file "c:\path\shadowGroupSync.ps1" | tee -file ('c:\path\log\shadowGroupSync-'+ (Get-Date -format d.M.yyyy.HH.mm) + '.log')

If you want to run the script normally, you can call the PowerShell script either with or without the '-file' argument.

> ./shadowGroupSync.ps1 'C:\path\to\csv'

> ./shadowGroupSync.ps1 -file 'C:\path\to\csv'

### Note
If you are using this script with child domains, you may need to change the GroupScope of created shadow groups to Universal.

Contact
---------------------

For help, feedback, suggestions or bugfixes please check out [http://tookitaway.co.uk/](http://tookitaway.co.uk/) or contact david.green@tookitaway.co.uk.

Thanks
---------------------

- i3laze - Updated the script to deal with syncing mail-enabled users and child domains.
- Dmitry - Submitted a correction when using the script to generate groups for [Fine-Grained Password Policies](http://technet.microsoft.com/en-us/library/cc770394).