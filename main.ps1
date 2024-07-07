# Updates the ATPS3_Players.csv with Map_Wins accurately pulled from Liquipedia (https://liquipedia.net/starcraft2/AllThingsProtoss/Team_League/3)
# ATPS3_Players.csv was created manually, but is dynamically updated with this script
# Even if Map_Losses is present in the .csv it's a scam and I can't be bothered to update it

Invoke-Sqlcmd -ServerInstance "WINDOWSSERVER\SQLEXPRESS" -Database 'ATPFantasy' -Encrypt Optional -Query @"
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'atp_team_league_matches')
    DROP TABLE atp_team_league_matches;

CREATE TABLE atp_team_league_matches (
    Player1 VARCHAR(255),
    Player1_Score INT,
    Player2 VARCHAR(255),
    Player2_Score INT
);
BULK INSERT atp_team_league_matches
FROM 'C:\Programs\ATPFantasy\atp_team_league_matches.csv'
WITH (
    FORMAT = 'CSV',
    FIELDTERMINATOR = ',',
    FIELDQUOTE = '"',
    ROWTERMINATOR = '\n',
    FIRSTROW = 2
);
"@

$matches = Invoke-Sqlcmd -ServerInstance "WINDOWSSERVER\SQLEXPRESS" -Database 'ATPFantasy' -Encrypt Optional -Query @"
SELECT TOP (1000) [Player1]
      ,[Player1_Score]
      ,[Player2]
      ,[Player2_Score]
  FROM [ATPFantasy].[dbo].[atp_team_league_matches]
"@

# Initialize a hashtable to store the map wins
$mapWins = @{}

# Function to add or update the map wins for a player
function Update-MapWins {
    param (
        [string]$player,
        [int]$score
    )
    if (-not $mapWins.ContainsKey($player)) {
        $mapWins[$player] = 0
    }
    $mapWins[$player] += $score
}

# Loop through the matches array and calculate the map wins
foreach ($match in $matches) {
    $player1 = $match[0]
    $player1Score = $match[1]
    $player2 = $match[2]
    $player2Score = $match[3]
    
    Update-MapWins -player $player1 -score $player1Score
    Update-MapWins -player $player2 -score $player2Score
}

# Convert the hashtable to an array of custom objects for easy display and further processing
$mapWinsArray = @()
foreach ($key in $mapWins.Keys) {
    $mapWinsArray += [pscustomobject]@{
        Player = $key
        MapWins = $mapWins[$key]
    }
}

# Display the results
$mapWinsArray | Format-Table -AutoSize

# If you want to store the results in a different array format
$resultsArray = @()
foreach ($entry in $mapWinsArray) {
    $resultsArray += ,@($entry.Player, $entry.MapWins)
}

$mapWinsArray | Export-Csv -Path '.\ATPS3_Players_Staging.csv'

# Loop through the array and update the SQL table
foreach ($entry in $mapWinsArray) {
    $player = $entry.Player
    $mapWins = $entry.MapWins
    
    # Define the SQL query
    $query = @"
    UPDATE [ATPS3_Players]
    SET [Map_Wins] = $mapWins
    WHERE [Name] = '$player'
"@

    # Execute the SQL command using Invoke-Sqlcmd
    Invoke-Sqlcmd -ServerInstance "WINDOWSSERVER\SQLEXPRESS" -Database 'ATPFantasy' -Encrypt Optional -Query $query
}

$updatePointTotalQuery = @"
UPDATE [ATPS3_Players]
SET [Point_Total] = ([Map_Wins] * 10) * [Multiplier]
"@

Invoke-Sqlcmd -ServerInstance "WINDOWSSERVER\SQLEXPRESS" -Database 'ATPFantasy' -Encrypt Optional -Query $updatePointTotalQuery

$playerRankings = Invoke-Sqlcmd -ServerInstance "WINDOWSSERVER\SQLEXPRESS" -Database 'ATPFantasy' -Encrypt Optional -Query @"
SELECT TOP (1000) [Team]
      ,[Name]
      ,[Pool]
      ,[Multiplier]
      ,[Map_Wins]
      ,[Point_Total]
  FROM [ATPFantasy].[dbo].[ATPS3_Players]
"@

$playerRankingsSorted = $playerRankings | Select-Object -Property Name,Pool,Multiplier,Map_Wins,Point_Total |  Sort-Object -Property @{Expression = "Point_Total"; Descending = $true}

$date = Get-Date -Format "MM-dd-yyyy"
$day = Get-Date -Format "dddd MM/dd/yyyy HH:mm"
$prettyday = Get-Date -Format "MM/dd"

# Discord webhook uri's
#$webhookURL = Get-Content ..\webhookURL.txt
$webhookURL = "https://discord.com/api/webhooks/1163881495958663249/Ne_on6tWF1pJEfYX9-rG-tCj4l9rWqSO8b2ussiaxGCvzOLNDvQcHGjGgZT7Znn2UKqO"

# 36 was the maximum amount of rows I could include. 
$leaderboard = $playerRankingsSorted[0..36]

# Create embed array
[System.Collections.ArrayList]$embedArray = @()

# Store embed values
$title       = "AllThingsProtoss Team League - Fantasy"
$description = "The AllThingsProtoss Team League is a Draft Team League organized and sponsored by Gemini with additional prize pool contributions from Esarel, NeWHoriZonS, Dyncommon, LeWaffles, Ardent, Frogos, Xin and danimal for the r/AllThingsProtoss Discord community. To view upcoming matches and results, visit the Liquipedia: https://liquipedia.net/starcraft2/AllThingsProtoss/Team_League/3."

# Format the CSV data as a table in a code block
$csvDescription = '`' + ($leaderboard | Format-Table | Out-String)+'`'

# Create thumbnail object
$thumbUrl = 'https://i.imgur.com/XPghlWq.png'
$thumbnailObject = [PSCustomObject]@{
    url = $thumbUrl
}

$footerObject = [PSCustomObject]@{
    text = $day + " --- This bot is maintained by @Gale and runs once weekly."
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

    embeds = $embedArray
    content = $csvDescription

}
# Send over payload, converting it to JSON
Invoke-RestMethod -Uri $webhookURL -Body ($payload | ConvertTo-Json -Depth 4) -Method Post -ContentType 'application/json'  