#!/usr/bin/env python3
import json

# Load data
with open('syllabus_data_structure/all_syllabus_data.json', 'r') as f:
    data = json.load(f)

# Check for period information
all_entries = data['alevel'] + data['olevel']
entries_with_periods = []
entries_with_suggested_periods = []

for entry in all_entries:
    # Check if topic name contains period info
    if '(periods)' in entry['topic'].lower() or '(period' in entry['topic'].lower():
        entries_with_periods.append(entry)
    
    # Check if suggested_periods field is populated
    if entry.get('suggested_periods') is not None:
        entries_with_suggested_periods.append(entry)

print(f'Total entries: {len(all_entries)}')
print(f'Entries with period info in topic name: {len(entries_with_periods)}')
print(f'Entries with suggested_periods field populated: {len(entries_with_suggested_periods)}')

print('\nSample entries with period info in topic name:')
for i, entry in enumerate(entries_with_periods[:10]):
    print(f'  {i+1}. {entry["topic"]}')

print('\nSample suggested_periods values:')
for i, entry in enumerate(entries_with_suggested_periods[:5]):
    print(f'  {i+1}. {entry["suggested_periods"]}')
