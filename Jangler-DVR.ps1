param (
$filter = "*jangler*",
$folder = "c:\projects",
$register = $false, 
$dayofWeek = 'Monday', 
$timeOfDay = '2:00 AM', 
[PSCredential]$credential)


function log($msg, $foregroundcolor = "white")
{
    Write-Host $msg -ForegroundColor $foregroundcolor
    "$(get-date): $msg" | Out-File -FilePath (join-path -path $ENV:SYS_LOGS -childpath "JanglerDVR.log") -Append
}

if($register)
{
    log -msg "Script running in Register mode!"
    $taskName = "JanglerDVR"
    # Check for existing scheduled task

    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Ignore

    # Create new task
    $action = New-ScheduledTaskAction -Execute "$env:WINDIR\System32\WindowsPowerShell\v1.0\powershell.exe" -Argument "-file `"$($MyInvocation.MyCommand.Path)`" -folder `"$folder`""
    $settings = New-ScheduledTaskSettingsSet
    $principal = New-ScheduledTaskPrincipal -UserId $credential.UserName -LogonType Password  -RunLevel Highest
    $trigger = New-ScheduledTaskTrigger -DaysOfWeek $dayofWeek -At $timeOfDay -Weekly
    $newTask = New-ScheduledTask -Action $action -Description "JanglerDVR script" -Principal $principal -Settings $settings -Trigger $trigger

    if($task -ne $null)
    {
        # Remove existing task and recreate it.
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
   
    Register-ScheduledTask -TaskName $taskName -InputObject $newTask -Password $credential.GetNetworkCredential().Password -User $credential.UserName
    log -msg "Successfully recreated $taskName scheduled task for every $dayofWeek at $timeOfDay"
    exit
}



function find-ytdlp()
{
    log -msg "find-ytdlp: checking path: $(join-path $ENV:TOOLS "yt-dlp_win\yt-dlp.exe")"
    if((test-path -Path (join-path $ENV:TOOLS "yt-dlp_win\yt-dlp.exe") -PathType Any))
    {
        log -msg "YT-DLP.exe found!"
        return (join-path $ENV:TOOLS "yt-dlp_win\yt-dlp.exe")
    }
    else
    {

        throw "find-ytdlp: YT-DLP Not found!  Please check TOOLS environment variable"
    }
}

try
{

    # Thanks browser dev mode!

    log -msg "Downloading stream list: https://services.viloud.tv/channel/a41379479a1f46923a2d1ad853245ed4?ref=https%3A%2F%2Fthemonsterchannel.com%2F" -ForegroundColor Green -folder $folder

    $session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
    $session.UserAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36"
    $response = Invoke-WebRequest -UseBasicParsing -Uri "https://services.viloud.tv/channel/a41379479a1f46923a2d1ad853245ed4?ref=https%3A%2F%2Fthemonsterchannel.com%2F" `
    -WebSession $session `
    -Headers @{
    "authority"="services.viloud.tv"
      "method"="GET"
      "path"="/channel/a41379479a1f46923a2d1ad853245ed4?ref=https%3A%2F%2Fthemonsterchannel.com%2F"
      "scheme"="https"
      "accept"="application/json, text/plain, */*"
      "accept-encoding"="gzip, deflate, br, zstd"
      "accept-language"="en-US,en;q=0.7"
      "origin"="https://player.viloud.tv"
      "referer"="https://player.viloud.tv/"
      "sec-ch-ua"="`"Brave`";v=`"123`", `"Not:A-Brand`";v=`"8`", `"Chromium`";v=`"123`""
      "sec-ch-ua-mobile"="?0"
      "sec-ch-ua-platform"="`"Windows`""
      "sec-fetch-dest"="empty"
      "sec-fetch-mode"="cors"
      "sec-fetch-site"="same-site"
      "sec-gpc"="1"
    }

}
catch
{
    log -msg "Stream list download failed!" -ForegroundColor Red -folder $folder
    log -msg $_.Message -ForegroundColor Red -folder $folder
}

# Parse it, Push it, Tow it to Golf Mill Ford!
$respObj = $response.Content | convertfrom-json

$uris = @()

foreach($item in $respObj.content)
{
    Write-Host "Evaluating item: $($item.s_name)"
    if($item.s_name -like $filter)
    {
        $uris += $item.content
        log -msg "Found Jangler stream item: $($item.content); adding to list" -ForegroundColor Green -folder $folder
    }
}

try
{
    # de-dupe and download if file not there...
    foreach($uri in ($uris | get-unique))
    {
        if($uri -like "*watch?v=*")
        {
            log -msg "Youtube video detected; downloading: $uri"
            $savepath = join-path -Path $folder -ChildPath "%(title)s.%(ext)s"
            $exepath = find-ytdlp
            log -msg "Running command: `"$exepath`"  $uri -f mp4 --video-multistreams -o `"$savepath`""
            # Note: We have to use this method instead of start-process, because start-process invokes the shell.  
            # Meaning, if you have not approved the unsigned *.exe, when your automated process runs, the (not non-interactive) prompt to confirm running the *.exe will silently hang the script.
            # You don't have that problem if you CreateProcess() intead via the C# Process object with UseShellExecute = false
            $pi = new-object -TypeName System.Diagnostics.ProcessStartInfo
            $pi.Arguments =  "$uri -f mp4 --video-multistreams -o `"$savepath`""
            $pi.FileName = $exepath
            $pi.WorkingDirectory = "$($ENV:TOOLS)yt-dlp_win\"
            $pi.UseShellExecute = $false
            $proc = new-object -TypeName System.Diagnostics.Process
            $proc.StartInfo = $pi
            $proc.Start()
            $proc.WaitForExit()
            
        }
        else
        {
            $filename = $uri.Split("/")[$uri.Split("/").Count - 1].Replace("%20"," ")
            $savepath = join-path -Path $folder -ChildPath $filename
            if((test-path $savepath) -eq $false)
            {
                log -msg "File $savepath not found in save folder!  Downloading..." -ForegroundColor Green -folder $folder
                Invoke-WebRequest -Uri $uri -OutFile $savepath
            }
            else
            {
                 log -msg "File found in savepath; ignoring:  $savepath" -ForegroundColor Yellow -folder $folder
            }
            log -msg "Finished downloading: $savepath" -ForegroundColor Green -folder $folder
        }

    } 
}
catch
{
    log -msg "Download of uri failed!  URI: $uri" -ForegroundColor Red -folder $folder
    log -msg "SavePath: $savepath" -ForegroundColor Red -folder $folder
    log -msg $_.Message -ForegroundColor Red -folder $folder
    log -msg $_.InnerException
    log -msg $_
    log -msg $stdout
}

