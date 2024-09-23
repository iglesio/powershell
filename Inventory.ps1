<#
This powershell script collects information about a computer and export this information on a report in HTML.
#>

#CIM querys to collect information about the computer.
$computersystem = Get-CimInstance -ClassName Win32_ComputerSystem
$hostname = $computersystem.Name
$username = $computersystem.PrimaryOwnerName
$domain = $computersystem.Domain
$manufacturer = $computersystem.Manufacturer
$model = $computersystem.Model
$bios = Get-CimInstance -ClassName Win32_BIOS
$serialnumber = $bios.SerialNumber
$biosversion = $bios.BIOSVersion -join " "
$processor = Get-CimInstance -ClassName Win32_processor | Select-Object -expandproperty name
$os = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -expandproperty caption
$memory = (Get-CimInstance -ClassName Win32_PhysicalMemory | Select-Object -expandproperty capacity | Measure-Object -Sum | Select-Object -ExpandProperty Sum) / 1GB
$disks = Get-CimInstance -ClassName Win32_logicaldisk -filter "DriveType='3'" #| Select-Object DeviceID, @{Name="SizeGB";Expression={$_.Size/1GB -as [int]}}, @{Name="FreeDiskSpace";Expression={[math]::Round($_.FreeSpace/1GB,2)}}, @{Name="FreeDiskSpacePercentage";Expression={[Math]::Round(($_.FreeSpace / $_.Size * 100),0)}} 
$timezone = Get-CimInstance -ClassName Win32_TimeZone | Select-Object -expandproperty Caption
$softwares = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |  Select-Object DisplayName, DisplayVersion
$softwares += Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName, DisplayVersion
#$softwares | ?{ $_.DisplayName -ne $null } | sort-object -Property DisplayName -Unique | Format-Table -AutoSize

#Count how many disks the computer have.
$diskcount = $disks | Measure-Object | Select-Object Count
$qtddisk = $diskcount.Count
#Clear the disk array
$diskfull = $null

#Search the disk array and extract the disk description and size and join this information on a single string.
for (($i=0); $i -lt $qtddisk; $i++){    
    $DeviceID = $disks[$i].DeviceID
    $SizeGB = $disks[$i].SizeGB
    $diskfull += (@("$DeviceID $SizeGB") -join '' )+"GB " 
}

#Function to get the number of disks.
function GetDisks{
    $diskinfo = @()
    foreach ($disk in $disks){
        $diskinfo = [PSCustomObject]@{
            Partition = $disk.DeviceID
            Size = "{0:N2}GB" -f [math]::round($disk.Size / 1GB, 2)
            FreeSpace = "{0:N2}GB" -f [math]::round($disk.FreeSpace / 1GB, 2)
            FreeSpacePercentage = "{0:N2}%" -f [math]::round($disk.FreeSpace / $disk.Size * 100, 2)
        }
    }
}

#Function to get the number of cpus.
function GetCPU{
    $qtdcpu = $processor.count
    $cpu = $processor[0] 
    if ($qtdcpu -gt 1){
        return "$qtdcpu x $cpu"
    } else {
        return $processor
        }
}
#Execute function CalculateCPU
$cputotal = CalculateCPU

$htmlcontent = @"

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Inventory 2024</title>

<style>    
#table {
  font-family: Arial, Helvetica, sans-serif;
  border-collapse: collapse;
  width: 100%;
}
#table td, #table th {
  border: 1px solid #ddd;
  padding: 8px;
}

#table tr:nth-child(even){background-color: #f2f2f2;}

#table tr:hover {background-color: #ddd;}

#table th{
  padding-top: 12px;
  padding-bottom: 12px;
  text-align: center;
  background-color: #04AA6D;
  color: white;
}
</style>
</head>
<body>
    <header>
    </header> 

    <main>
        <table id="table">
            <tr><th colspan=2>Inventory 2024</th></tr>
            <tr><td><b>Hostname</b></td><td>$hostname</td></tr>
            <tr><td><b>Username</b></td><td>$username</td></tr>
            <tr><td><b>Domain</b></td><td>$domain</td></tr>
            <tr><td><b>Manufacturer</b></td><td>$manufacturer</td></tr>
            <tr><td><b>Model</b></td><td>$model</td></tr>
            <tr><td><b>Bios Version</b></td><td>$biosversion</td></tr>
            <tr><td><b>SerialNumber</b></td><td>$serialnumber</td></tr>
            <tr><td><b>Processor</b></td><td>$processor</td></tr>
            <tr><td><b>OS</b></td><td>$os</td></tr>
            <tr><td><b>Memory</b></td><td>$memory</td></tr>
            <tr><td><b>Disks</b></td><td>$diskfull</td></tr>
            <tr><td><b>Timezone</b></td><td>$timezone</td></tr>
            <tr><td><b>CPUs</b></td><td>$cputotal</td></tr>
        </table>
    </main>

    <footer id="footer">
    </footer>
</body>
</html>
"@

$htmlcontent | Out-File "C:\Users\$username\$hostname.html"




