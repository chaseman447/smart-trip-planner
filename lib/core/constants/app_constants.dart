class AppConstants {
  // App Information
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String openAiApiUrl = 'https://api.openai.com/v1';
  static const String openAiChatCompletionsEndpoint = '/chat/completions';
  static const String openAiModel = 'gpt-4-turbo-preview';
  
  // DeepSeek API Configuration
  static const String deepSeekApiUrl = 'https://api.aimlapi.com/v1';
  static const String deepSeekModel = 'deepseek/deepseek-prover-v2';
  // API Keys
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
  static const String openaiApiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static const String deepSeekApiKey = ''; // Replace with actual key
  static const String githubToken = String.fromEnvironment('GITHUB_TOKEN', defaultValue: '');
  static const String openRouterApiKey = String.fromEnvironment('OPENROUTER_API_KEY', defaultValue: '');
  
  // Database
  static const String databaseName = 'smart_trip_planner';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  
  // Chat Configuration
  static const int maxTokens = 4000;
  static const double temperature = 0.7;
  
  // Map Configuration
  static const String googleMapsUrlScheme = 'https://www.google.com/maps/search/?api=1&query=';
  static const String appleMapsUrlScheme = 'http://maps.apple.com/?q=';
  
  // Error Messages
  static const String networkErrorMessage = 'Network connection failed. Please check your internet connection.';
  static const String apiErrorMessage = 'Failed to get response from AI service. Please try again.';
  static const String databaseErrorMessage = 'Failed to save data locally. Please try again.';
  static const String locationErrorMessage = 'Failed to get location coordinates.';
  
  // Success Messages
  static const String tripSavedMessage = 'Trip saved successfully!';
  static const String tripDeletedMessage = 'Trip deleted successfully!';
}