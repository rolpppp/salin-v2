import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salin/core/ai/ai_validator.dart';
import 'package:salin/core/ai/rule_parser.dart';

// Covers docs/NEXT_ITERATION.md's Core Value Proposition revision (adopted
// 2026-08-26): the AI review gate narrows to amount + income/expense
// direction only. A best-effort parse with a single, unambiguous number
// must no longer block confirmation — only a line with more than one
// number (genuine amount ambiguity) should.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  final parser = RuleParser();

  group('RuleParser amount-ambiguity classification', () {
    test('Single unambiguous number on a non-exact-format line is marked needs_review, not ambiguous_amount', () async {
      final res = await parser.parseTransaction('Spent 150 on coffee');
      expect(res.parsedPayload.first.notes, 'needs_review');
    });

    test('Multiple numbers on a line are marked ambiguous_amount', () async {
      final res = await parser.parseTransaction('Owed 500 but paid back 150 for dinner');
      expect(res.parsedPayload.first.notes, 'ambiguous_amount');
    });

    test('Exact <amount> <description> format is fully confident (null notes)', () async {
      final res = await parser.parseTransaction('Lunch 180');
      expect(res.parsedPayload.first.notes, isNull);
    });
  });

  group('AIValidator only blocks on ambiguous_amount', () {
    test('needs_review (unambiguous best-effort parse) produces no warnings', () async {
      final res = await parser.parseTransaction('Spent 150 on coffee');
      final warnings = AIValidator.validate(res.parsedPayload.first);
      expect(warnings, isEmpty);
    });

    test('ambiguous_amount (multiple numbers) produces a blocking warning', () async {
      final res = await parser.parseTransaction('Owed 500 but paid back 150 for dinner');
      final warnings = AIValidator.validate(res.parsedPayload.first);
      expect(warnings, isNotEmpty);
    });

    test('exact format produces no warnings', () async {
      final res = await parser.parseTransaction('Lunch 180');
      final warnings = AIValidator.validate(res.parsedPayload.first);
      expect(warnings, isEmpty);
    });
  });
}
