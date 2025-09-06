import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
class Failure with _$Failure {
  const factory Failure.server({
    required String message,
    int? statusCode,
  }) = ServerFailure;
  
  const factory Failure.network({
    required String message,
  }) = NetworkFailure;
  
  const factory Failure.database({
    required String message,
  }) = DatabaseFailure;
  
  const factory Failure.validation({
    required String message,
  }) = ValidationFailure;
  
  const factory Failure.unknown({
    required String message,
  }) = UnknownFailure;
}

// Extension to get user-friendly error messages
extension FailureExtension on Failure {
  String get userMessage {
    return when(
      server: (message, statusCode) {
        if (statusCode == 401) {
          return 'Invalid API key. Please check your configuration.';
        } else if (statusCode == 429) {
          return 'Too many requests. Please wait a moment and try again.';
        }
        return 'Server error: $message';
      },
      network: (message) => 'Network connection failed. Please check your internet connection.',
      database: (message) => 'Failed to save data locally. Please try again.',
      validation: (message) => 'Invalid input: $message',
      unknown: (message) => 'An unexpected error occurred: $message',
    );
  }
}