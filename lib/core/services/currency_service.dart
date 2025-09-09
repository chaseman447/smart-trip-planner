import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExchangeRate {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final DateTime timestamp;

  ExchangeRate({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.timestamp,
  });

  factory ExchangeRate.fromJson(Map<String, dynamic> json, String from, String to) {
    return ExchangeRate(
      fromCurrency: from,
      toCurrency: to,
      rate: (json['rates'][to] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] * 1000),
    );
  }

  double convert(double amount) => amount * rate;

  String formatConversion(double amount) {
    final converted = convert(amount);
    return '$amount $fromCurrency = ${converted.toStringAsFixed(2)} $toCurrency';
  }
}

class CurrencyTip {
  final String country;
  final String currency;
  final String tip;
  final String paymentMethods;
  final bool cashPreferred;
  final List<String> commonDenominations;

  CurrencyTip({
    required this.country,
    required this.currency,
    required this.tip,
    required this.paymentMethods,
    required this.cashPreferred,
    required this.commonDenominations,
  });
}

class CurrencyService {
  static const String _baseUrl = 'https://api.exchangerate-api.com/v4/latest';
  final Dio _dio;
  final Logger _logger = Logger();
  final String? _apiKey;
  
  // Cache for exchange rates (valid for 1 hour)
  final Map<String, ExchangeRate> _rateCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidDuration = Duration(hours: 1);

  CurrencyService(this._dio, {String? apiKey}) : _apiKey = apiKey ?? const String.fromEnvironment('EXCHANGE_RATE_API_KEY');

  /// Get exchange rate between two currencies
  Future<ExchangeRate?> getExchangeRate(String fromCurrency, String toCurrency) async {
    final cacheKey = '${fromCurrency}_$toCurrency';
    
    // Check cache first
    if (_rateCache.containsKey(cacheKey) && _cacheTimestamps.containsKey(cacheKey)) {
      final cacheTime = _cacheTimestamps[cacheKey]!;
      if (DateTime.now().difference(cacheTime) < _cacheValidDuration) {
        return _rateCache[cacheKey];
      }
    }

    try {
      // Use API key if available for better rate limits
      final url = _apiKey != null && _apiKey!.isNotEmpty 
          ? 'https://v6.exchangerate-api.com/v6/$_apiKey/latest/$fromCurrency'
          : '$_baseUrl/$fromCurrency';
      
      final response = await _dio.get(url);
      
      if (response.statusCode == 200) {
        final rate = ExchangeRate.fromJson(response.data, fromCurrency, toCurrency);
        
        // Cache the result
        _rateCache[cacheKey] = rate;
        _cacheTimestamps[cacheKey] = DateTime.now();
        
        return rate;
      } else {
        _logger.e('Currency API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Failed to fetch exchange rate: $e');
      return null;
    }
  }

  /// Get multiple exchange rates for a base currency
  Future<Map<String, double>?> getMultipleRates(String baseCurrency, List<String> targetCurrencies) async {
    try {
      final response = await _dio.get('$_baseUrl/$baseCurrency');
      
      if (response.statusCode == 200) {
        final rates = <String, double>{};
        final responseRates = response.data['rates'] as Map<String, dynamic>;
        
        for (final currency in targetCurrencies) {
          if (responseRates.containsKey(currency)) {
            rates[currency] = (responseRates[currency] as num).toDouble();
          }
        }
        
        return rates;
      } else {
        _logger.e('Currency API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Failed to fetch multiple exchange rates: $e');
      return null;
    }
  }

  /// Get currency tips for a specific country
  CurrencyTip getCurrencyTips(String countryCode) {
    final tips = _currencyTipsDatabase[countryCode.toUpperCase()];
    return tips ?? _getDefaultTip(countryCode);
  }

  /// Get budget recommendations based on exchange rates
  Future<String> getBudgetRecommendation(
    String fromCurrency,
    String toCurrency,
    double dailyBudget,
  ) async {
    final rate = await getExchangeRate(fromCurrency, toCurrency);
    if (rate == null) {
      return 'Unable to get current exchange rates. Please check manually.';
    }

    final convertedBudget = rate.convert(dailyBudget);
    final tip = getCurrencyTips(_getCurrencyCountry(toCurrency));
    
    final recommendation = StringBuffer();
    recommendation.writeln('💰 Budget Conversion:');
    recommendation.writeln('${rate.formatConversion(dailyBudget)} per day');
    recommendation.writeln();
    recommendation.writeln('💡 Local Tips:');
    recommendation.writeln('• ${tip.tip}');
    recommendation.writeln('• Payment methods: ${tip.paymentMethods}');
    
    if (tip.cashPreferred) {
      recommendation.writeln('• Cash is preferred - exchange money beforehand');
    }
    
    if (tip.commonDenominations.isNotEmpty) {
      recommendation.writeln('• Common denominations: ${tip.commonDenominations.join(", ")}');
    }
    
    return recommendation.toString();
  }

  /// Get exchange rate trend (simplified)
  String getExchangeTrend(double currentRate, double previousRate) {
    final change = ((currentRate - previousRate) / previousRate) * 100;
    
    if (change > 2) {
      return '📈 Strong upward trend (+${change.toStringAsFixed(1)}%)';
    } else if (change > 0.5) {
      return '📊 Slight upward trend (+${change.toStringAsFixed(1)}%)';
    } else if (change < -2) {
      return '📉 Strong downward trend (${change.toStringAsFixed(1)}%)';
    } else if (change < -0.5) {
      return '📊 Slight downward trend (${change.toStringAsFixed(1)}%)';
    } else {
      return '➡️ Stable rate (${change.toStringAsFixed(1)}%)';
    }
  }

  /// Clear cache
  void clearCache() {
    _rateCache.clear();
    _cacheTimestamps.clear();
  }

  String _getCurrencyCountry(String currency) {
    final currencyToCountry = {
      'USD': 'US',
      'EUR': 'EU',
      'GBP': 'GB',
      'JPY': 'JP',
      'CNY': 'CN',
      'INR': 'IN',
      'AUD': 'AU',
      'CAD': 'CA',
      'CHF': 'CH',
      'SEK': 'SE',
      'NOK': 'NO',
      'DKK': 'DK',
    };
    return currencyToCountry[currency] ?? 'UNKNOWN';
  }

  CurrencyTip _getDefaultTip(String countryCode) {
    return CurrencyTip(
      country: countryCode,
      currency: 'Unknown',
      tip: 'Check local payment preferences and exchange rates',
      paymentMethods: 'Cash, Credit Cards',
      cashPreferred: false,
      commonDenominations: [],
    );
  }

  // Database of currency tips by country
  static final Map<String, CurrencyTip> _currencyTipsDatabase = {
    'US': CurrencyTip(
      country: 'United States',
      currency: 'USD',
      tip: 'Credit cards widely accepted. Tipping 15-20% expected in restaurants.',
      paymentMethods: 'Credit Cards, Cash, Mobile Pay',
      cashPreferred: false,
      commonDenominations: ['1', '5', '10', '20', '50', '100'],
    ),
    'EU': CurrencyTip(
      country: 'European Union',
      currency: 'EUR',
      tip: 'Contactless payments common. Tipping 5-10% in restaurants.',
      paymentMethods: 'Credit Cards, Cash, Contactless',
      cashPreferred: false,
      commonDenominations: ['5', '10', '20', '50', '100', '200', '500'],
    ),
    'GB': CurrencyTip(
      country: 'United Kingdom',
      currency: 'GBP',
      tip: 'Contactless payments very common. Tipping 10-15% in restaurants.',
      paymentMethods: 'Contactless, Credit Cards, Cash',
      cashPreferred: false,
      commonDenominations: ['5', '10', '20', '50'],
    ),
    'JP': CurrencyTip(
      country: 'Japan',
      currency: 'JPY',
      tip: 'Cash still king in many places. No tipping culture.',
      paymentMethods: 'Cash, IC Cards, Credit Cards',
      cashPreferred: true,
      commonDenominations: ['1000', '2000', '5000', '10000'],
    ),
    'CN': CurrencyTip(
      country: 'China',
      currency: 'CNY',
      tip: 'Mobile payments (WeChat Pay, Alipay) dominate. Cash backup recommended.',
      paymentMethods: 'Mobile Pay, Cash, Credit Cards',
      cashPreferred: false,
      commonDenominations: ['1', '5', '10', '20', '50', '100'],
    ),
    'IN': CurrencyTip(
      country: 'India',
      currency: 'INR',
      tip: 'Digital payments growing rapidly. Keep small denominations for tips.',
      paymentMethods: 'UPI, Cash, Credit Cards',
      cashPreferred: true,
      commonDenominations: ['10', '20', '50', '100', '200', '500', '2000'],
    ),
  };
}

// Provider for CurrencyService
final currencyServiceProvider = Provider<CurrencyService>((ref) {
  final dio = Dio();
  return CurrencyService(dio);
});