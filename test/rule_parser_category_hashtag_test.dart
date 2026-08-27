import 'package:flutter_test/flutter_test.dart';
import 'package:salin/core/ai/rule_parser.dart';

// Covers backlog item 6 (docs/SPRINTS.md Sprint 7): #category hashtag
// resolution must be "smart" — not exact-match-only. It should understand
// shorthand/truncations (e.g. #transpo -> Transportation) and common
// synonyms, while never fabricating a category id for something it can't
// reasonably resolve.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final parser = RuleParser();

  group('Exact tag matches (unchanged behavior)', () {
    test('#transport resolves to cat_transport', () async {
      final res = await parser.parseTransaction('150 grab ride #transport');
      expect(res.parsedPayload.first.category, 'cat_transport');
    });

    test('#food resolves to cat_food', () async {
      final res = await parser.parseTransaction('150 snacks #food');
      expect(res.parsedPayload.first.category, 'cat_food');
    });
  });

  group('Spec-name aliases', () {
    test('#dorm resolves to cat_rent', () async {
      final res = await parser.parseTransaction('5000 monthly #dorm');
      expect(res.parsedPayload.first.category, 'cat_rent');
    });

    test('#leisure resolves to cat_entertainment', () async {
      final res = await parser.parseTransaction('300 movie night #leisure');
      expect(res.parsedPayload.first.category, 'cat_entertainment');
    });

    test('#academics resolves to cat_utilities', () async {
      final res = await parser.parseTransaction('200 school stuff #academics');
      expect(res.parsedPayload.first.category, 'cat_utilities');
    });
  });

  group('Shorthand / truncation via prefix matching', () {
    test('#transpo resolves to cat_transport', () async {
      final res = await parser.parseTransaction('150 grab ride #transpo');
      expect(res.parsedPayload.first.category, 'cat_transport');
    });

    test('#ent resolves to cat_entertainment', () async {
      final res = await parser.parseTransaction('300 arcade #ent');
      expect(res.parsedPayload.first.category, 'cat_entertainment');
    });

    test('#util resolves to cat_utilities', () async {
      final res = await parser.parseTransaction('800 electric bill #util');
      expect(res.parsedPayload.first.category, 'cat_utilities');
    });
  });

  group('Synonym aliases beyond the original spec names', () {
    test('#grocery resolves to cat_food', () async {
      final res = await parser.parseTransaction('600 sm supermarket #grocery');
      expect(res.parsedPayload.first.category, 'cat_food');
    });

    test('#commute resolves to cat_transport', () async {
      final res = await parser.parseTransaction('50 jeepney #commute');
      expect(res.parsedPayload.first.category, 'cat_transport');
    });

    test('#wifi resolves to cat_utilities', () async {
      final res = await parser.parseTransaction('1500 pldt #wifi');
      expect(res.parsedPayload.first.category, 'cat_utilities');
    });
  });

  group('Unrecognized tags never fabricate a category', () {
    test('a nonsense tag falls back to null (Uncategorized), not a dangling id', () async {
      final res = await parser.parseTransaction('150 something #xyzzy');
      expect(res.parsedPayload.first.category, isNull);
    });

    test('a very short tag does not prefix-match too eagerly', () async {
      final res = await parser.parseTransaction('150 something #re');
      expect(res.parsedPayload.first.category, isNull);
    });
  });
}
