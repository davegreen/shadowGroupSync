Readme - shadowGroupSync
====================

Description
---------------------

A PowerShell script that provides an easy way to manage Active Directory shadow groups. 
This script requires the [Active Directory PowerShell module](http://technet.microsoft.com/en-us/library/ee617195.aspx) from Microsoft. 

If you are running Windows 7, this can be installed with the [Microsoft Remote Server Administration Tools](http://www.microsoft.com/en-us/download/details.aspx?id=7887).

Usage
---------------------

You can run the script in a couple of ways. In most production environments, you can use a scheduled task to run the script.

The following command will run the script and log the output to a specific directory.
> powershell.exe -file "c:\path\shadowGroupSync.ps1" | tee -file ('c:\path\log\shadowGroupSync-'+ (Get-Date -format d.M.yyyy.HH.mm) + '.log')

If you want to run the script normally, you can call the PowerShell script either with or without the '-file' argument.

> ./shadowGroupSync.ps1 'C:\path\to\csv'

> ./shadowGroupSync.ps1 -file 'C:\path\to\csv'

Contact
---------------------

For help, feedback, suggestions or bugfixes please check out [http://tookitaway.co.uk/](http://tookitaway.co.uk/) or contact david.green@tookitaway.co.uk.

Thanks
---------------------

Thanks to i3laze (i3laze 'at' yandex 'dot' ru), who provided an update to deal with syncing mail-enabled users and child domains.