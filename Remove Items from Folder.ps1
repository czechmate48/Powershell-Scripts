while($true){
    
    #Get Files
    #$source = "C:\Users\csefcik\Hospice of the Piedmont\HOP Intranet - Aprima Documents Library Import & Export"
    #$destination = "C:\Aprima Test"
    $source = "C:\Users\csefcik\Desktop\Test_1"
    $destination = "C:\Users\csefcik\Desktop\Test_2"
    $files = Get-ChildItem $source -Name

    #Move Files
    foreach ($file in $files){
        #check to make sure file is not currently being copied/uploaded
        Move-Item -Path "$source\$file" -Destination $destination
    }

    #"#-------------------------------------------------------#" | Out-File -FilePath $finalStepsPath -Append

    $lastSync = Get-Date
    $now = Get-Date
    $difference = New-TimeSpan -Start $lastSync -End $now
    $syncClock = New-TimeSpan -minute 2
    while($difference -lt $syncClock){

        $checkTimer = New-TimeSpan -minute 1 -Seconds 59 
        if ($difference -gt $checkTimer){
            $now = Get-Date
            $difference = New-TimeSpan -Start $lastSync -End $now
            Write-Host "Less than"
        }
        else {
            Start-Sleep -Seconds 1
            $now = Get-Date
            $difference = New-TimeSpan -Start $lastSync -End $now
            Write-Host "$now : Sleeping"
        }
    }

}