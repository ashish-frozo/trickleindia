#!/usr/bin/env python3
"""Offline reviewed-pack builder. Does not activate languages or certify field acceptance."""
import argparse
import csv
import hashlib
import json
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LOCALES = {'or': 'or-Orya-IN', 'hoc': 'hoc-Wara-IN', 'sat': 'sat-Olck-IN'}
FIELDS = ['key', 'source', 'translation', 'reviewer', 'status']


def require(condition, message):
    if not condition:
        raise ValueError(message)


def canonical(value):
    return json.dumps(value, ensure_ascii=False, sort_keys=True, indent=2) + '\n'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def sources(root=ROOT):
    en = json.loads((root / 'packages/ui/assets/ui_en.arb').read_text())
    cards = json.loads((root / 'packages/ui/assets/content_cards.json').read_text())
    source = {f'ui.{k}': v for k, v in en.items() if not k.startswith('@')}
    for card in cards['cards']:
        for key in ['title', 'audioScript']:
            source[f"help.{card['id']}.{key}"] = card['locales']['en'][key]
        for i, step in enumerate(card['locales']['en']['steps']):
            source[f"help.{card['id']}.steps.{i}"] = step
    return source, en, cards


def placeholders(text):
    # Preserve argument occurrences and ICU plural/select branch selectors.
    depth = 0
    for char in text:
        if char == '{': depth += 1
        elif char == '}': depth -= 1
        require(depth >= 0, 'Malformed placeholder braces')
    require(depth == 0, 'Malformed placeholder braces')
    branch_opens = {m.end() - 1 for m in re.finditer(r'(?:=\d+|zero|one|two|few|many|other)\s*\{', text)}
    arguments = [m.group(1) for m in re.finditer(r'\{([A-Za-z_][A-Za-z0-9_]*)\s*(?:\}|,)', text) if m.start() not in branch_opens]
    types = re.findall(r'\{[A-Za-z_][A-Za-z0-9_]*\s*,\s*(plural|select|selectordinal)\s*,', text)
    selectors = re.findall(r'(=\d+|zero|one|two|few|many|other)\s*\{', text) if types else []
    return Counter(['arg:' + x for x in arguments] + ['type:' + x for x in types] + ['branch:' + x for x in selectors])


def validate(path, source):
    with path.open(newline='', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        require(reader.fieldnames == FIELDS, 'Unexpected CSV columns')
        rows = list(reader)
    require(len({x['key'] for x in rows}) == len(rows), 'Duplicate keys')
    require({x['key'] for x in rows} == set(source), 'Missing or unexpected keys')
    for row in rows:
        key = row['key']
        require(row['source'] == source[key], f'Stale source: {key}')
        require(bool(row['translation'] and row['translation'].strip() and row['reviewer'] and row['reviewer'].strip() and row['status'] == 'reviewed'), f'Not reviewed: {key}')
        require(placeholders(row['translation']) == placeholders(source[key]), f'Placeholder mismatch: {key}')
    return {row['key']: row for row in rows}


def validate_audio(manifest, pack, locale):
    data = json.loads(manifest.read_text(encoding='utf-8'))
    require(data.get('locale') == locale, 'Audio locale mismatch')
    clips = data.get('clips')
    require(isinstance(clips, list) and bool(clips), 'Audio clips required')
    seen = set()
    for clip in clips:
        for field in ['path', 'speaker', 'permissionEvidence', 'reviewer', 'reviewEvidence']:
            require(isinstance(clip.get(field), str) and bool(clip[field].strip()), f'Missing audio {field}')
        require(clip.get('status') == 'reviewed', 'Audio not reviewed')
        relative = Path(clip['path'])
        require(not relative.is_absolute() and '..' not in relative.parts, 'Unsafe audio path')
        path = (pack / relative).resolve()
        require(path.is_relative_to(pack.resolve()) and path.is_file(), 'Audio outside pack or missing')
        require(str(relative) not in seen, 'Duplicate audio path')
        seen.add(str(relative))
        body = path.read_bytes()
        formats = {'.wav': ('audio/wav', body[:4] == b'RIFF' and body[8:12] == b'WAVE'), '.mp3': ('audio/mpeg', body[:3] == b'ID3' or (len(body) > 1 and body[0] == 255 and body[1] & 224 == 224)), '.ogg': ('audio/ogg', body[:4] == b'OggS')}
        require(path.suffix.lower() in formats, 'Unsupported audio extension')
        mime, magic = formats[path.suffix.lower()]
        require(clip.get('mediaType') == mime and magic, 'Invalid audio media signature/type')
        require(type(clip.get('sizeBytes')) is int and clip['sizeBytes'] == len(body) and len(body) > 12, 'Audio size mismatch')
        require(clip.get('sha256') == digest(body), 'Audio digest mismatch')
    return data


def build(path, language, output, source, en, cards):
    rows = validate(path, source)
    require(not output.exists(), 'Output already exists; never overwrite an existing pack')
    arb = {k: v for k, v in en.items() if k.startswith('@')}
    arb['@@locale'] = LOCALES[language]
    arb.update({key[3:]: row['translation'] for key, row in rows.items() if key.startswith('ui.')})
    help_cards = []
    for card in cards['cards']:
        prefix = f"help.{card['id']}."
        help_cards.append({'id': card['id'], 'locales': {LOCALES[language]: {
            'title': rows[prefix + 'title']['translation'],
            'audioScript': rows[prefix + 'audioScript']['translation'],
            'steps': [rows[prefix + f'steps.{i}']['translation'] for i in range(len(card['locales']['en']['steps']))]}}})
    files = {f'ui_{language}.arb': canonical(arb), 'help.json': canonical({'cards': help_cards})}
    manifest = {'schemaVersion': 1, 'locale': LOCALES[language], 'script': LOCALES[language].split('-')[1], 'status': 'reviewed-not-activated', 'sourceSha256': digest(canonical(source).encode()), 'worksheetSha256': digest(path.read_bytes()), 'reviewers': sorted({r['reviewer'].strip() for r in rows.values()}), 'entryCount': len(rows), 'files': {k: digest(v.encode()) for k, v in files.items()}, 'remainingGates': ['script/font rendering', 'participant task testing', 'recorded audio consent and listening review']}
    output.mkdir(parents=True)
    for name, text in files.items():
        (output / name).write_text(text, encoding='utf-8')
    (output / 'manifest.json').write_text(canonical(manifest), encoding='utf-8')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['export', 'validate', 'build', 'validate-audio'])
    parser.add_argument('--language', choices=LOCALES, required=True)
    parser.add_argument('--file', type=Path, required=True)
    parser.add_argument('--output', type=Path, help='New output directory for build; pack root for validate-audio')
    a = parser.parse_args()
    try:
        if a.action == 'validate-audio':
            require(a.output is not None, '--output pack directory required')
            validate_audio(a.file, a.output, LOCALES[a.language])
        else:
            source, en, cards = sources()
            if a.action == 'export':
                a.file.parent.mkdir(parents=True, exist_ok=True)
                with a.file.open('w', newline='', encoding='utf-8') as f:
                    writer = csv.DictWriter(f, fieldnames=FIELDS, lineterminator='\n')
                    writer.writeheader()
                    writer.writerows(dict(key=k, source=v, translation='', reviewer='', status='needs-translation') for k, v in source.items())
            elif a.action == 'validate':
                validate(a.file, source)
            else:
                require(a.output is not None, '--output new directory required')
                build(a.file, a.language, a.output, source, en, cards)
        print(f'{a.action}: PASS ({LOCALES[a.language]}). Field acceptance and activation remain separate.')
    except (ValueError, OSError, KeyError, TypeError, csv.Error) as error:
        parser.exit(1, f'Rejected: {error}\n')


if __name__ == '__main__':
    main()
