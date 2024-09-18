<#
This powershell script collects information about a computer and export this information on a report in HTML.
#>

#CIM querys to collect information about the computer.
$hostname = (Get-CimInstance -ClassName Win32_ComputerSystem).Name
$serialnumber = Get-CimInstance -ClassName Win32_BIOS | Select-Object -expandproperty Serialnumber 
$manufacturer = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -expandproperty Manufacturer 
$model = Get-CimInstance -ClassName Win32_ComputerSystem | Select-Object -expandproperty Model
$processor = Get-CimInstance -ClassName Win32_processor | Select-Object -expandproperty name
$os = Get-CimInstance -ClassName Win32_OperatingSystem | Select-Object -expandproperty caption
$memory = (Get-CimInstance -ClassName Win32_PhysicalMemory | Select-Object -expandproperty capacity | Measure-Object -Sum | Select-Object -ExpandProperty Sum) / 1GB
$disks = Get-CimInstance -ClassName Win32_logicaldisk -filter "DriveType='3'" | Select-Object DeviceID, @{Name="SizeGB";Expression={$_.Size/1GB -as [int]}}, @{Name="FreeDiskSpace";Expression={[math]::Round($_.FreeSpace/1GB,2)}}, @{Name="FreeDiskSpacePercentage";Expression={[Math]::Round(($_.FreeSpace / $_.Size * 100),0)}} 
$softwares = Get-ItemProperty HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\* |  Select-Object DisplayName, DisplayVersion, Publisher, InstallDate
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

#Function to calculate the number of cpus.
function CalculateCPU{
    $qtdcpu = $processor.count
    $cpu = $processor[0] 
    if ($qtdcpu -gt 1){
        return "$qtdcpu x $cpu"
    } else {
        return $processor
        }
}
#Chama a função CalculaCPU
$cputotal = CalculateCPU

Write-Output $hostname
Write-Output $serialnumber
Write-Output $cputotal
Write-Output $os
Write-Output $memory'GB'
Write-Output $manufacturer
Write-Output $model
Write-Output $diskfull
Write-Output $softwares | sort-object -Property DisplayName -Unique | Format-Table -AutoSize




