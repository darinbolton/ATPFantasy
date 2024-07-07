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