#!/usr/bin/env python3
import json

# Load data
with open('syllabus_data_structure/all_syllabus_data.json', 'r') as f:
    data = json.load(f)

# Get entries with period information
all_entries = data['alevel'] + data['olevel']
entries_with_periods = [entry for entry in all_entries if entry.get('suggested_periods') is not None]

print(f'Entries with period info: {len(entries_with_periods)}/{len(all_entries)}')
print(f'Coverage: {len(entries_with_periods)/len(all_entries)*100:.1f}%')

print('\nSample entries with period information:')
for i, entry in enumerate(entries_with_periods[:10]):
    print(f'{i+1}. Subject: {entry["subject"]}')
    print(f'   Topic: {entry["topic"]}')
    print(f'   Class: {entry["class"]}')
    print(f'   Periods: {entry["suggested_periods"]}')
    print()

# Period distribution
period_counts = {}
for entry in entries_with_periods:
    periods = entry['suggested_periods']
    period_counts[periods] = period_counts.get(periods, 0) + 1

print('Period distribution:')
for periods, count in sorted(period_counts.items()):
    print(f'  {periods} periods: {count} entries')
