<#
This PowerShell script gathers essential information about a computer for troubleshooting or inventory purposes. 
Author: Iglesio Santos
Version: 1.0
#>

#Global variables and CIM querys to collect information about the computer.
$Hostname = $Env:COMPUTERNAME
$Username = $Env:USERNAME 
$Domain = $Env:USERDNSDOMAIN
$ComputerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
$Os = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -expandproperty caption
$Timezone = Get-CimInstance -ClassName Win32_TimeZone | Select-Object -expandproperty Caption
$Date = Get-Date
$Manufacturer = $ComputerSystem.Manufacturer
$Model = $ComputerSystem.Model
$Bios = Get-CimInstance -ClassName Win32_BIOS
$SerialNumber = $Bios.SerialNumber
$BiosVersion = $Bios.BIOSVersion -join " "
$Processor = Get-CimInstance -ClassName Win32_processor | Select-Object -expandproperty name
$Memory = Get-CimInstance -ClassName Win32_PhysicalMemory
$Disks = Get-CimInstance -ClassName Win32_logicaldisk -filter "DriveType='3'" 
$Softwares64 = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | ?{ $_.DisplayName -ne $null }
$Softwares64 += Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* | ?{ $_.DisplayName -ne $null }
$Softwares32 = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | ?{ $_.DisplayName -ne $null } 
$Softwares32 += Get-ItemProperty HKCU:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | ?{ $_.DisplayName -ne $null } 
$Softwares = $Softwares64 + $Softwares32 | Sort-Object -Property DisplayName -Unique
$Network = Get-CimInstance -ClassName Win32_NetworkAdapterConfiguration | ?{ $_.IPAddress -ne $null} | Select-Object Description, IPAddress, IPSubnet, DNSServerSearchOrder, DefaultIPGateway, DHCPServer 
$LocalUsers = Get-LocalUser
$LocalGroups = Get-LocalGroup
$Services = Get-CimInstance -ClassName Win32_Service | Select-Object Caption, StartMode, State, StartName | Sort-Object -Property Caption

#Function to get the number of disks and calculate free space.
function GetDisks{
    $DiskInfo = @()
    foreach ($Disk in $Disks){
        $DiskInfo += [PSCustomObject]@{
            Disk = $Disk.DeviceID
            Size = "{0:N2} GB" -f [math]::round($Disk.Size / 1GB, 2)
            FreeSpace = "{0:N2} GB" -f [math]::round($Disk.FreeSpace / 1GB, 2)
            FreeSpacePercentage = "{0:N2} %" -f [math]::round($Disk.FreeSpace / $Disk.Size * 100, 2)
        }
    }
    return $DiskInfo
}

#Function to get members of local groups
function GetGroups{
    Param (
        [string]$User
    )
    $UsersMembership = @()
    foreach ($Group in $LocalGroups){
        $GetMember = Get-LocalGroupMember -Group $Group | Where-Object { $_.Name -like "*$($User)" }
        if ($GetMember){
            $UsersMembership += $Group.Name
        } 
    }
    return $UsersMembership -join ', '
}

#Save all the information to an HTML file.
$HtmlContent = @"

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
color: #302c29;
}

header h1{
  text-align: center;
  font-size: 34px;
}

.table {
  border-collapse: collapse;
  width: 100%;
  margin-top: 40px;
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
  background-color: #c6cfcf;
  color: #302c29;
}

</style>
</head>
<body>
    <header>
        <h1>Inventory $($Date.Year)</h1>
    </header> 

    <main>
        <table class="table">
            <tr><th colspan=2>Operating System</th></tr>
            <tr><td width=20%><b>Hostname</b></td><td>$Hostname</td></tr>
            <tr><td width=20%><b>Username</b></td><td>$Username</td></tr>
            <tr><td width=20%><b>Domain</b></td><td>$Domain</td></tr>
            <tr><td width=20%><b>OS</b></td><td>$Os</td></tr>
            <tr><td width=20%><b>Timezone</b></td><td>$Timezone</td></tr>
            <tr><td width=20%><b>Date</b></td><td>$Date</td></tr>
        </table>
        
        <table class="table">
            <tr><th colspan=2>BIOS/Hardware</th></tr>
            <tr><td width=20%><b>Manufacturer</b></td><td>$Manufacturer</td></tr>
            <tr><td width=20%><b>Model</b></td><td>$Model</td></tr>
            <tr><td width=20%><b>SerialNumber</b></td><td>$SerialNumber</td></tr>
            <tr><td width=20%><b>Bios Version</b></td><td>$BiosVersion</td></tr>
        </table>
        
        <table class="table">
            <tr><th colspan=2>Processor</th></tr>
            $(
                $i = 1
                foreach ($Cpu in $Processor){
                    "<tr><td width=20%>Processor $($i)</td><td>$Cpu</td></tr>"
                    $i++
                }
            )
        </table>
        
        <table class="table">
            <tr><th colspan=2>Memory</th></tr>
            <tr><td><b>Slot</b></td><td><b>Capacity</b></td></tr>
            $(
                foreach ($Mem in $Memory){
                    "<tr><td width=20%>$($Mem.Tag)</td><td>$($Mem.Capacity / 1GB) GB</td></tr>"
                }
            )
            <tr><td><b>Total</b></td><td>$(($Memory.Capacity | Measure-Object -Sum).Sum / 1GB) GB</td></tr>
        </table>
        
        <table class="table">
            <tr><th colspan=4>Disks</th></tr>
            <tr><td><b>Disk</b></td><td><b>Size</b></td><td><b>FreeSpace</b></td><td><b>FreeSpacePercentage</b></td></tr>
            $(
                foreach ($Disk in GetDisks){
                    "<tr><td>$($Disk.Disk)</td><td>$($Disk.Size)</td><td>$($Disk.FreeSpace)</td><td>$($Disk.FreeSpacePercentage)</td></tr>"
                }
            )
        </table>
        
        <table class="table">
            <tr><th colspan=6>Network Interfaces</th></tr>
            <tr><td><b>Interface</b></td><td><b>IP Address</b></td><td><b>Subnet Mask</b></td><td><b>DNS Server</b></td><td><b>Default Gateway</b></td><td><b>DHCP Server</b></td></tr>
            $(
                foreach ($Net in $Network){
                    "<tr><td>$($Net.Description)</td><td>$($Net.IPAddress -join ', ')</td><td>$($Net.IPSubnet -join ', ')</td><td>$($Net.DNSServerSearchOrder -join ', ')</td><td>$($Net.DefaultIPGateway)</td><td>$($Net.DHCPServer)</td></tr>"
                }
            )
        </table>
        
        <table class="table">
            <tr><th colspan=4>Local Users</th></tr>
            <tr><td><b>User</b></td><td><b>Enabled</b></td><td><b>Description</b></td><td><b>Groups</b></td></tr>
            $(
                foreach ($User in $LocalUsers){
                    "<tr><td>$($User.Name)</td><td>$($User.Enabled)</td><td>$($User.Description)</td><td>$(GetGroups -user $User.Name)</td></tr>"
                }
            )
        </table>
        
        <table class="table">
            <tr><th colspan=2>Installed Softwares</th></tr>
            <tr><td><b>Name</b></td><td><b>Version</b></td></tr>
            $(
                foreach ($Soft in $Softwares){
                    "<tr><td width=40%>$($Soft.DisplayName)</td><td>$($Soft.DisplayVersion)</td></tr>"
                }
            )
        </table>
        
        <table class="table">
            <tr><th colspan=4>Services</th></tr>
            <tr><td><b>Service Name</b></td><td><b>Status</b></td><td><b>Startup</b></td><td><b>Startup User</b></td></tr>
            $(
                foreach ($Service in $Services){
                    "<tr><td width=40%>$($Service.Caption)</td><td>$($Service.State)</td><td>$($Service.StartMode)</td><td>$($Service.StartName)</td></tr>"
                }
            )
        </table>         
    </main>

    <footer id="footer">
    </footer>
</body>
</html>
"@

$HtmlContent | Out-File "$PSScriptRoot\$hostname.html"


