import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:salin/core/ai/ai_service.dart';
import 'package:salin/core/ai/ai_validator.dart';
import 'package:salin/core/ai/gemini_cloud_provider.dart';
import 'package:salin/core/ai/rule_parser.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // AIService checks the Cloud AI consent setting (backed by
  // SharedPreferences) whenever RuleParser's result isn't fully exact —
  // mock it here so that path doesn't hit an uninitialized plugin channel.
  SharedPreferences.setMockInitialValues({});

  group('RuleParser Tests', () {
    final parser = RuleParser();

    test('Parse "Lunch 180"', () async {
      final res = await parser.parseTransaction('Lunch 180');
      expect(res.provider, 'Rule Parser');
      expect(res.parsedPayload.first.description, 'Lunch');
      expect(res.parsedPayload.first.amountMinor, 18000);
      expect(res.parsedPayload.first.transactionType, 'expense');
      expect(res.parsedPayload.first.category, 'cat_food');
      expect(res.parsedPayload.first.notes, isNull); // High confidence / exact format
    });

    test('Parse "Grab 250"', () async {
      final res = await parser.parseTransaction('Grab 250');
      expect(res.parsedPayload.first.description, 'Grab');
      expect(res.parsedPayload.first.amountMinor, 25000);
      expect(res.parsedPayload.first.transactionType, 'expense');
      expect(res.parsedPayload.first.category, 'cat_transport');
      expect(res.parsedPayload.first.notes, isNull);
    });

    test('Parse "Salary 12000"', () async {
      final res = await parser.parseTransaction('Salary 12000');
      expect(res.parsedPayload.first.description, 'Salary');
      expect(res.parsedPayload.first.amountMinor, 1200000);
      expect(res.parsedPayload.first.transactionType, 'income');
      expect(res.parsedPayload.first.category, 'cat_salary');
      expect(res.parsedPayload.first.notes, isNull);
    });

    test('Parse "180 Lunch"', () async {
      final res = await parser.parseTransaction('180 Lunch');
      expect(res.parsedPayload.first.description, 'Lunch');
      expect(res.parsedPayload.first.amountMinor, 18000);
      expect(res.parsedPayload.first.transactionType, 'expense');
      expect(res.parsedPayload.first.category, 'cat_food');
      expect(res.parsedPayload.first.notes, isNull);
    });

    test('Parse Multiple simple transactions', () async {
      final res = await parser.parseTransaction('Lunch 180\nGrab 250');
      expect(res.parsedPayload.length, 2);
      expect(res.parsedPayload[0].description, 'Lunch');
      expect(res.parsedPayload[1].description, 'Grab');
    });

    test('Best-effort parse on invalid format "Spent 150 on coffee"', () async {
      final res = await parser.parseTransaction('Spent 150 on coffee');
      expect(res.parsedPayload.first.description, 'Spent on coffee');
      expect(res.parsedPayload.first.amountMinor, 15000);
      expect(res.parsedPayload.first.notes, 'needs_review'); // Best effort / needs review flag
    });

    test('Throw on line with no numbers "Spent nothing on coffee"', () {
      expect(
        () => parser.parseTransaction('Spent nothing on coffee'),
        throwsFormatException,
      );
    });

    test('Parse #category tags override keyword guessing', () async {
      final res = await parser.parseTransaction('150 grab ride #transport');
      expect(res.parsedPayload.first.description, 'grab ride');
      expect(res.parsedPayload.first.amountMinor, 15000);
      expect(res.parsedPayload.first.category, 'cat_transport');
      expect(res.parsedPayload.first.notes, isNull); // Exact match formatting
    });

    test('Skipping empty/unparseable lines without creating ghost transactions', () async {
      // Line 1 has number, line 2 is fluff, line 3 has number
      final res = await parser.parseTransaction('150 lunch\nhey this has no numbers\n250 grab');
      expect(res.parsedPayload.length, 2);
      expect(res.parsedPayload[0].description, 'lunch');
      expect(res.parsedPayload[0].amountMinor, 15000);
      expect(res.parsedPayload[1].description, 'grab');
      expect(res.parsedPayload[1].amountMinor, 25000);
    });
  });

  group('GeminiCloudProvider Tests (Fallback Mode)', () {
    final provider = GeminiCloudProvider();

    test('Parse complex "Spent 150 on coffee at Ozone yesterday"', () async {
      final res = await provider.parseTransaction('Spent 150 on coffee at Ozone yesterday');
      expect(res.provider, 'Rule Parser'); // degrades to RuleParser fallback
      expect(res.parsedPayload.first.description, 'Spent on coffee at Ozone yesterday');
      expect(res.parsedPayload.first.amountMinor, 15000);
      expect(res.parsedPayload.first.transactionType, 'expense');
      expect(res.parsedPayload.first.category, 'cat_food');
      expect(res.parsedPayload.first.notes, 'needs_review');
    });

    test('Parse "Salary from company 15000"', () async {
      final res = await provider.parseTransaction('Salary from company 15000');
      expect(res.provider, 'Rule Parser'); // degrades to RuleParser fallback
      expect(res.parsedPayload.first.description, 'Salary from company');
      expect(res.parsedPayload.first.amountMinor, 1500000);
      expect(res.parsedPayload.first.transactionType, 'income');
      expect(res.parsedPayload.first.category, 'cat_salary');
      expect(res.parsedPayload.first.notes, isNull); // matches <desc> <amt> exact format
    });

    test('Parse Multiple complex transactions', () async {
      final res = await provider.parseTransaction('Spent 150 on coffee yesterday\nReceived salary of 50000');
      expect(res.parsedPayload.length, 2);
      expect(res.parsedPayload[0].description, 'Spent on coffee yesterday');
      expect(res.parsedPayload[1].description, 'Received salary of');
    });
  });

  group('AIService Integration Tests', () {
    final service = AIService();

    test('Chain resolves simple query with RuleParser', () async {
      final res = await service.parseTransaction('Lunch 180');
      expect(res.isSuccess, true);
      expect(res.provider, 'Rule Parser');
      expect(res.parsedData!.first.description, 'Lunch');
      expect(res.parsedData!.first.amountMinor, 18000);
    });

    test('Chain resolves complex query with fallback RuleParser when offline', () async {
      final res = await service.parseTransaction('Spent 150 on coffee at Ozone yesterday');
      expect(res.isSuccess, true);
      expect(res.provider, 'Rule Parser'); // falls back to rule parser
      expect(res.parsedData!.first.description, 'Spent on coffee at Ozone yesterday');
      expect(res.parsedData!.first.amountMinor, 15000);
    });
  });

  group('Onboarding regression guard', () {
    // Onboarding page 3 ("Type it like a note.") teaches the exact string
    // "Lunch 180" and shows a rehearsal of the exact snackbar
    // "Saved ₱180.00 · Lunch → Cash" as what happens when you type it — a
    // literal, falsifiable product claim. This test locks the full chain
    // (RuleParser output + AIValidator warnings) so a future change to
    // either file can't silently turn that promise into a lie without a
    // test failure. If this test needs to change, onboarding's copy in
    // lib/features/onboarding/presentation/widgets/onboarding_page_three.dart
    // must be reviewed and updated in the same change.
    test('"Lunch 180" parses confidently and is warning-free (auto-save eligible)', () async {
      final result = await RuleParser().parseTransaction('Lunch 180');
      final parsed = result.parsedPayload.single;

      expect(parsed.description, 'Lunch');
      expect(parsed.amountMinor, 18000); // ₱180.00
      expect(parsed.transactionType, 'expense');
      expect(parsed.category, 'cat_food');
      expect(parsed.notes, isNull); // exact-format match, not needs_review

      // These are precisely the conditions quick_add_view.dart's
      // _handleParse checks before auto-saving instead of staging a review
      // card: exactly one parsed item, and zero validator warnings.
      expect(result.parsedPayload.length, 1);
      expect(AIValidator.validate(parsed), isEmpty);
    });
  });
}
