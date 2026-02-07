#!/usr/bin/env python3
import json
from collections import Counter

# Load data
with open('syllabus_data_structure/all_syllabus_data.json', 'r') as f:
    data = json.load(f)

# Get class distribution
classes = [entry['class'] for entry in data['alevel'] + data['olevel']]
class_counts = Counter(classes)

print('Class Distribution:')
for cls, count in sorted(class_counts.items()):
    print(f'  {cls}: {count} entries')

print(f'\nTotal entries: {sum(class_counts.values())}')
print(f'Unique classes: {len(class_counts)}')
