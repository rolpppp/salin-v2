import 'package:flutter_test/flutter_test.dart';
import 'package:salin/core/ai/ai_service.dart';
import 'package:salin/core/ai/gemini_cloud_provider.dart';
import 'package:salin/core/ai/rule_parser.dart';

void main() {
  group('RuleParser Tests', () {
    final parser = RuleParser();

    test('Parse "Lunch 180"', () async {
      final res = await parser.parseTransaction('Lunch 180');
      expect(res.provider, 'Rule Parser');
      expect(res.parsedPayload.first.description, 'Lunch');
      expect(res.parsedPayload.first.amountMinor, 18000);
      expect(res.parsedPayload.first.transactionType, 'expense');
      expect(res.parsedPayload.first.category, 'food');
      expect(res.parsedPayload.first.notes, isNull); // High confidence / exact format
    });

    test('Parse "Grab 250"', () async {
      final res = await parser.parseTransaction('Grab 250');
      expect(res.parsedPayload.first.description, 'Grab');
      expect(res.parsedPayload.first.amountMinor, 25000);
      expect(res.parsedPayload.first.transactionType, 'expense');
      expect(res.parsedPayload.first.category, 'transport');
      expect(res.parsedPayload.first.notes, isNull);
    });

    test('Parse "Salary 12000"', () async {
      final res = await parser.parseTransaction('Salary 12000');
      expect(res.parsedPayload.first.description, 'Salary');
      expect(res.parsedPayload.first.amountMinor, 1200000);
      expect(res.parsedPayload.first.transactionType, 'income');
      expect(res.parsedPayload.first.category, 'salary');
      expect(res.parsedPayload.first.notes, isNull);
    });

    test('Parse "180 Lunch"', () async {
      final res = await parser.parseTransaction('180 Lunch');
      expect(res.parsedPayload.first.description, 'Lunch');
      expect(res.parsedPayload.first.amountMinor, 18000);
      expect(res.parsedPayload.first.transactionType, 'expense');
      expect(res.parsedPayload.first.category, 'food');
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
      expect(res.parsedPayload.first.category, 'transport');
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
      expect(res.parsedPayload.first.category, 'food');
      expect(res.parsedPayload.first.notes, 'needs_review');
    });

    test('Parse "Salary from company 15000"', () async {
      final res = await provider.parseTransaction('Salary from company 15000');
      expect(res.provider, 'Rule Parser'); // degrades to RuleParser fallback
      expect(res.parsedPayload.first.description, 'Salary from company');
      expect(res.parsedPayload.first.amountMinor, 1500000);
      expect(res.parsedPayload.first.transactionType, 'income');
      expect(res.parsedPayload.first.category, 'salary');
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
}
