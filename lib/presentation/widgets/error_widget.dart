import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';

class CustomErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final String? customMessage;

  const CustomErrorWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              customMessage ?? _getErrorMessage(error),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppConstants.largePadding),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ]
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(String error) {
    // Try to parse if it's a Failure object
    if (error.contains('ServerFailure')) {
      return 'Server error occurred. Please try again later.';
    } else if (error.contains('NetworkFailure')) {
      return 'Network connection failed. Please check your internet connection.';
    } else if (error.contains('CacheFailure')) {
      return 'Local storage error occurred.';
    } else if (error.contains('ValidationFailure')) {
      return 'Invalid input provided. Please check your data.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }
}