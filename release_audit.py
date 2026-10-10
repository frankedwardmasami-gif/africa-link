#!/usr/bin/env python3
"""Static release audit for AFRICA LINK. No network access required."""
from pathlib import Path
import re, sys

ROOT = Path(__file__).resolve().parents[1]
errors=[]; warnings=[]

pub=ROOT/'pubspec.yaml'
text=pub.read_text()
if 'supabase_flutter:' not in text: errors.append('Missing supabase_flutter dependency')
if not re.search(r'^version:\s*\d+\.\d+\.\d+\+\d+', text, re.M): errors.append('Invalid/missing pubspec version')

migrations=sorted((ROOT/'supabase/migrations').glob('*.sql'))
nums=[]
for p in migrations:
    m=re.match(r'(\d+)_',p.name)
    if m: nums.append(int(m.group(1)))
expected=list(range(1,len(nums)+1))
if nums != expected: errors.append(f'Migration numbering/order is not contiguous: {nums}')

for p in ROOT.rglob('*'):
    if not p.is_file() or any(part in {'.git','build','.dart_tool'} for part in p.parts): continue
    try: s=p.read_text(errors='ignore')
    except Exception: continue
    if p.name != 'release_audit.py' and re.search(r'(?i)(service' + r'_role|BEGIN RSA PRIVATE KEY|-----BEGIN .*PRIVATE KEY-----)', s):
        errors.append(f'Possible secret/private key in {p.relative_to(ROOT)}')
    if 'TODO' in s and p.suffix in {'.dart','.sql'}:
        warnings.append(f'TODO remains in {p.relative_to(ROOT)}')

# Verify every local Dart import resolves to a file in this project.
for dart_file in ROOT.rglob('*.dart'):
    if any(part in {'.git','.dart_tool','build'} for part in dart_file.parts):
        continue
    try:
        source=dart_file.read_text(errors='ignore')
    except Exception:
        continue
    for imp in re.findall(r"import\s+['\"]([^'\"]+)['\"]", source):
        target=None
        if imp.startswith('.'):
            target=(dart_file.parent/imp).resolve()
        elif imp.startswith('package:africa_link/'):
            target=(ROOT/'lib'/imp.split('/',1)[1]).resolve()
        if target is not None and not target.is_file():
            errors.append(f'Missing Dart import: {dart_file.relative_to(ROOT)} -> {imp}')

# Verify the production docs mention the critical release gates.
doc=(ROOT/'docs/DEPLOYMENT.md').read_text(errors='ignore')
for phrase in ['RLS review','backup restore test','push-delivery test','end-to-end smoke tests']:
    if phrase not in doc: errors.append(f'Missing deployment gate: {phrase}')

# The GitHub workflow must install Flutter, analyze, test, and build an APK.
workflow=ROOT/'.github/workflows/flutter.yml'
if not workflow.is_file():
    errors.append('Missing GitHub Actions workflow: .github/workflows/flutter.yml')
else:
    wf=workflow.read_text(errors='ignore')
    for phrase in ['subosito/flutter-action@v2','flutter pub get','flutter analyze','flutter test','flutter build apk']:
        if phrase not in wf: errors.append(f'Missing CI step: {phrase}')


# Required project hygiene and release contract files.
for required in ['.gitignore', 'analysis_options.yaml', 'README.md', 'docs/DEPLOYMENT.md', 'docs/RELEASE_CHECKLIST.md']:
    if not (ROOT / required).is_file():
        errors.append(f'Missing required project file: {required}')

# The release candidate version must be consistent across the package and README.
pub_text = pub.read_text(errors='ignore')
if 'version: 1.4.0+16' not in pub_text:
    errors.append('Expected release version 1.4.0+16')
readme_text = (ROOT/'README.md').read_text(errors='ignore')
if not readme_text.startswith('# AFRICA LINK v1.4'):
    errors.append('README release header is not v1.4')

# Release-blocking Dart/API contracts found during the pre-GitHub review.
for forbidden in ['FunctionsException(']:
    for dart_file in ROOT.rglob('*.dart'):
        if forbidden in dart_file.read_text(errors='ignore'):
            errors.append(f'Unsupported Dart API remains: {forbidden} in {dart_file.relative_to(ROOT)}')

opp = (ROOT/'lib/repositories/opportunity_repository.dart').read_text(errors='ignore')
if "'user_id': uid" not in opp:
    errors.append('Opportunity save must include authenticated user_id for RLS')

# Migration 012 is the final pre-GitHub hardening layer.
m012 = ROOT/'supabase/migrations/012_pre_github_hardening.sql'
if not m012.is_file():
    errors.append('Missing migration 012_pre_github_hardening.sql')
else:
    msql = m012.read_text(errors='ignore')
    for phrase in [
        'admin_note', 'updated_at', 'admin safety reports read',
        'can_view_profile', 'allow_connection_requests',
        'allow_direct_messages', 'africa link storage read own',
        'revoke all on function public.notify_user',
        'set search_path=public,pg_temp',
    ]:
        if phrase not in msql:
            errors.append(f'Migration 012 missing hardening contract: {phrase}')

# Required Supabase Edge Function boundaries must exist. They are deployment stubs,
# not proof of provider integration.
for fn in ['ai-proxy/index.ts', 'notify-push/index.ts', 'payment-webhook/index.ts']:
    if not (ROOT/'supabase/functions'/fn).is_file():
        errors.append(f'Missing Edge Function boundary: supabase/functions/{fn}')

# Lightweight Dart lexical balance check catches malformed source even when Flutter SDK is absent.
def dart_balance_ok(source):
    stack=[]; i=0; state='code'; quote=''
    pairs={')':'(',']':'[','}':'{'}
    while i < len(source):
        c=source[i]; n=source[i+1] if i+1 < len(source) else ''
        if state=='code':
            if c=='/' and n=='/': state='line'; i+=2; continue
            if c=='/' and n=='*': state='block'; i+=2; continue
            if c in "'\"": quote=c; state='string'; i+=1; continue
            if c in '([{': stack.append(c)
            elif c in ')]}':
                if not stack or stack[-1] != pairs[c]: return False
                stack.pop()
            i+=1
        elif state=='line':
            if c=='\n': state='code'
            i+=1
        elif state=='block':
            if c=='*' and n=='/': state='code'; i+=2
            else: i+=1
        else:
            if c=='\\': i+=2; continue
            if c==quote: state='code'
            i+=1
    return state=='code' and not stack

for dart_file in list((ROOT/'lib').rglob('*.dart')) + list((ROOT/'test').rglob('*.dart')):
    if not dart_balance_ok(dart_file.read_text(errors='ignore')):
        errors.append(f'Dart delimiter/syntax balance failure: {dart_file.relative_to(ROOT)}')

print(f'AFRICA LINK static audit: {len(errors)} error(s), {len(warnings)} warning(s)')
for x in errors: print('ERROR:',x)
for x in warnings: print('WARN :',x)
if errors: sys.exit(1)
