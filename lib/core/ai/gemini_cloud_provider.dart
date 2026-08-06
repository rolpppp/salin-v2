import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';
import 'ai_provider.dart';
import 'inference_result.dart';
import 'parsed_transaction.dart';
import 'rule_parser.dart';

class GeminiCloudProvider implements AIProvider {
  @override
  String get name => 'Gemini Cloud';

  @override
  Future<InferenceResult<List<ParsedTransaction>>> parseTransaction(String input) async {
    final startTime = DateTime.now();
    final trimmed = input.trim();

    // Use gemini-3.1-flash-lite as the current low-latency model for structured extraction tasks
    const modelName = 'gemini-3.1-flash-lite';

    // If API Key is configured, attempt actual call to Google Gemini REST API
    if (AIConfig.hasApiKey) {
      try {
        final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=${AIConfig.geminiApiKey}',
        );

        final requestBody = {
          'contents': [
            {
              'parts': [
                {
                  'text': 'You are a strict, precise financial data extraction engine for a college budgeting app. Your sole job is to read the user\'s input, identify every distinct financial transaction (income or expense), and output them as a structured JSON array.\n\nRULES:\n'
                      '1. MULTIPLE TRANSACTIONS: A user may log multiple transactions in one sentence. You must extract EVERY distinct transaction into its own separate object within the JSON array.\n'
                      '2. IGNORE FLUFF: Ignore filler, complaints, emotional text. Do not log empty entries.\n'
                      '3. CONTEXTUAL TITLES: Create a concise, 2-to-4 word title for each transaction.\n'
                      '4. CATEGORIES: You may ONLY use: Food, Transport, Academics, Dorm, Leisure, Income, Uncategorized.\n'
                      '5. Input text to parse:\n\n"$trimmed"'
                }
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
            'responseSchema': {
              'type': 'ARRAY',
              'items': {
                'type': 'OBJECT',
                'properties': {
                  'title': {'type': 'STRING'},
                  'amount': {'type': 'NUMBER'},
                  'category': {
                    'type': 'STRING',
                    'enum': ['Food', 'Transport', 'Academics', 'Dorm', 'Leisure', 'Income', 'Uncategorized']
                  },
                  'type': {
                    'type': 'STRING',
                    'enum': ['expense', 'income']
                  }
                },
                'required': ['title', 'amount', 'category', 'type']
              }
            }
          }
        };

        http.Response response;
        try {
          // Attempt 1 with 3 seconds timeout
          response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          ).timeout(const Duration(seconds: 3));
        } catch (e) {
          debugPrint('Gemini Cloud API call failed: $e. Retrying once...');
          // Retry 1 with 3 seconds timeout
          response = await http.post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          ).timeout(const Duration(seconds: 3));
        }

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          final candidates = responseBody['candidates'] as List<dynamic>;
          if (candidates.isNotEmpty) {
            final firstCandidate = candidates.first;
            final text = firstCandidate['content']['parts'].first['text'] as String;
            
            // Clean markdown wrappers just in case the model returns wrapped JSON
            final cleanText = _cleanMarkdownJson(text);
            final txList = jsonDecode(cleanText) as List<dynamic>;

            final parsedTransactions = txList.map((item) {
              final categoryName = (item['category'] as String? ?? 'Uncategorized').toLowerCase();
              final double amtVal = (item['amount'] as num? ?? 0.0).toDouble();
              final amountMinor = (amtVal * 100).round();

              return ParsedTransaction(
                description: item['title'] as String? ?? 'Quick Add',
                amountMinor: amountMinor > 0 ? amountMinor : null,
                currency: 'PHP',
                transactionType: item['type'] as String? ?? 'expense',
                category: categoryName == 'uncategorized' ? null : categoryName,
                transactionDate: DateTime.now().toUtc(),
              );
            }).toList();

            final latency = DateTime.now().difference(startTime);
            return InferenceResult<List<ParsedTransaction>>(
              provider: name,
              model: modelName,
              latency: latency,
              finishReason: 'stop',
              safetyFlags: const {},
              usage: const {},
              rawResponse: response.body,
              parsedPayload: parsedTransactions,
            );
          }
        } else {
          debugPrint('Gemini API call failed with status code ${response.statusCode}: ${response.body}');
        }
      } catch (e) {
        debugPrint('Gemini Cloud API call failed after retry: $e. Falling back to RuleParser.');
      }
    } else {
      debugPrint('Gemini Cloud: API key is not configured or is empty. Falling back to RuleParser.');
    }

    // Fallback to RuleParser on failure or if key is missing
    return RuleParser().parseTransaction(trimmed);
  }

  String _cleanMarkdownJson(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      s = s.replaceAll(RegExp(r'^```(?:json)?\n?|```$'), '');
    }
    return s.trim();
  }
}