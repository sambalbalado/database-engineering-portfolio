"""Convert a SQL client NDJSON export to a validated MongoDB import array.

Does not connect to a database or claim to execute Oracle SQL.
"""
import argparse
import json
from pathlib import Path
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('source', type=Path)
parser.add_argument('destination', type=Path)
args = parser.parse_args()
documents = [json.loads(line) for line in args.source.read_text().splitlines() if line.strip()]
if not all(isinstance(d, dict) and '_id' in d for d in documents):
    raise ValueError('Each line must be a JSON customer object')
if len({d['_id'] for d in documents}) != len(documents):
    raise ValueError('Duplicate customer identifiers')
args.destination.write_text(json.dumps(documents, indent=2) + '\n')
print(f'Converted {len(documents)} customer documents')
