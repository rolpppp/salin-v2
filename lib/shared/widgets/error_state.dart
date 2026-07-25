import 'package:flutter/material.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final String? technicalDetails;
  final VoidCallback? onRetry;

  const ErrorState({
    super.key,
    required this.message,
    this.technicalDetails,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: 'PublicSans',
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            if (technicalDetails != null) ...[
              const SizedBox(height: 12),
              Text(
                technicalDetails!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFamily: 'IBMPlexMono',
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                  foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(fontFamily: 'PublicSans'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
