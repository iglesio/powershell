
<#This script gets the Veeam backup jobs schedule.

Author: Iglesio Santos
Version: 1.0
#>

$Jobs = Get-VBRJob | Select-Object Name

$DailySchedule = @()
$MonthlySchedule = @()
$PeriodicallySchedule = @()
$ContinuousSchedule = @()

foreach ($Job in $Jobs){
    #Get schedule for the job
    $Schedule = Get-VBRJobScheduleOptions -Job $Job.Name 

    #Check if Daily Options are enabled
    if ($Schedule.OptionsDaily.Enabled -eq $True){
        $Time = (($Schedule.OptionsDaily).TimeLocal).ToString("HH:mm")
        $DayOfWeek = ($Schedule.OptionsDaily).DaysSrv -join ', '

        $DailySchedule += [PSCustomObject]@{
            Name = $Job.Name
            Time = $Time
            "Day of Week" = $DayOfWeek
        }
    }

    #Check if Monthly Options are enabled
    if (($Schedule.OptionsMonthly).Enabled -eq $True){
        $Time = (($Schedule.OptionsMonthly).TimeLocal).ToString("HH:mm")
        $DayOfWeek = ($Schedule.OptionsMonthly).DayOfWeek
        $Months = ($Schedule.OptionsMonthly).Months -join ', '

        $MonthlySchedule += [PSCustomObject]@{
            Name = $Job.Name
            Time = $Time
            "Day of Week" = $DayOfWeek
            Months = $Months
        }
    }

    #Check if Periodically Options are enabled
    if (($Schedule.OptionsPeriodically).Enabled -eq $True){
        $Period = ($Schedule.OptionsPeriodically).FullPeriod
        $Unit = ($Schedule.OptionsPeriodically).Unit

        $PeriodicallySchedule += [PSCustomObject]@{
            Name = $Job.Name
            Time = "Every $Period $Unit"
        }
    }

    #Check if Continuous Options are enabled
    if (($Schedule.OptionsContinuous).Enabled -eq $True){

        $ContinuousSchedule += [PSCustomObject]@{
            Name = $Job.Name
            Time = "Run Continuous"
        }
    }
}

#Prints the output on the screen
Write-Output "-------------------------------------------------------------------------------------------------"
Write-Output "Daily Schedule:"
if($DailySchedule.Count -eq 0){
    ""
    Write-Output "No jobs scheduled"
    ""
} else{
    $DailySchedule | Format-Table -AutoSize
}

Write-Output "-------------------------------------------------------------------------------------------------"
Write-Output "Monthly Schedule:"
if($MonthlySchedule.Count -eq 0){
    ""
    Write-Output "No jobs scheduled"
    ""
} else{
    $MonthlySchedule | Format-Table -AutoSize
}

Write-Output "-------------------------------------------------------------------------------------------------"
Write-Output "Periodicaly Schedule:"
if($PeriodicallySchedule.Count -eq 0){
    ""
    Write-Output "No jobs scheduled"
    ""
} else{
    $PeriodicallySchedule | Format-Table -AutoSize
}

Write-Output "-------------------------------------------------------------------------------------------------"
Write-Output "Continuos Schedule:"
if($ContinuousSchedule.Count -eq 0){
    ""
    Write-Output "No jobs scheduled"
    ""
} else {
    $ContinuousSchedule | Format-Table -AutoSize
}
Write-Output "-------------------------------------------------------------------------------------------------"


        