
<#This script gets the Veeam Backup Jobs Schedule

Author: Iglesio Santos
Version: 1.0
#>

$jobs = Get-VBRJob | Select-Object Name

$daily_schedule = @()
$monthly_schedule = @()
$periodically_schedule = @()
$continuous_schedule = @()

foreach ($job in $jobs){
    #Get schedule for the job
    $schedule = Get-VBRJobScheduleOptions -Job $job.Name 

    #Check if Daily Options are enabled
    if ($schedule.OptionsDaily.Enabled -eq $True){
        $time = (($schedule.OptionsDaily).TimeLocal).ToString("HH:mm")
        $day_of_week = ($schedule.OptionsDaily).DaysSrv -join ', '

        $daily_schedule += [PSCustomObject]@{
            Name = $job.Name
            Time = $time
            "Day of Week" = $day_of_week
        }
    }

    #Check if Monthly Options are enabled
    if (($schedule.OptionsMonthly).Enabled -eq $True){
        $time = (($schedule.OptionsMonthly).TimeLocal).ToString("HH:mm")
        $day_of_week = ($schedule.OptionsMonthly).DayOfWeek
        $months = ($schedule.OptionsMonthly).Months -join ', '

        $monthly_schedule += [PSCustomObject]@{
            Name = $job.Name
            Time = $time
            "Day of Week" = $day_of_week
            Months = $months
        }
    }

    #Check if Periodically Options are enabled
    if (($schedule.OptionsPeriodically).Enabled -eq $True){
        $period = ($schedule.OptionsPeriodically).FullPeriod
        $unit = ($schedule.OptionsPeriodically).Unit

        $periodically_schedule += [PSCustomObject]@{
            Name = $job.Name
            Time = "Every $period $unit"
        }
    }

    #Check if Continuous Options are enabled
    if (($schedule.OptionsContinuous).Enabled -eq $True){

        $continuous_schedule += [PSCustomObject]@{
            Name = $job.Name
            Time = "Run Continuous"
        }
    }
     
}

#Prints the output on the screen
Write-Output "-------------------------------------------------------------------------------------------------"
Write-Output "Daily Schedule:"
if($daily_schedule.Count -eq 0){
    ""
    Write-Output "No jobs scheduled"
    ""
} else{
    $daily_schedule | Format-Table -AutoSize
}

Write-Output "-------------------------------------------------------------------------------------------------"
Write-Output "Monthly Schedule:"
if($monthly_schedule.Count -eq 0){
    ""
    Write-Output "No jobs scheduled"
    ""
} else{
    $monthly_schedule | Format-Table -AutoSize
}

Write-Output "-------------------------------------------------------------------------------------------------"
Write-Output "Periodicaly Schedule:"
if($periodically_schedule.Count -eq 0){
    ""
    Write-Output "No jobs scheduled"
    ""
} else{
    $periodically_schedule | Format-Table -AutoSize
}

Write-Output "-------------------------------------------------------------------------------------------------"
Write-Output "Continuos Schedule:"
if($continuous_schedule.Count -eq 0){
    ""
    Write-Output "No jobs scheduled"
    ""
} else {
    $continuous_schedule | Format-Table -AutoSize
}
Write-Output "-------------------------------------------------------------------------------------------------"


        