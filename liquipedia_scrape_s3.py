import pandas as pd
import requests
from bs4 import BeautifulSoup

URL = 'https://liquipedia.net/starcraft2/AllThingsProtoss/Team_League/3'

page = requests.get(URL)
soup = BeautifulSoup(page.content, 'html.parser')

results = soup.find(id='main-content-column')
real_results = results.find(id='bodyContent')
real_results = real_results.find(id='mw-content-text')

matches = real_results.find_all('div', class_="brkts-popup brkts-popup-sc brkts-popup-sc-team-match brkts-match-info-popup")

# Initialize list to store match data
match_data = []

for match in matches:
    match_info = match.find('div', class_='brkts-popup-body')
    submatches = match_info.find_all('div', class_='brkts-popup-sc-submatch')
    
    for submatch in submatches:
        player1_div = submatch.find('div', class_='block-player starcraft-block-player flipped brkts-popup-sc-submatch-opponent')
        player2_div = submatch.find('div', class_='block-player starcraft-block-player brkts-popup-sc-submatch-opponent')
        
        if player1_div and player2_div:
            player1 = player1_div.find('span', class_='name').text.strip()
            player2 = player2_div.find('span', class_='name').text.strip()
            
            # Find the scores for each player
            scores = submatch.find_all('div', class_='brkts-popup-sc-submatch-score')
            player1_score = scores[0].text.strip() if len(scores) > 0 else 'N/A'
            player2_score = scores[1].text.strip() if len(scores) > 1 else 'N/A'

            match_data.append({
                'Player 1': player1,
                'Player 1 Score': player1_score,
                'Player 2': player2,
                'Player 2 Score': player2_score
            })

# Convert to DataFrame
df = pd.DataFrame(match_data)

# Save to CSV
df.to_csv('atp_team_league_matches.csv', index=False)

print("Data scraped and saved to 'atp_team_league_matches.csv'")
