# ----------------------------------------------------------------------------
# |             Batch folder creation + ACL application                      |
# |                                                                          |
# |     AUTHOR  : Nahim "Naam" EL ATMANI                                     |
# |     CONTACT : naam92160@gmail.com                                        |
# |     LISCENCE: GPL-V2                                                     |
# |                                                                          |
# ----------------------------------------------------------------------------
# The script create folder and apply ACL policies to it, it takes one input
# file as first parameter and read line by line to get folder name.
# The second argument is the destination path that will contain the new
# folders.

if ($args.length -ne 2) {
echo "Usage ./script <user list> <dest folder>"
echo "Example: ./script ""C:\provision\list.ext"" ""C:\temp\"""
exit
}
echo "Please wait..."
# Using .NET reader for reading the user list
$reader=[System.IO.File]::OpenText($args[0])
# Proper user identification using ActiveDirectory. If userlist are already
# like DOMAIN\User please disable the following line:
$domain="AD\"
# File used for log output.
$logfile=".\report.log"
# http://msdn.microsoft.com/fr-fr/library/system.security.accesscontrol.filesystemrights.aspx
$colRights = [System.Security.AccessControl.FileSystemRights]"Traverse, ListDirectory, ReadAttributes, ReadExtendedAttributes, CreateFiles, Read, WriteData, CreateDirectories, AppendData, WriteAttributes, WriteExtendedAttributes, DeleteSubdirectoriesAndFiles"
$InheritanceFlag = [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"
$PropagationFlag =  [system.security.accesscontrol.PropagationFlags]::InheritOnly
$objType = [System.Security.AccessControl.AccessControlType]::Allow
try {
    for(;;) {
        $line = $reader.ReadLine()
        if ($line -eq $null) { break }
        $folder=$args[1] + $line
        New-Item -Path $folder -ItemType "directory" -force | Out-Null
        $usr=$domain + $line
        "$folder created, applying ACL..." >> $logfile
        $objACE = New-Object System.Security.AccessControl.FileSystemAccessRule($usr, $colRights, $InheritanceFlag, $PropagationFlag, $objType)
        $objACL = Get-Acl -Path $folder
        $objACL.AddAccessRule($objACE)
        Set-Acl -Path $folder -AclObject $ObjACL
        $objACE >> $logfile
    }
}
finally {
    $reader.Close()
}
echo "Done"
