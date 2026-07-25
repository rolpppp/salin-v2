class PromptBuilder {
  static String buildQuickAddPrompt(String input) {
    return '''
You are an expert financial transaction parser for Salin.
Extract the transaction details from this raw text: "$input".
Output raw JSON matching this format:
{
  "amount_minor": integer amount in cents/minor units (e.g. 100 pesos = 10000),
  "merchant": "merchant name or null",
  "occurred_at": "ISO 8601 UTC timestamp or null",
  "category_name": "Food", "Transport", "Rent", etc. or null,
  "direction": "inflow" or "outflow"
}
''';
  }
}
