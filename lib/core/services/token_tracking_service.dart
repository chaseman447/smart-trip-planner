import 'package:flutter_riverpod/flutter_riverpod.dart';

class TokenUsage {
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final DateTime timestamp;
  final String requestType;
  final double? estimatedCost;

  const TokenUsage({
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    required this.timestamp,
    required this.requestType,
    this.estimatedCost,
  });

  TokenUsage copyWith({
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
    DateTime? timestamp,
    String? requestType,
    double? estimatedCost,
  }) {
    return TokenUsage(
      promptTokens: promptTokens ?? this.promptTokens,
      completionTokens: completionTokens ?? this.completionTokens,
      totalTokens: totalTokens ?? this.totalTokens,
      timestamp: timestamp ?? this.timestamp,
      requestType: requestType ?? this.requestType,
      estimatedCost: estimatedCost ?? this.estimatedCost,
    );
  }
}

class TokenMetrics {
  final List<TokenUsage> usageHistory;
  final int totalTokensUsed;
  final double totalEstimatedCost;
  final int requestCount;
  final DateTime? lastRequestTime;

  const TokenMetrics({
    required this.usageHistory,
    required this.totalTokensUsed,
    required this.totalEstimatedCost,
    required this.requestCount,
    this.lastRequestTime,
  });

  TokenMetrics copyWith({
    List<TokenUsage>? usageHistory,
    int? totalTokensUsed,
    double? totalEstimatedCost,
    int? requestCount,
    DateTime? lastRequestTime,
  }) {
    return TokenMetrics(
      usageHistory: usageHistory ?? this.usageHistory,
      totalTokensUsed: totalTokensUsed ?? this.totalTokensUsed,
      totalEstimatedCost: totalEstimatedCost ?? this.totalEstimatedCost,
      requestCount: requestCount ?? this.requestCount,
      lastRequestTime: lastRequestTime ?? this.lastRequestTime,
    );
  }

  TokenMetrics addUsage(TokenUsage usage) {
    final newHistory = [...usageHistory, usage];
    // Keep only last 100 entries to prevent memory issues
    if (newHistory.length > 100) {
      newHistory.removeRange(0, newHistory.length - 100);
    }

    return copyWith(
      usageHistory: newHistory,
      totalTokensUsed: totalTokensUsed + usage.totalTokens,
      totalEstimatedCost: totalEstimatedCost + (usage.estimatedCost ?? 0),
      requestCount: requestCount + 1,
      lastRequestTime: usage.timestamp,
    );
  }

  // Get usage for the last 24 hours
  List<TokenUsage> get last24Hours {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    return usageHistory.where((usage) => usage.timestamp.isAfter(cutoff)).toList();
  }

  // Get total tokens used in the last 24 hours
  int get tokensLast24Hours {
    return last24Hours.fold(0, (sum, usage) => sum + usage.totalTokens);
  }

  // Get estimated cost for the last 24 hours
  double get costLast24Hours {
    return last24Hours.fold(0.0, (sum, usage) => sum + (usage.estimatedCost ?? 0));
  }
}

class TokenTrackingService extends StateNotifier<TokenMetrics> {
  TokenTrackingService() : super(const TokenMetrics(
    usageHistory: [],
    totalTokensUsed: 0,
    totalEstimatedCost: 0.0,
    requestCount: 0,
  ));

  // OpenAI GPT-4 pricing (as of 2024)
  static const double gpt4InputCostPer1kTokens = 0.03;
  static const double gpt4OutputCostPer1kTokens = 0.06;
  
  // Gemini pricing (free tier has limits)
  static const double geminiInputCostPer1kTokens = 0.0;
  static const double geminiOutputCostPer1kTokens = 0.0;

  void trackTokenUsage({
    required int promptTokens,
    required int completionTokens,
    required String requestType,
    String? model,
  }) {
    final totalTokens = promptTokens + completionTokens;
    final estimatedCost = _calculateCost(
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      model: model ?? 'gpt-4',
    );

    final usage = TokenUsage(
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      totalTokens: totalTokens,
      timestamp: DateTime.now(),
      requestType: requestType,
      estimatedCost: estimatedCost,
    );

    state = state.addUsage(usage);
  }

  void trackEstimatedUsage({
    required int estimatedTokens,
    required String requestType,
    String? model,
  }) {
    // For cases where we don't have exact prompt/completion breakdown
    final promptTokens = (estimatedTokens * 0.7).round(); // Estimate 70% prompt
    final completionTokens = estimatedTokens - promptTokens;
    
    trackTokenUsage(
      promptTokens: promptTokens,
      completionTokens: completionTokens,
      requestType: requestType,
      model: model,
    );
  }

  double _calculateCost({
    required int promptTokens,
    required int completionTokens,
    required String model,
  }) {
    if (model.toLowerCase().contains('gemini')) {
      // Gemini is currently free for most usage
      return (promptTokens / 1000) * geminiInputCostPer1kTokens +
             (completionTokens / 1000) * geminiOutputCostPer1kTokens;
    } else {
      // Default to GPT-4 pricing
      return (promptTokens / 1000) * gpt4InputCostPer1kTokens +
             (completionTokens / 1000) * gpt4OutputCostPer1kTokens;
    }
  }

  void clearMetrics() {
    state = const TokenMetrics(
      usageHistory: [],
      totalTokensUsed: 0,
      totalEstimatedCost: 0.0,
      requestCount: 0,
    );
  }

  // Get metrics summary for display
  Map<String, dynamic> getMetricsSummary() {
    return {
      'totalTokens': state.totalTokensUsed,
      'totalCost': state.totalEstimatedCost,
      'requestCount': state.requestCount,
      'tokensLast24h': state.tokensLast24Hours,
      'costLast24h': state.costLast24Hours,
      'lastRequest': state.lastRequestTime?.toIso8601String(),
      'averageTokensPerRequest': state.requestCount > 0 
          ? (state.totalTokensUsed / state.requestCount).round() 
          : 0,
    };
  }
}

// Provider for TokenTrackingService
final tokenTrackingServiceProvider = StateNotifierProvider<TokenTrackingService, TokenMetrics>((ref) {
  return TokenTrackingService();
});

// Provider for metrics summary
final tokenMetricsSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final service = ref.read(tokenTrackingServiceProvider.notifier);
  return service.getMetricsSummary();
});