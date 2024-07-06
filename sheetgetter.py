import os
import json
import requests
from google.oauth2 import service_account
from googleapiclient.discovery import build

# Set up the credentials
credentials_file = r"C:\Users\Darin\Code\ATP_FantasyLeague\SheetGetter.json"
spreadsheet_id = "1iomLDTI9KKcl6NlZf4LpQOn2KA7uoheGnoHyO6EBd-c"
range_name = "Season3_Players"

credentials = service_account.Credentials.from_service_account_file(credentials_file)
service = build('sheets', 'v4', credentials=credentials)

# Fetch the data from Google Sheets
sheet = service.spreadsheets()
result = sheet.values().get(spreadsheetId=spreadsheet_id, range=range_name).execute()
values = result.get('values', [])

# Save the data to a CSV file
csv_file_path = 'ATPS3_Players.csv'
with open(csv_file_path, 'w', newline='') as csv_file:
    for row in values:
        csv_file.write(','.join(row) + '\n')

print(f'Data has been written to {csv_file_path}')

# Set up the credentials
credentials_file = r"C:\Users\Darin\Code\ATP_FantasyLeague\SheetGetter.json"
spreadsheet_id = "1iomLDTI9KKcl6NlZf4LpQOn2KA7uoheGnoHyO6EBd-c"
range_name = "Season3_FantasyPlayers"

credentials = service_account.Credentials.from_service_account_file(credentials_file)
service = build('sheets', 'v4', credentials=credentials)

# Fetch the data from Google Sheets
sheet = service.spreadsheets()
result = sheet.values().get(spreadsheetId=spreadsheet_id, range=range_name).execute()
values = result.get('values', [])

# Save the data to a CSV file
csv_file_path = 'ATPS3_FantasyPlayers.csv'
with open(csv_file_path, 'w', newline='') as csv_file:
    for row in values:
        csv_file.write(','.join(row) + '\n')

print(f'Data has been written to {csv_file_path}')
