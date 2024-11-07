<#
This script creates a new VM on Hyper-V.

Author: Iglesio Santos
Version: 1.0
#>

$VMs= "srv1", "srv2"

foreach ($VM in $VMs){
    #Creates a new VM
    $VMSpecs = @{
        Name = $VM
        MemoryStartupBytes = 4GB
        Generation = 2
        NewVHDPath = "C:\Virtual Machines\Virtual Hard Disks\$VM.vhdx"
        NewVHDSizeBytes = 30GB
        BootDevice = "VHD"
        Path = "C:\Virtual Machines\$VM"
        SwitchName = "External"     
    }

    New-VM @VMSpecs

    #Add a ISO file to the DVD drive
    Add-VMDvdDrive -VMName $VM -Path "D:\ISOs\ubuntu-24.04.1-live-server-amd64.iso"

    #Change secure boot options and boot order
    Set-VMFirmware -VMName $VM -SecureBootTemplate "MicrosoftUEFICertificateAuthority" -BootOrder (Get-VMDvdDrive -VMName $VM), (Get-VMHardDiskDrive -VMName $VM), (Get-VMNetworkAdapter -VMName $VM)
  
    #Enable dynamic memory
    Set-VMMemory -VMName $VM -DynamicMemoryEnabled $true -MinimumBytes 1GB -MaximumBytes 4GB

    #Disable automatic checkpoints and set number of processors
    Set-VM -Name $VM -AutomaticCheckpointsEnabled $false -ProcessorCount 1 

    #Enable guest services
    Enable-VMIntegrationService -Name "Interface de Serviço de Convidado" -VMName $VM
}

