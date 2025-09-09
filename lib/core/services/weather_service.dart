import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WeatherData {
  final double temperature;
  final String description;
  final String icon;
  final double humidity;
  final double windSpeed;
  final double feelsLike;
  final String cityName;

  WeatherData({
    required this.temperature,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.feelsLike,
    required this.cityName,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['description'] as String,
      icon: json['weather'][0]['icon'] as String,
      humidity: (json['main']['humidity'] as num).toDouble(),
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      feelsLike: (json['main']['feels_like'] as num).toDouble(),
      cityName: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'description': description,
      'icon': icon,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'feelsLike': feelsLike,
      'cityName': cityName,
    };
  }

  String get temperatureCelsius => '${(temperature - 273.15).round()}°C';
  String get temperatureFahrenheit => '${((temperature - 273.15) * 9/5 + 32).round()}°F';
  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';
}

class WeatherService {
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';
  final Dio _dio;
  final Logger _logger = Logger();
  final String? _apiKey;

  WeatherService(this._dio, {String? apiKey}) : _apiKey = apiKey ?? const String.fromEnvironment('OPENWEATHER_API_KEY');

  /// Get current weather by city name
  Future<WeatherData?> getCurrentWeatherByCity(String cityName) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      _logger.w('OpenWeather API key not provided');
      return null;
    }

    try {
      final response = await _dio.get(
        '$_baseUrl/weather',
        queryParameters: {
          'q': cityName,
          'appid': _apiKey,
          'units': 'metric',
        },
      );

      if (response.statusCode == 200) {
        return WeatherData.fromJson(response.data);
      } else {
        _logger.e('Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Failed to fetch weather data: $e');
      return null;
    }
  }

  /// Get current weather by coordinates
  Future<WeatherData?> getCurrentWeatherByCoordinates(
    double latitude,
    double longitude,
  ) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      _logger.w('OpenWeather API key not provided');
      return null;
    }

    try {
      final response = await _dio.get(
        '$_baseUrl/weather',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'appid': _apiKey,
          'units': 'metric',
        },
      );

      if (response.statusCode == 200) {
        return WeatherData.fromJson(response.data);
      } else {
        _logger.e('Weather API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Failed to fetch weather data: $e');
      return null;
    }
  }

  /// Get 5-day weather forecast
  Future<List<WeatherData>?> getForecast(String cityName) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      _logger.w('OpenWeather API key not provided');
      return null;
    }

    try {
      final response = await _dio.get(
        '$_baseUrl/forecast',
        queryParameters: {
          'q': cityName,
          'appid': _apiKey,
          'units': 'metric',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> forecastList = response.data['list'];
        return forecastList
            .map((item) => WeatherData.fromJson({
                  ...item,
                  'name': response.data['city']['name'],
                }))
            .toList();
      } else {
        _logger.e('Weather forecast API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      _logger.e('Failed to fetch weather forecast: $e');
      return null;
    }
  }

  /// Get weather recommendations for travel
  String getWeatherRecommendation(WeatherData weather) {
    final temp = weather.temperature - 273.15; // Convert to Celsius
    final description = weather.description.toLowerCase();

    if (description.contains('rain') || description.contains('drizzle')) {
      return 'Pack an umbrella and waterproof clothing. Consider indoor activities.';
    } else if (description.contains('snow')) {
      return 'Dress warmly and pack winter gear. Check for travel advisories.';
    } else if (description.contains('thunderstorm')) {
      return 'Severe weather expected. Consider postponing outdoor activities.';
    } else if (temp > 30) {
      return 'Very hot weather. Stay hydrated, wear light clothing, and seek shade.';
    } else if (temp > 25) {
      return 'Warm weather. Perfect for outdoor activities. Don\'t forget sunscreen.';
    } else if (temp > 15) {
      return 'Pleasant weather. Great for sightseeing and outdoor activities.';
    } else if (temp > 5) {
      return 'Cool weather. Pack layers and a light jacket.';
    } else {
      return 'Cold weather. Dress warmly and pack winter clothing.';
    }
  }

  /// Check if weather is suitable for outdoor activities
  bool isGoodForOutdoorActivities(WeatherData weather) {
    final temp = weather.temperature - 273.15;
    final description = weather.description.toLowerCase();

    // Not good if severe weather
    if (description.contains('thunderstorm') ||
        description.contains('heavy rain') ||
        description.contains('snow')) {
      return false;
    }

    // Not good if too hot or too cold
    if (temp > 35 || temp < 0) {
      return false;
    }

    return true;
  }
}

// Provider for WeatherService
final weatherServiceProvider = Provider<WeatherService>((ref) {
  final dio = Dio();
  return WeatherService(dio);
});