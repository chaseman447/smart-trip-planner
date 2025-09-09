import 'dart:async';
import 'package:flutter/foundation.dart';
// import 'package:speech_to_text/speech_to_text.dart'; // Temporarily disabled
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  // final SpeechToText _speechToText = SpeechToText(); // Temporarily disabled
  final FlutterTts _flutterTts = FlutterTts();
  final Logger _logger = Logger();

  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastWords = '';

  // Getters
  bool get speechEnabled => _speechEnabled;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  String get lastWords => _lastWords;

  // Stream controllers for real-time updates
  final StreamController<String> _speechResultController = StreamController<String>.broadcast();
  final StreamController<bool> _listeningStateController = StreamController<bool>.broadcast();
  final StreamController<bool> _speakingStateController = StreamController<bool>.broadcast();

  Stream<String> get speechResultStream => _speechResultController.stream;
  Stream<bool> get listeningStateStream => _listeningStateController.stream;
  Stream<bool> get speakingStateStream => _speakingStateController.stream;

  /// Initialize the voice service
  Future<bool> initialize() async {
    try {
      // Request microphone permission
      final microphoneStatus = await Permission.microphone.request();
      if (microphoneStatus != PermissionStatus.granted) {
        _logger.w('Microphone permission denied');
        return false;
      }

      // Initialize speech to text - temporarily disabled
      _speechEnabled = false;
      _logger.w('Speech recognition temporarily disabled');

      // Initialize text to speech
      await _initializeTts();

      _logger.i('Voice service initialized successfully');
      return _speechEnabled;
    } catch (e) {
      _logger.e('Failed to initialize voice service: $e');
      return false;
    }
  }

  /// Initialize TTS settings
  Future<void> _initializeTts() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
      _speakingStateController.add(_isSpeaking);
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
      _speakingStateController.add(_isSpeaking);
    });

    _flutterTts.setErrorHandler((msg) {
      _logger.e('TTS error: $msg');
      _isSpeaking = false;
      _speakingStateController.add(_isSpeaking);
    });
  }

  /// Start listening for speech input
  Future<void> startListening() async {
    // Speech recognition temporarily disabled
    _logger.w('Speech recognition not available');
    _speechResultController.add('Speech recognition temporarily disabled');
  }

  /// Stop listening for speech input
  Future<void> stopListening() async {
    // Speech recognition temporarily disabled
    _isListening = false;
    _listeningStateController.add(_isListening);
  }

  /// Speak the given text
  Future<void> speak(String text) async {
    if (text.isEmpty || _isSpeaking) return;

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      _logger.e('Failed to speak: $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    if (!_isSpeaking) return;

    try {
      await _flutterTts.stop();
      _isSpeaking = false;
      _speakingStateController.add(_isSpeaking);
    } catch (e) {
      _logger.e('Failed to stop speaking: $e');
    }
  }

  /// Get available languages for TTS
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      _logger.e('Failed to get available languages: $e');
      return ['en-US'];
    }
  }

  /// Set TTS language
  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
    } catch (e) {
      _logger.e('Failed to set language: $e');
    }
  }

  /// Set TTS speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
    } catch (e) {
      _logger.e('Failed to set speech rate: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _speechResultController.close();
    _listeningStateController.close();
    _speakingStateController.close();
  }
}