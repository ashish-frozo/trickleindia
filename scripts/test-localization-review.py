#!/usr/bin/env python3
"""Synthetic test fixtures only: no reviewed translations or participant recordings."""
import csv
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
import wave

spec = importlib.util.spec_from_file_location('review', Path(__file__).with_name('localization-review.py'))
review = importlib.util.module_from_spec(spec)
spec.loader.exec_module(review)


class ReviewTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.csv = self.root / 'test-only.csv'
        self.source = {'ui.test': 'Hello {name}', 'help.test.title': 'Title', 'help.test.audioScript': 'Prompt', 'help.test.steps.0': 'Step'}
        self.rows = [dict(key=k, source=v, translation=v, reviewer='synthetic-test-reviewer', status='reviewed') for k, v in self.source.items()]
        self.write()

    def write(self):
        with self.csv.open('w', newline='') as f:
            w = csv.DictWriter(f, fieldnames=review.FIELDS)
            w.writeheader()
            w.writerows(self.rows)

    def test_negative_worksheets(self):
        for case in ['stale', 'missing', 'duplicate', 'placeholder', 'unreviewed', 'reviewer', 'malformed']:
            with self.subTest(case=case):
                original = [dict(r) for r in self.rows]
                if case == 'stale': self.rows[0]['source'] = 'Old source'
                elif case == 'missing': self.rows.pop()
                elif case == 'duplicate': self.rows.append(dict(self.rows[0]))
                elif case == 'placeholder': self.rows[0]['translation'] = 'Hello {wrong}'
                elif case == 'unreviewed': self.rows[0]['status'] = 'draft'
                elif case == 'reviewer': self.rows[0]['reviewer'] = ' '
                else: self.rows[0]['translation'] = 'Hello {name'
                self.write()
                with self.assertRaises(ValueError): review.validate(self.csv, self.source)
                self.rows = original
        self.write()
        self.assertEqual(len(review.validate(self.csv, self.source)), 4)

    def test_plural_arguments_and_branches(self):
        source = '{count, plural, =0{None} other{{count} entries}}'
        translated = '{count, plural, =0{Zero} other{{count} items}}'
        self.assertEqual(review.placeholders(source), review.placeholders(translated))
        self.assertNotEqual(review.placeholders(source), review.placeholders(translated.replace('=0', '=1')))

    def test_deterministic_build_no_overwrite(self):
        en = {'@@locale': 'en', 'test': 'Hello {name}', '@test': {'placeholders': {'name': {}}}}
        cards = {'cards': [{'id': 'test', 'locales': {'en': {'steps': ['Step']}}}]}
        for name in ['one', 'two']:
            review.build(self.csv, 'hoc', self.root / name, self.source, en, cards)
        for p in (self.root / 'one').iterdir():
            self.assertEqual(p.read_bytes(), (self.root / 'two' / p.name).read_bytes())
        self.assertEqual(json.loads((self.root / 'one/ui_hoc.arb').read_text())['@@locale'], 'hoc-Wara-IN')
        with self.assertRaises(ValueError): review.build(self.csv, 'hoc', self.root / 'one', self.source, en, cards)

    def test_audio_validation(self):
        # Deliberate synthetic silence, confined to a temporary test fixture.
        buf = io.BytesIO()
        with wave.open(buf, 'wb') as wav:
            wav.setnchannels(1); wav.setsampwidth(2); wav.setframerate(8000); wav.writeframes(b'\0' * 160)
        body = buf.getvalue()
        (self.root / 'test.wav').write_bytes(body)
        clip = dict(path='test.wav', speaker='test-only', permissionEvidence='test-only', reviewer='test-only', reviewEvidence='test-only', status='reviewed', mediaType='audio/wav', sizeBytes=len(body), sha256=review.digest(body))
        manifest = self.root / 'audio.json'
        def run(c):
            manifest.write_text(json.dumps({'locale': 'or-Orya-IN', 'clips': [c]}))
            return review.validate_audio(manifest, self.root, 'or-Orya-IN')
        run(clip)
        for field, value in [('path', '../test.wav'), ('path', '/tmp/test.wav'), ('path', 'absent.wav'), ('sha256', 'bad'), ('sizeBytes', 0), ('status', 'draft'), ('speaker', ''), ('permissionEvidence', ''), ('reviewer', ''), ('reviewEvidence', ''), ('mediaType', 'text/plain')]:
            with self.subTest(field=field, value=value):
                with self.assertRaises(ValueError): run({**clip, field: value})
        outside = self.root.parent / (self.root.name + '-outside.wav')
        outside.write_bytes(body)
        self.addCleanup(outside.unlink)
        (self.root / 'escape.wav').symlink_to(outside)
        with self.assertRaises(ValueError): run({**clip, 'path': 'escape.wav'})

    def test_current_english_sources_supported(self):
        source, _, _ = review.sources()
        self.assertGreater(len(source), 100)
        for text in source.values(): review.placeholders(text)


if __name__ == '__main__':
    unittest.main()
