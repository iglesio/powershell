<#
This PowerShell script gathers essential information about a computer for troubleshooting or inventory purposes. 

### Key Functions:
1. **Collects System Data**: Gathers information about the computer's hostname, username, domain, OS, BIOS, hardware, memory, logical disks, installed software, local users, and network configuration.
2. **Formats Disk Information**: Defines a function to calculate and format disk sizes and free space.
3. **Generates HTML Report**: Compiles the collected data into an HTML file for easy viewing and saves it to the user's Downloads folder.

### Use Case:
Useful for IT professionals needing to perform system audits or inventory management.

Author: Iglesio Santos
Version: 1.0
#>

#Global variables and CIM querys to collect information about the computer.
$hostname = $Env:COMPUTERNAME
$username = $Env:USERNAME 
$domain = $Env:USERDNSDOMAIN
$computer_system = Get-CimInstance -ClassName Win32_ComputerSystem
$os = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -expandproperty caption
$timezone = Get-CimInstance -ClassName Win32_TimeZone | Select-Object -expandproperty Caption
$date = Get-Date
$manufacturer = $computer_system.Manufacturer
$model = $computer_system.Model
$bios = Get-CimInstance -ClassName Win32_BIOS
$serial_number = $bios.SerialNumber
$bios_version = $bios.BIOSVersion -join " "
$processor = Get-CimInstance -ClassName Win32_processor | Select-Object -expandproperty name
$memory = Get-CimInstance -ClassName Win32_PhysicalMemory
$disks = Get-CimInstance -ClassName Win32_logicaldisk -filter "DriveType='3'" 
$softwares64 = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | ?{ $_.DisplayName -ne $null }
$softwares64 += Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | ?{ $_.DisplayName -ne $null }
$softwares32 = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | ?{ $_.DisplayName -ne $null } 
$softwares32 += Get-ItemProperty HKCU:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | ?{ $_.DisplayName -ne $null } 
$softwares = $softwares64 + $softwares32 | Sort-Object -Property DisplayName -Unique
$network = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | ?{ $_.IPAddress -ne $null} | Select-Object Description, IPAddress, IPSubnet, DNSServerSearchOrder, DefaultIPGateway, DHCPServer 
$local_users = Get-LocalUser

#Function to get the number of disks and calculate free space.
function get_disks{
    $disk_info = @()
    foreach ($disk in $disks){
        $disk_info += [PSCustomObject]@{
            Disk = $disk.DeviceID
            Size = "{0:N2} GB" -f [math]::round($disk.Size / 1GB, 2)
            FreeSpace = "{0:N2} GB" -f [math]::round($disk.FreeSpace / 1GB, 2)
            FreeSpacePercentage = "{0:N2} %" -f [math]::round($disk.FreeSpace / $disk.Size * 100, 2)
        }
    }
    return $disk_info
}

#Call functions and associate the results to the variables.
$total_disks = get_disks

#Save all the information to an HTML file.
$html_content = @"

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Inventory 2024</title>

<style>    
*{
font-family: Arial, Helvetica, sans-serif;
font-size: 15px;
}

.table {
  border-collapse: collapse;
  width: 100%;
}
.table td, .table th {
  border: 1px solid #ddd;
  padding: 8px;
}
  
.table tr:nth-child(even){background-color: #f2f2f2;}

.table tr:hover {background-color: #ddd;}

.table th{
  padding-top: 12px;
  padding-bottom: 12px;
  text-align: center;
  font-size: 18px;
  background-color: #96a1ad;
  color: white;
}

</style>
</head>
<body>
    <header>
    </header> 

    <main>
        <table class="table">
            <tr><th colspan=2>Operating System</th></tr>
            <tr><td width=20%><b>Hostname</b></td><td>$hostname</td></tr>
            <tr><td width=20%><b>Username</b></td><td>$username</td></tr>
            <tr><td width=20%><b>Domain</b></td><td>$domain</td></tr>
            <tr><td width=20%><b>OS</b></td><td>$os</td></tr>
            <tr><td width=20%><b>Timezone</b></td><td>$timezone</td></tr>
            <tr><td width=20%><b>Date</b></td><td>$date</td></tr>
        </table>
        <br/><br/>
        <table class="table">
            <tr><th colspan=2>BIOS/Hardware</th></tr>
            <tr><td width=20%><b>Manufacturer</b></td><td>$manufacturer</td></tr>
            <tr><td width=20%><b>Model</b></td><td>$model</td></tr>
            <tr><td width=20%><b>SerialNumber</b></td><td>$serial_number</td></tr>
            <tr><td width=20%><b>Bios Version</b></td><td>$bios_version</td></tr>
        </table>
        <br/><br/>
        <table class="table">
            <tr><th colspan=2>Processor</th></tr>
            $(
                $i = 1
                foreach ($cpu in $processor){
                    "<tr><td width=20%>Processor $($i)</td><td>$cpu</td></tr>"
                    $i++
                }
            )
        </table>
        <br/><br/>
        <table class="table">
            <tr><th colspan=2>Memory</th></tr>
            <tr><td><b>Slot</b></td><td><b>Capacity</b></td></tr>
            $(
                foreach ($mem in $memory){
                    "<tr><td width=20%>$($mem.Tag)</td><td>$($mem.Capacity / 1GB) GB</td></tr>"
                }
            )
            <tr><td><b>Total</b></td><td>$(($memory.Capacity | Measure-Object -Sum).Sum / 1GB) GB</td></tr>
        </table>
        <br/><br/>
        <table class="table">
            <tr><th colspan=4>Disks</th></tr>
            <tr><td><b>Disk</b></td><td><b>Size</b></td><td><b>FreeSpace</b></td><td><b>FreeSpacePercentage</b></td></tr>
            $(
                foreach ($disk in $total_disks){
                    "<tr><td>$($disk.Disk)</td><td>$($disk.Size)</td><td>$($disk.FreeSpace)</td><td>$($disk.FreeSpacePercentage)</td></tr>"
                }
            )
        </table>
        <br/><br/>
        <table class="table">
            <tr><th colspan=6>Network Interfaces</th></tr>
            <tr><td><b>Interface</b></td><td><b>IP Address</b></td><td><b>Subnet Mask</b></td><td><b>DNS Server</b></td><td><b>Default Gateway</b></td><td><b>DHCP Server</b></td></tr>
            $(
                foreach ($net in $network){
                    "<tr><td>$($net.Description)</td><td>$($net.IPAddress)</td><td>$($net.IPSubnet)</td><td>$($net.DNSServerSearchOrder)</td><td>$($net.DefaultIPGateway)</td><td>$($net.DHCPServer)</td></tr>"
                }
            )
        </table>
        <br/><br/>
        <table class="table">
            <tr><th colspan=3>Local Users</th></tr>
            <tr><td><b>User</b></td><td><b>Enabled</b></td><td><b>Description</b></td></tr>
            $(
                foreach ($user in $local_users){
                    "<tr><td>$($user.Name)</td><td>$($user.Enabled)</td><td>$($user.Description)</td></tr>"
                }
            )
        </table>
        <br/><br/>
        <table class="table">
            <tr><th colspan=2>Installed Softwares</th></tr>
            <tr><td><b>Name</b></td><td><b>Version</b></td></tr>
            $(
                foreach ($soft in $softwares){
                    "<tr><td width=40%>$($soft.DisplayName)</td><td>$($soft.DisplayVersion)</td></tr>"
                }
            )
        </table>        
    </main>

    <footer id="footer">
    </footer>
</body>
</html>
"@

$html_content | Out-File "$PSScriptRoot\$hostname.html"


