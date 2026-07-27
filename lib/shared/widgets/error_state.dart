import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ErrorState extends StatelessWidget {
  final String errorMessage;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ErrorState({
    super.key,
    required this.errorMessage,
    this.actionLabel = 'Retry',
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppTheme.inkRed.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.inkRed.withOpacity(0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.inkRed.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppTheme.inkRed,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.carbonText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage,
                style: TextStyle(
                  fontFamily: 'PublicSans',
                  fontSize: 13,
                  color: AppTheme.carbonText.withOpacity(0.6),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (onAction != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.inkRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    actionLabel!,
                    style: const TextStyle(
                      fontFamily: 'PublicSans',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
