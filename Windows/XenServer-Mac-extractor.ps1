# ----------------------------------------------------------------------------
# |             MAC address extractor for VMs under Xen hypervisor           |
# |                                                                          |
# |     AUTHOR  : Nahim "Naam" EL ATMANI                                     |
# |     CONTACT : naam92160@gmail.com                                        |
# |     LISCENCE: GPL-V2                                                     |
# |                                                                          |
# ----------------------------------------------------------------------------
# XenServer MAC extractor let you extract VM's MAC address from an IP range
# of XenServer Hypervisor

if ($args.length -ne 1) {echo "Example Usage: ./extract_mac XX.XX.XX.1[-255]";  exit} # proper splitting to go
if ( (Get-PSSnapIn -Name "XenServerPSSnapIn" -ErrorAction SilentlyContinue) -eq $Null ) {
        Add-PSSnapIn XenServerPSSnapIn
        } 
# Specify the root user on the next line if different
[string]$xenserver_username = "root"
[string]$xenserver_credential_path = "C:\Temp\xen_credential.pwd"
if ((Test-Path -Path $xenserver_credential_path) -eq $False) {
    (Get-Credential).Password | ConvertFrom-SecureString | Out-File $xenserver_credential_path
}
$xenserver_password = cat $xenserver_credential_path | ConvertTo-SecureString
$xenserver_credential = New-Object -Typename System.Management.Automation.PSCredential -ArgumentList $xenserver_username, $xenserver_password
$base=$args[0].split('.')
$range=$base[$base.length - 1].split('-')
$start=[int]$range[0]
if ($range.length -eq 2) {
    $stop=[int]$range[1]
} else {
    $stop=$start
}
$address=$base[0] + "." + $base[1] + "." + $base[2] + "."
for(;$start -le $stop; $start++) {
    $current = $address + $start
    Connect-XenServer -Server $current -Creds $xenserver_credential -SetDefaultSession
    [array]$vms=Get-XenVM | ? {$_.is_a_snapshot -eq $false -and $_.is_a_template -eq $false -and $_.is_control_domain -eq $false}
    foreach($vm in $vms) {
        $name=$vm."name_label"
        [array]$vifs = $vm."VIFs"
        echo "-------------------------------------------------"
        echo $name
        foreach($vif in $vifs) {
            $xvif=Get-XenVIF | ? {$_.opaque_ref -match $vif."opaque_ref" }
            $mac_label=$xvif."MAC"
            $netw_obj=Get-XenNetwork | ? {$_.opaque_ref -match ($xvif."network")."opaque_ref"}
            $netw_label=$netw_obj."name_label"
            echo "$mac_label ($netw_label)"
        }
    }
    Get-XenSession -Server $current | Disconnect-XenServer
}
