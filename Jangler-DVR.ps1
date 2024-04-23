param ($folder = "c:\projects")

# Thanks browser dev mode!

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

# Parse it, Push it, Tow it to Golf Mill Ford!
$respObj = $response.Content | convertfrom-json

$uris = @()

foreach($item in $respObj.content)
{
    if($item.s_name -like "*jangler*")
    {
        $uris += $item.content
    }
}

# de-dupe and download if file not there...
foreach($uri in ($uris | get-unique))
{
    $filename = $uri.Split("/")[$uri.Split("/").Count - 1].Replace("%20"," ")
    $savepath = join-path -Path $folder -ChildPath $filename
    if((test-path $savepath) -eq $false)
    {
        Write-Host "File not found in save folder!  Downloading..." -ForegroundColor Green
        Invoke-WebRequest -Uri $uri -OutFile $savepath
    }
    else
    {
        Write-Host "File found in savepath; ignoring:  $savepath" -ForegroundColor Yellow
    }
} 

