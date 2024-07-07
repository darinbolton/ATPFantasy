# Get dates. $date is used for the file, $day is used for the bot message
$date = Get-Date -Format "MM-dd-yyyy"
$day = Get-Date -Format "dddd MM/dd/yyyy HH:mm"
$prettyday = Get-Date -Format "dddd, MM/dd"

# Discord webhook uri's
#$webhookURL = Get-Content ..\webhookURL.txt
$webhookURL = "https://discord.com/api/webhooks/1163881495958663249/Ne_on6tWF1pJEfYX9-rG-tCj4l9rWqSO8b2ussiaxGCvzOLNDvQcHGjGgZT7Znn2UKqO"

$leaderboard = Import-Csv -Path .\ATPS3_PlayersSQL.csv | ft | Select-Object -First 10

# Create embed array
[System.Collections.ArrayList]$embedArray = @()

# Store embed values
$title       = "Ladder Leaderboard for $prettyday"
$description = "To join the Discord, please visit here: https://discord.gg/VJQCveXcPw"

# Format the CSV data as a table in a code block
$csvDescription = '`' + ($leaderboard | Format-Table | Out-String)+'`'

# Create thumbnail object
$thumbUrl = 'https://i.imgur.com/XPghlWq.png'
$thumbnailObject = [PSCustomObject]@{
    url = $thumbUrl
}

$footerObject = [PSCustomObject]@{
    text = $day + " --- This bot is maintained by Galeforce. Values are pulled from last 25 games."
}

# Create embed object, also adding thumbnail
$embedObject = [PSCustomObject]@{

    title       = $title
    description = $description
    color       = '15780864'
    thumbnail   = $thumbnailObject
    footer      = $footerObject
}

# Add embed object to array
$embedArray.Add($embedObject) | Out-Null

# Create the payload
$payload = [PSCustomObject]@{

    content = $csvDescription
    embeds = $embedArray

}

try {
    # Send over payload, converting it to JSON
    Invoke-RestMethod -Uri $webhookURL -Body ($payload | ConvertTo-Json -Depth 4) -Method Post -ContentType 'application/json'    
}

catch {
    Write-Host "Sorry about your luck."
}