"""Database-independent portfolio checks; does not execute SQL or MongoDB.

Run from any directory with Python 3.10+. Uses only the standard library.
"""
from pathlib import Path
from datetime import datetime
from decimal import Decimal
from collections import Counter
from itertools import combinations
import json
import re
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
WASTE = ROOT / 'case-studies/waste-collection'
TRANSPORT = ROOT / 'case-studies/transport-logistics'
completed = []


def check(condition, message):
    if not condition:
        raise AssertionError(message)


def split_values(text):
    values, start, depth, quoted, pos = [], 0, 0, False, 0
    while pos < len(text):
        char = text[pos]
        if char == "'":
            if quoted and pos + 1 < len(text) and text[pos + 1] == "'":
                pos += 2
                continue
            quoted = not quoted
        elif not quoted:
            if char == '(':
                depth += 1
            elif char == ')':
                depth -= 1
            elif char == ',' and depth == 0:
                values.append(text[start:pos].strip())
                start = pos + 1
        pos += 1
    check(not quoted and depth == 0, 'Unbalanced fixture literal')
    return values + [text[start:].strip()]


def literal(text):
    if text.upper() == 'NULL':
        return None
    if text.upper().startswith('TO_DATE'):
        values = split_values(text[text.index('(') + 1:-1])
        check(values[1].strip("'") == 'YYYY-MM-DD', 'Unexpected fixture date format')
        return datetime.strptime(values[0].strip("'"), '%Y-%m-%d')
    if text.upper().startswith(('DATE ', 'TIMESTAMP ')):
        return datetime.fromisoformat(re.search(r"'([^']+)'", text)[1])
    if text.startswith("'"):
        return text[1:-1].replace("''", "'")
    return Decimal(text) if '.' in text else int(text)


def read_inserts(path, column_order=None):
    rows = {}
    sql = re.sub(r'--[^\n]*', '', path.read_text())
    for match in re.finditer(r'INSERT INTO (\w+)\s*(?:\((.*?)\))?\s*VALUES\s*\((.*?)\);', sql, re.S | re.I):
        table = match[1].lower()
        columns = [c.strip().lower() for c in match[2].split(',')] if match[2] else column_order[table]
        values = list(map(literal, split_values(match[3])))
        check(len(values) == len(columns), f'{path.name}: {table} column/value mismatch')
        rows.setdefault(table, []).append(dict(zip(columns, values)))
    return rows


def schema_columns(text):
    tables = {}
    for match in re.finditer(r'CREATE TABLE (\w+)\s*\((.*?)\)\s*;', text, re.S | re.I):
        columns = []
        for item in split_values(match[2]):
            field = re.match(r'\s*(\w+)\s+(CHAR|VARCHAR2|NUMBER|DATE)\b', item, re.I)
            if field:
                columns.append(field[1].lower())
        tables[match[1].lower()] = columns
    return tables


# Complete literal fixture references, costs, roles and scheduling.
core = read_inserts(TRANSPORT / 'sql/05-sample-data.sql')
ref_schema = (TRANSPORT / 'sql/01-reference-schema.sql').read_text()
reference = read_inserts(TRANSPORT / 'sql/04-reference-data.sql', schema_columns(ref_schema))
employees = {r['emp_no']: r for r in core['employee']}
quotes = {r['quote_no']: r for r in core['quote']}
jobs = core['job']
customers = {r['cust_no']: r for r in reference['customer']}
valid_pairs = {(r['truck_vin'], r['trailer_code']) for r in reference['combination']}
check((len(employees), len(quotes), len(jobs), len(customers), len(valid_pairs)) == (10, 32, 20, 6, 13), 'Unexpected fixture counts')
for table, key in [('employee', 'emp_no'), ('quote', 'quote_no'), ('job', 'job_no')]:
    check(len({r[key] for r in core[table]}) == len(core[table]), f'Duplicate {table} key')
check(len({e['emp_contact_no'] for e in employees.values()}) == len(employees), 'Duplicate employee contact')
licences = [e['emp_licenceno'] for e in employees.values() if e['emp_licenceno']]
check(len(set(licences)) == len(licences), 'Duplicate employee licence')
for employee in employees.values():
    check((employee['emp_role'] == 'D') == bool(employee['emp_licenceno']), 'Driver licence mismatch')
    if employee['emp_role'] != 'B':
        check(employees[employee['emp_no_manager']]['emp_role'] == 'B', 'Invalid reporting role')
for quote in quotes.values():
    check(quote['cust_no'] in customers and employees[quote['emp_no']]['emp_role'] == 'T', 'Quote relationship/role mismatch')
    check(quote['quote_cost'] > 0 and quote['quote_pref_start_date'] >= quote['quote_prepared_date'], 'Invalid quote cost/dates')
check(len({job['quote_no'] for job in jobs}) == len(jobs), 'Multiple jobs per quote')
for job in jobs:
    quote = quotes[job['quote_no']]
    check((job['truck_vin'], job['trailer_code']) in valid_pairs, 'Unapproved vehicle pair')
    check(employees[job['driver_emp_no']]['emp_role'] == 'D', 'Invalid driver role')
    check(employees[job['sched_emp_no']]['emp_role'] == 'T', 'Invalid scheduler role')
    check(job['job_intended_dropoff_dt'] > job['job_pickup_dt'] >= quote['quote_prepared_date'], 'Invalid job chronology')
    check(job['job_payment_made'] in {'Y', 'N'}, 'Invalid payment flag')
    check(job['job_cost'] is None or job['job_cost'] > 0, 'Invalid revised job cost')
for first, second in combinations(jobs, 2):
    if first['job_pickup_dt'] < second['job_intended_dropoff_dt'] and second['job_pickup_dt'] < first['job_intended_dropoff_dt']:
        for resource in ('truck_vin', 'trailer_code', 'driver_emp_no'):
            check(first[resource] != second[resource], f'Overlapping {resource}: jobs {first["job_no"]}/{second["job_no"]}')
check(sum(j['job_cost'] is None for j in jobs) == 15, 'Expected fifteen quote-cost fallbacks')
check(sum(j['job_cost'] is not None and j['job_cost'] != quotes[j['quote_no']]['quote_cost'] for j in jobs) == 5, 'Expected five revised prices')
completed.append('Transport literal fixtures: keys, dependencies, roles, dates, price cases and resource intervals')

# Calculate report expectations without claiming SQL execution.
usage = Counter((j['truck_vin'], j['trailer_code']) for j in jobs)
check(len(usage) == 10 and sum(n >= 2 for n in usage.values()) >= 5, 'Insufficient repeated combinations')
check(len(valid_pairs - usage.keys()) == 3, 'Unused combination edge case missing')
check(sum(usage.values()) / len(usage) == 2, 'Unexpected used-pair average')
check(sum(n > 2 for n in usage.values()) == 2, 'Unexpected high-use pair count')
check(sum(quotes[j['quote_no']]['quote_cost'] for j in jobs) != sum(j['job_cost'] or quotes[j['quote_no']]['quote_cost'] for j in jobs), 'Quoted and effective totals must differ')
completed.append('Report expectations: ten used pairs, three unused pairs, average 2 jobs, two high-use pairs; quoted/effective costs differ')

# Independently reconstruct the expected document state after cancellation.
quotes[300] = dict(quote_no=300, quote_prepared_date=datetime(2026, 5, 17), quote_pref_start_date=datetime(2026, 5, 25), quote_start_location='29 Kuranda Road, Adelaide SA 5030', quote_end_location='9 Albatros Drive, Mount Gambier SA 5270', quote_cost=1000, cust_no=18)
by_quote = {j['quote_no']: j for j in jobs}
expected_documents = []

def money(number):
    return '-' if number is None else f'${number:,.2f}'

for customer in customers.values():
    customer_quotes = sorted([q for q in quotes.values() if q['cust_no'] == customer['cust_no']], key=lambda q: q['quote_no'])
    paid, unpaid, embedded = [], [], []
    for quote in customer_quotes:
        job = by_quote.get(quote['quote_no'])
        cost = (job['job_cost'] if job['job_cost'] is not None else quote['quote_cost']) if job else None
        if job:
            (paid if job['job_payment_made'] == 'Y' else unpaid).append(cost)
        embedded.append(dict(quote_no=quote['quote_no'], quote_prepared_on=quote['quote_prepared_date'].strftime('%d-%b-%Y'), preferred_start_date=quote['quote_pref_start_date'].strftime('%d-%b-%Y'), start_location=quote['quote_start_location'], end_location=quote['quote_end_location'], quote_cost=money(quote['quote_cost']), assigned_to_job='Y' if job else 'N', job_cost=money(cost)))
    expected_documents.append(dict(_id=customer['cust_no'], customer_name=' '.join(filter(None, [customer['cust_gname'], customer['cust_fname']])), customer_business=customer['cust_bname'] or '-', customer_address=', '.join([customer['cust_street'], customer['cust_town'], customer['cust_pcode']]), customer_phone=customer['cust_contact_no'], customer_stats=dict(number_of_quotes=len(customer_quotes), number_of_jobs=sum(q['quote_no'] in by_quote for q in customer_quotes), total_paid_jobcost=money(sum(paid) if paid else None), total_unpaid_jobcost=money(sum(unpaid) if unpaid else None)), quotes=embedded))
actual_documents = json.loads((TRANSPORT / 'examples/customers.json').read_text())
check(actual_documents == expected_documents, 'Customer JSON differs from independently reconstructed fixture')
check(sum(len(d['quotes']) for d in actual_documents) == 33, 'Expected 33 nested quotes')
check(len([d for d in actual_documents if 'Melbourne' in d['customer_address'] and len(d['quotes']) >= 2]) == 2, 'Mongo filter fixture edge case missing')
completed.append('JSON validity and all six documents reconciled: 33 quotes, 20 jobs, paid/unpaid effective totals')

# Waste model correspondence and corrected synthetic fixture.
baseline = (WASTE / 'sql/01-schema.sql').read_text()
waste_columns = schema_columns(baseline)
model_tables = {}
for path in (WASTE / 'models/data-modeler').glob('**/table/**/*.xml'):
    element = ET.fromstring(path.read_text())
    model_tables[element.attrib['name'].lower()] = [column.attrib['name'].lower() for column in element.findall('.//Column')]
check(waste_columns == model_tables and len(model_tables) == 14, 'Baseline model/SQL mismatch')
current_columns = dict(waste_columns)
current_columns['bin'] = [c for c in waste_columns['bin'] if c not in {'waste_type_id', 'bin_size'}]
waste_rows = read_inserts(WASTE / 'sql/03-demo-data.sql', current_columns)
supplies = {s['contract_bin_supply_id']: s for s in waste_rows['contract_bin_supply']}
bins = {b['bin_rfid']: b for b in waste_rows['bin']}
runs = {r['collection_run_id']: r for r in waste_rows['collection_run']}
contracts = {c['contract_no']: c for c in waste_rows['contract']}
properties = {p['property_id']: p for p in waste_rows['property']}
prices = {(c['contract_no'], c['waste_type_id']): c['collection_cost_per_kg'] for c in waste_rows['contract_waste_collection']}
check(all((s['contract_no'], s['waste_type_id']) in prices for s in supplies.values()), 'Uncovered supply agreement')
check(all(re.fullmatch(r'[0-9A-F]{24}', b['bin_rfid']) for b in bins.values()), 'Invalid RFID fixture')
check(all(re.fullmatch(r'[A-HJ-NPR-Z0-9]{17}', t['collection_truck_vin']) for t in waste_rows['truck']), 'Invalid VIN fixture')
for b in bins.values():
    contract = contracts[supplies[b['contract_bin_supply_id']]['contract_no']]
    check(contract['authority_name'] == properties[b['property_id']]['authority_name'], 'Wrong supply authority')
    check(contract['start_date'] <= b['supply_date'] <= contract['end_date'], 'Supply date outside contract')
daily = set()
for observation in waste_rows['bin_collection']:
    run = runs[observation['collection_run_id']]
    b = bins[observation['bin_rfid']]
    check(supplies[b['contract_bin_supply_id']]['waste_type_id'] == run['waste_type_id'], 'Collection waste mismatch')
    key = b['property_id'], run['waste_type_id'], run['date_of_collection']
    check(key not in daily, 'Duplicate property/waste/day fixture')
    daily.add(key)
    check((observation['overweight'] == 'Y') == (observation['collected_kgs'] is None), 'Overweight/weight fixture mismatch')
check(supplies[1]['contract_bin_supply_cost'] == 55, 'Historical price mismatch')
check(Decimal('62') * prices[102, 'GW'] == Decimal('11.16'), 'Charge expectation mismatch')
completed.append('Waste baseline: 14 table definitions match model XML; corrected fixture identifiers, contract coverage and charge expectations')

# All included editable model documents parse, and paired .dmd directories exist.
xml_count = 0
for path in ROOT.rglob('*'):
    if '.git' in path.parts or not path.is_file():
        continue
    if path.suffix in {'.xml', '.dmd', '.drawio', '.local'}:
        ET.fromstring(path.read_text())
        xml_count += 1
    if path.suffix == '.dmd':
        check(path.with_suffix('').is_dir(), f'Missing Data Modeler companion folder: {path.name}')
completed.append(f'Editable model structure: {xml_count} XML/design documents parse; Data Modeler companion directory present')

# Local documentation/image targets and script includes, resolved from their containing files.
link_count = 0
include_count = 0
for path in ROOT.rglob('*'):
    if '.git' in path.parts or not path.is_file():
        continue
    if path.suffix == '.md':
        for target in re.findall(r'\]\(([^)]+)\)', path.read_text()):
            target = target.split('#')[0]
            if not target or re.match(r'[a-z]+://', target):
                continue
            check((path.parent / target).resolve().is_file() or (path.parent / target).resolve().is_dir(), f'Broken Markdown link in {path.relative_to(ROOT)}: {target}')
            link_count += 1
    if path.suffix == '.sql':
        for target in re.findall(r'^@@(\S+)', path.read_text(), re.M):
            check((path.parent / target).is_file(), f'Broken SQL include: {path.name}: {target}')
            include_count += 1
completed.append(f'Navigation: {link_count} local Markdown/image links and {include_count} SQL includes resolve')

# Public-tree content scan. PDFs also receive a separate decompressed-content/metadata review.
blocked_names = re.compile(r'(?:_Brief|marked|feedback|checklist|schema-insert)', re.I)
blocked_text = re.compile(r'Student\s+ID\s*:|Faculty\s+of\s+Information\s+Technology|/Users/[A-Za-z0-9_.-]+/|BEGIN (?:RSA |OPENSSH )?PRIVATE KEY|gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]+|AKIA[A-Z0-9]{16}', re.I)
text_count = 0
for path in ROOT.rglob('*'):
    if '.git' in path.parts or not path.is_file():
        continue
    check(not blocked_names.search(path.name), f'Excluded filename found: {path.name}')
    check(path.suffix not in {'.zip', '.7z', '.pem', '.key', '.p12', '.jks', '.ora'}, f'Blocked artifact type: {path.name}')
    if path == Path(__file__).resolve():
        continue  # scanner rules necessarily contain the patterns they reject
    try:
        text = path.read_text()
    except (UnicodeError, OSError):
        continue
    check(not blocked_text.search(text), f'Blocked public content in {path.relative_to(ROOT)}')
    check(not re.search(r'://[^\s/:]+:[^\s/@]+@', text), f'Credential-bearing URL in {path.name}')
    text_count += 1
completed.append(f'Public-tree scan: {text_count} text files; no blocked identifiers, credential URLs or restricted artifact names')

print('STATIC CHECKS PASSED')
for item in completed:
    print('- ' + item)
print('Not executed: Oracle SQL/PLSQL, database constraint tests, SQL client exports, MongoDB operations, native Data Modeler reopening.')
