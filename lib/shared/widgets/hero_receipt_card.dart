import 'package:flutter/material.dart';
import 'money_text.dart';

class HeroReceiptCard extends StatelessWidget {
  final String title;
  final int amountMinor;
  final String? subtitle;
  final List<Widget>? children;

  const HeroReceiptCard({
    super.key,
    required this.title,
    required this.amountMinor,
    this.subtitle,
    this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontFamily: 'PublicSans',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                      ),
                ),
                const SizedBox(height: 12),
                MoneyText(
                  amountMinor: amountMinor,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'PublicSans',
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                        ),
                  ),
                ],
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Row(
              children: List.generate(
                30,
                (index) => Expanded(
                  child: Container(
                    color: index % 2 == 0
                        ? Colors.transparent
                        : Theme.of(context).colorScheme.onBackground.withOpacity(0.15),
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ),
          
          if (children != null && children!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0, left: 24.0, right: 24.0),
              child: Column(
                children: children!,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
