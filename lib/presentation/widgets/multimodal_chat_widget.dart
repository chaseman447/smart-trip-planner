import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/trip.dart';
import '../../core/services/voice_service.dart';
import '../../core/services/enhanced_ai_agent_service.dart';
import '../../core/services/connectivity_service.dart';
import '../../core/services/offline_trip_service.dart';
import '../../core/utils/json_extractor.dart';
import '../providers/trip_provider.dart';
import 'itinerary_diff_widget.dart';
import 'trip_card_widget.dart';

class MultimodalChatWidget extends ConsumerStatefulWidget {
  final Trip? currentTrip;
  final Function(Trip)? onTripGenerated;
  final VoidCallback? onClearChat;
  final Function(VoidCallback)? onRegisterClearCallback;

  const MultimodalChatWidget({
    super.key,
    this.currentTrip,
    this.onTripGenerated,
    this.onClearChat,
    this.onRegisterClearCallback,
  });

  @override
  ConsumerState<MultimodalChatWidget> createState() => _MultimodalChatWidgetState();
}

class _MultimodalChatWidgetState extends ConsumerState<MultimodalChatWidget>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final Map<String, Trip> _tripCards = {}; // Store trip objects for rendering
  
  late VoiceService _voiceService;
  late AnimationController _voiceAnimationController;
  late AnimationController _typingAnimationController;
  
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _isTyping = false;
  String _currentResponse = '';
  Trip? _currentExtractedTrip;

  @override
  void initState() {
    super.initState();
    _voiceService = VoiceService();
    _voiceAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _textController.addListener(() {
      setState(() {});
    });
    
    // Register the clear callback with the parent
    if (widget.onRegisterClearCallback != null) {
      widget.onRegisterClearCallback!(clearChat);
    }
  }

  @override
  void dispose() {
    _voiceAnimationController.dispose();
    _typingAnimationController.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startListening() async {
    if (_isListening) return;
    
    setState(() {
      _isListening = true;
    });
    
    _voiceAnimationController.repeat();
    
    try {
        await _voiceService.startListening();
        
        // Listen to speech results
        _voiceService.speechResultStream.listen((text) {
          setState(() {
            _textController.text = text;
          });
        });
    } catch (e) {
      _showError('Failed to start voice recognition: $e');
      _stopListening();
    }
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    
    setState(() {
      _isListening = false;
    });
    
    _voiceAnimationController.stop();
    await _voiceService.stopListening();
    
    // Auto-send if we have text
    if (_textController.text.trim().isNotEmpty) {
      _sendMessage();
    }
  }

  void _cancelProcessing() {
    setState(() {
      _isProcessing = false;
      _isTyping = false;
    });
    _typingAnimationController.stop();
    
    // Remove the last assistant message if it's still streaming
    if (_messages.isNotEmpty && _messages.last.type == ChatMessageType.assistant && _messages.last.isStreaming) {
      setState(() {
        _messages.removeLast();
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isProcessing) return;

    // Check connectivity before sending
    final isOnline = ref.read(isOnlineProvider);
    if (!isOnline) {
      _showOfflineMessage(text);
      return;
    }

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      type: ChatMessageType.user,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(userMessage);
      _textController.clear();
      _isProcessing = true;
      _isTyping = true;
      _currentResponse = '';
      // Keep _currentExtractedTrip available until a new trip is generated
      // This allows the save button to remain visible for the last generated trip
    });
    
    _typingAnimationController.repeat();
    _scrollToBottom();

    try {
      // Create assistant message placeholder
      final assistantMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '',
        type: ChatMessageType.assistant,
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      
      setState(() {
        _messages.add(assistantMessage);
      });

      // Stream response from actual AI service
      await _getActualAIResponse(text);
      
    } catch (e) {
      _showError('Failed to get response: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isTyping = false;
        });
      }
      _typingAnimationController.stop();
    }
  }

  Future<void> _getActualAIResponse(String userInput) async {
    try {
      final enhancedService = ref.read(enhancedAIAgentServiceProvider);
      final messages = _messages.where((m) => m.type == ChatMessageType.user).toList();
      
      final responseStream = enhancedService.chatWithTools(messages);
      
      await for (final chunk in responseStream) {
        setState(() {
          _currentResponse += chunk;
          if (_messages.isNotEmpty) {
            final lastIndex = _messages.length - 1;
            _messages[lastIndex] = _messages[lastIndex].copyWith(
              content: _currentResponse,
              isStreaming: true,
            );
          }
        });
        _scrollToBottom();
      }
      
      // Finalize the message
      if (_messages.isNotEmpty) {
        final lastIndex = _messages.length - 1;
        _messages[lastIndex] = _messages[lastIndex].copyWith(
          content: _currentResponse,
          isStreaming: false,
        );
        
        // Handle trip response
      await _handleTripResponse(_currentResponse);
      
      // Auto-speak response
      await _speakResponse(_currentResponse);
    }
    
    // Reset loading states
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _isTyping = false;
      });
    }
      
    } catch (e) {
      // Fallback response
      final fallbackResponse = 'I can help you plan your trip! However, I\'m currently experiencing some technical difficulties with my advanced features. Please try asking about specific destinations, dates, or activities you\'d like to include in your trip.';
      
      setState(() {
        _currentResponse = fallbackResponse;
        if (_messages.isNotEmpty) {
          final lastIndex = _messages.length - 1;
          _messages[lastIndex] = _messages[lastIndex].copyWith(
            content: _currentResponse,
            isStreaming: false,
          );
        }
      });
      
      await _speakResponse(_currentResponse);
      
      // Reset loading states in fallback case
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isTyping = false;
        });
      }
    }
  }

  Future<void> _speakResponse(String text) async {
    if (text.isEmpty) return;
    
    setState(() {
      _isSpeaking = true;
    });
    
    try {
      await _voiceService.speak(text);
    } catch (e) {
      // Ignore TTS errors
    } finally {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
        });
      }
    }
  }

  Future<void> _stopSpeaking() async {
    await _voiceService.stopSpeaking();
    setState(() {
      _isSpeaking = false;
    });
  }

  void _handleLinkTap(String? href) async {
    if (href != null) {
      try {
        final uri = Uri.parse(href);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          // Fallback to Google Maps web if maps:// scheme doesn't work
          final fallbackUrl = href.startsWith('maps://')
              ? href.replaceFirst('maps://?q=', 'https://maps.google.com/maps?q=')
              : href;
          final fallbackUri = Uri.parse(fallbackUrl);
          if (await canLaunchUrl(fallbackUri)) {
            await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
          }
        }
      } catch (e) {
        // Handle error silently or show a snackbar
        debugPrint('Error launching URL: $e');
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _generateTestTrip() async {
    try {
      // Add a user message asking for a trip
      final userMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Generate a test trip to Paris for 3 days',
        type: ChatMessageType.user,
        timestamp: DateTime.now(),
      );
      
      setState(() {
        _messages.add(userMessage);
      });
      
      // Create a compatible test trip JSON that matches the expected format
      final testTripJson = {
        'title': '🌟 Magical Paris Adventure',
        'startDate': DateTime.now().toIso8601String().split('T')[0],
        'endDate': DateTime.now().add(const Duration(days: 2)).toIso8601String().split('T')[0],
        'days': [
          {
            'date': DateTime.now().toIso8601String().split('T')[0],
            'summary': 'Arrival & Classic Paris',
            'items': [
              {
                'time': '10:00 AM',
                'activity': 'Arrive at Charles de Gaulle Airport',
                'location': 'Charles de Gaulle Airport, Paris',
                'description': 'Welcome to the City of Light! Take the RER B train to central Paris.',
                'cost': '€12',
                'notes': 'Buy a Navigo Easy card for convenient metro travel',
                'latitude': 49.0097,
                'longitude': 2.5479
              },
              {
                'time': '2:00 PM',
                'activity': 'Visit the Eiffel Tower',
                'location': 'Champ de Mars, Paris',
                'description': 'Iconic iron lattice tower and symbol of Paris. Take photos and enjoy the views.',
                'cost': '€29',
                'notes': 'Book tickets online to skip the lines',
                'latitude': 48.8584,
                'longitude': 2.2945
              },
              {
                'time': '6:00 PM',
                'activity': 'Seine River Cruise',
                'location': 'Port de la Bourdonnais, Paris',
                'description': 'Romantic evening cruise along the Seine with stunning city views.',
                'cost': '€15',
                'notes': 'Perfect for sunset photos',
                'latitude': 48.8606,
                'longitude': 2.2978
              }
            ]
          },
          {
            'date': DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T')[0],
            'summary': 'Art & Culture Day',
            'items': [
              {
                'time': '9:00 AM',
                'activity': 'Explore the Louvre Museum',
                'location': 'Rue de Rivoli, Paris',
                'description': 'World\'s largest art museum featuring the Mona Lisa and Venus de Milo.',
                'cost': '€17',
                'notes': 'Free on first Sunday of each month for EU residents',
                'latitude': 48.8606,
                'longitude': 2.3376
              },
              {
                'time': '2:00 PM',
                'activity': 'Stroll through Montmartre',
                'location': 'Montmartre, Paris',
                'description': 'Historic district with cobblestone streets, artists, and the Sacré-Cœur Basilica.',
                'cost': 'Free',
                'notes': 'Watch street artists and enjoy panoramic city views',
                'latitude': 48.8867,
                'longitude': 2.3431
              },
              {
                'time': '7:00 PM',
                'activity': 'Dinner at a Traditional Bistro',
                'location': 'Le Marais District, Paris',
                'description': 'Authentic French cuisine in a charming historic neighborhood.',
                'cost': '€45',
                'notes': 'Try the coq au vin and crème brûlée',
                'latitude': 48.8566,
                'longitude': 2.3522
              }
            ]
          },
          {
            'date': DateTime.now().add(const Duration(days: 2)).toIso8601String().split('T')[0],
            'summary': 'Gardens & Departure',
            'items': [
              {
                'time': '10:00 AM',
                'activity': 'Visit Luxembourg Gardens',
                'location': 'Luxembourg Gardens, Paris',
                'description': 'Beautiful palace gardens perfect for a morning stroll and relaxation.',
                'cost': 'Free',
                'notes': 'Great spot for people watching and photos',
                'latitude': 48.8462,
                'longitude': 2.3372
              },
              {
                'time': '1:00 PM',
                'activity': 'Shopping on Champs-Élysées',
                'location': 'Avenue des Champs-Élysées, Paris',
                'description': 'Famous avenue for shopping, cafés, and the Arc de Triomphe.',
                'cost': 'Variable',
                'notes': 'Perfect for last-minute souvenirs',
                'latitude': 48.8698,
                'longitude': 2.3076
              },
              {
                'time': '4:00 PM',
                'activity': 'Departure to Airport',
                'location': 'Charles de Gaulle Airport, Paris',
                'description': 'Take the RER B train back to the airport for your departure.',
                'cost': '€12',
                'notes': 'Allow 1.5 hours for airport procedures',
                'latitude': 49.0097,
                'longitude': 2.5479
              }
            ]
          }
        ],
        'totalTokensUsed': 0
      };
      
      final jsonString = jsonEncode(testTripJson);
      final responseContent = 'Here\'s your perfect 3-day Paris itinerary! ✨\n\n```json\n$jsonString\n```';
      
      final assistantMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        content: responseContent,
        type: ChatMessageType.assistant,
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      
      setState(() {
        _messages.add(assistantMessage);
      });
      
      // Handle the trip response to create the formatted trip card
      await _handleTripResponse(responseContent);
      
      _scrollToBottom();
      
    } catch (e) {
      _showError('Failed to generate test trip: $e');
    }
  }

  void _showOfflineMessage(String userInput) {
    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: userInput,
      type: ChatMessageType.user,
      timestamp: DateTime.now(),
    );
    
    // Generate contextual offline response
    String offlineResponse;
    final input = userInput.toLowerCase();
    
    if (input.contains('trip') || input.contains('plan') || input.contains('travel')) {
      offlineResponse = '🌐 **Offline Mode**\n\n'
          'I\'d love to help you plan your trip, but I need an internet connection to access real-time information and generate detailed itineraries.\n\n'
          '**What I need online access for:**\n'
          '• Current weather and seasonal information\n'
          '• Live attraction hours and availability\n'
          '• Up-to-date restaurant recommendations\n'
          '• Real-time transportation schedules\n'
          '• Currency exchange rates\n\n'
          '**Please:**\n'
          '1. Check your internet connection\n'
          '2. Try again when you\'re back online\n\n'
          'I\'ll be ready to create an amazing itinerary for you! 🗺️✈️';
    } else if (input.contains('weather')) {
      offlineResponse = '🌐 **Offline Mode**\n\n'
          'I can\'t access current weather information without an internet connection. Please check a weather app or website for up-to-date conditions at your destination.\n\n'
          'When you\'re back online, I can help you plan activities based on the weather forecast! 🌤️';
    } else if (input.contains('currency') || input.contains('exchange')) {
      offlineResponse = '🌐 **Offline Mode**\n\n'
          'I can\'t access real-time currency exchange rates without an internet connection. Please check a financial app or website for current rates.\n\n'
          'When online, I can help you budget for your trip with current exchange rates! 💱';
    } else {
      offlineResponse = '🌐 **Offline Mode**\n\n'
          'I\'m currently unable to access real-time information due to network connectivity issues. I can still help with basic trip planning questions!\n\n'
          '**Try asking about:**\n'
          '• General destination information\n'
          '• Travel tips and advice\n'
          '• Packing suggestions\n\n'
          'For detailed itineraries and real-time info, please check your connection and try again when online. 🌍';
    }
    
    final assistantMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: offlineResponse,
      type: ChatMessageType.assistant,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.addAll([userMessage, assistantMessage]);
    });
    
    _scrollToBottom();
    
    // Show snackbar with retry option
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 8),
            Text('You\'re offline. Limited functionality available.'),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () async {
            final connectivityService = ref.read(connectivityServiceProvider.notifier);
            final isConnected = await connectivityService.checkConnection();
            if (isConnected) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.wifi, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Connection restored!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(isOfflineProvider);
    
    return Column(
      children: [
        // Connectivity status bar
        if (isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.orange.shade100,
            child: Row(
              children: [
                Icon(
                  Icons.wifi_off,
                  size: 16,
                  color: Colors.orange.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You\'re offline. Limited functionality available.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final connectivityService = ref.read(connectivityServiceProvider.notifier);
                    await connectivityService.checkConnection();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Retry',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _generateTestTrip,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Test Trip',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Test Trip button (always visible for testing)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              Icon(
                Icons.science,
                size: 16,
                color: Colors.blue.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Testing Mode - Generate sample trip with clickable locations',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              TextButton(
                onPressed: _generateTestTrip,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Generate Test Trip',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Chat messages
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return _buildMessageBubble(message);
            },
          ),
        ),
        
        // Input area
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: _buildInputArea(),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.type == ChatMessageType.user;
    final isTripCard = message.tripId != null && !isUser;
    
    // For assistant messages, just display the content as-is
    // The _handleTripResponse method already handles formatting
    String displayContent = message.content;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: isTripCard ? 8 : 4),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * (isTripCard ? 0.95 : 0.85),
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Regular message bubble or trip card
            if (displayContent.trim().isNotEmpty)
              Container(
                padding: EdgeInsets.all(isTripCard ? 16 : 20),
                decoration: BoxDecoration(
                  gradient: isUser 
                      ? LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : isTripCard
                          ? LinearGradient(
                              colors: [
                                Colors.blue.shade50,
                                Colors.blue.shade100.withOpacity(0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [
                                Theme.of(context).cardColor,
                                Theme.of(context).cardColor.withOpacity(0.95),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                  borderRadius: BorderRadius.circular(isTripCard ? 16 : 24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isTripCard ? 0.08 : 0.12),
                      blurRadius: isTripCard ? 8 : 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                      spreadRadius: 0,
                    ),
                  ],
                  border: isUser ? null : Border.all(
                    color: isTripCard 
                        ? Colors.blue.shade200.withOpacity(0.5)
                        : Theme.of(context).dividerColor.withOpacity(0.2),
                    width: isTripCard ? 1 : 0.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trip card header
                     if (isTripCard) ...[
                       Row(
                         children: [
                           Icon(
                             Icons.map_outlined,
                             color: Colors.blue.shade700,
                             size: 20,
                           ),
                           const SizedBox(width: 8),
                           Text(
                             'Trip Itinerary',
                             style: TextStyle(
                               color: Colors.blue.shade700,
                               fontSize: 14,
                               fontWeight: FontWeight.w600,
                             ),
                           ),
                         ],
                       ),
                       const SizedBox(height: 12),
                     ],
                    isUser 
                        ? Text(
                            displayContent,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              height: 1.4,
                              fontWeight: FontWeight.w400,
                            ),
                          )
                        : isTripCard && _tripCards.containsKey(message.id)
                            ? TripCardWidget(
                                trip: _tripCards[message.id]!,
                                onTap: () {}, // No action needed for chat display
                              )
                            : MarkdownBody(
                                data: displayContent,
                                styleSheet: MarkdownStyleSheet(
                                  p: TextStyle(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    fontSize: 16,
                                    height: 1.5,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  h1: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    height: 1.3,
                                  ),
                                  h2: TextStyle(
                                    color: Theme.of(context).primaryColor.withOpacity(0.8),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    height: 1.3,
                                  ),
                                  h3: TextStyle(
                                    color: Theme.of(context).textTheme.headlineSmall?.color,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  strong: TextStyle(
                                    color: Theme.of(context).textTheme.bodyLarge?.color,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  em: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  blockquote: TextStyle(
                                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                                    fontStyle: FontStyle.italic,
                                  ),
                                  code: TextStyle(
                                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontFamily: 'monospace',
                                fontSize: 14,
                              ),
                              horizontalRuleDecoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                            selectable: true,
                            onTapLink: (text, href, title) => _handleLinkTap(href),
                          ),
                    if (message.isStreaming) ...[
                      const SizedBox(height: 8),
                      _buildTypingIndicator(),
                    ],
                    if (!isUser && !message.isStreaming) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              _isSpeaking ? Icons.volume_off : Icons.volume_up,
                              size: 16,
                            ),
                            onPressed: _isSpeaking ? _stopSpeaking : () => _speakResponse(message.content),
                            tooltip: _isSpeaking ? 'Stop speaking' : 'Read aloud',
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            
            // Save trip button if we have an extracted trip
             if (!isUser && !message.isStreaming && _currentExtractedTrip != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  child: ElevatedButton.icon(
                    onPressed: () => _saveTrip(_currentExtractedTrip!),
                    icon: const Icon(Icons.bookmark_add, size: 18),
                    label: const Text('Save This Trip'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Trip? _extractTripFromMessage(String content) {
    try {
      final json = JsonExtractor.extractJson(content);
      
      // Check if it's a valid trip JSON
      if (json != null && json.containsKey('title') && json.containsKey('days')) {
        return _jsonToTrip(json);
      }
    } catch (e) {
      // Ignore JSON parsing errors
      print('⚠️ Failed to extract trip from message: $e');
    }
    return null;
  }

  String _removeJsonFromContent(String content) {
    final jsonStart = content.indexOf('{');
    if (jsonStart != -1) {
      final beforeJson = content.substring(0, jsonStart).trim();
      final jsonEnd = content.lastIndexOf('}') + 1;
      final afterJson = jsonEnd < content.length 
          ? content.substring(jsonEnd).trim() 
          : '';
      
      final result = '$beforeJson $afterJson'.trim();
      return result.isNotEmpty ? result : 'Here\'s your personalized itinerary:';
    }
    return content;
  }

  Widget _buildInputArea() {
    final isOffline = ref.watch(isOfflineProvider);
    final canSend = _textController.text.trim().isNotEmpty && !_isProcessing && !isOffline;
    
    return Row(
      children: [
        // Voice input button
        AnimatedBuilder(
          animation: _voiceAnimationController,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isListening 
                    ? Colors.red.withOpacity(0.1 + 0.3 * _voiceAnimationController.value)
                    : Theme.of(context).primaryColor.withOpacity(0.1),
              ),
              child: IconButton(
                icon: Icon(
                  _isListening ? Icons.mic : Icons.mic_none,
                  color: isOffline
                      ? Theme.of(context).disabledColor
                      : _isListening 
                          ? Colors.red
                          : Theme.of(context).primaryColor,
                ),
                onPressed: isOffline ? null : (_isListening ? _stopListening : _startListening),
                tooltip: isOffline 
                    ? 'Voice input unavailable offline'
                    : _isListening ? 'Stop listening' : 'Voice input',
              ),
            );
          },
        ),
        
        const SizedBox(width: 8),
        
        // Text input
        Expanded(
          child: TextField(
            controller: _textController,
            enabled: !isOffline,
            decoration: InputDecoration(
              hintText: isOffline 
                  ? 'Connect to internet to chat...'
                  : _isListening 
                      ? 'Listening...' 
                      : 'Ask about your trip or say "plan a trip to..."',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => canSend ? _sendMessage() : null,
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Send button
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (canSend || _isProcessing)
                ? Theme.of(context).primaryColor
                : Theme.of(context).disabledColor,
          ),
          child: IconButton(
            icon: _isProcessing 
                ? const Icon(Icons.stop, color: Colors.white)
                : const Icon(Icons.send),
            color: (canSend || _isProcessing) ? Colors.white : null,
            onPressed: _isProcessing 
                ? _cancelProcessing
                : (canSend ? _sendMessage : null),
            tooltip: isOffline 
                ? 'Send unavailable offline'
                : _isProcessing 
                    ? 'Cancel message'
                    : canSend ? 'Send message' : 'Type a message',
          ),
        ),
      ],
    );
  }

  Widget _buildTypingIndicator() {
    return AnimatedBuilder(
      animation: _typingAnimationController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final animationValue = (_typingAnimationController.value - delay).clamp(0.0, 1.0);
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.translate(
                offset: Offset(0, -4 * (1 - (animationValue * 2 - 1).abs())),
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Future<void> _handleTripResponse(String response) async {
    try {
      // Use JsonExtractor to handle various AI response formats
      final json = JsonExtractor.extractJson(response);
      
      if (json != null && json.containsKey('title') && json.containsKey('days')) {
        print('🔍 DEBUG: Full extracted JSON before formatting:');
        print('═══════════════════════════════════════════════════════════');
        print(const JsonEncoder.withIndent('  ').convert(json));
        print('═══════════════════════════════════════════════════════════');
        print('Title: ${json['title']}');
        if (json['days'] is List) {
          final days = json['days'] as List;
          print('Number of days: ${days.length}');
          for (int i = 0; i < days.length && i < 3; i++) {
            final day = days[i];
            print('Day $i structure: ${day.runtimeType}');
            if (day is Map) {
              print('  - Keys: ${day.keys.toList()}');
              if (day.containsKey('items') && day['items'] is List) {
                final items = day['items'] as List;
                print('  - Items count: ${items.length}');
                for (int j = 0; j < items.length && j < 2; j++) {
                  final item = items[j];
                  print('    Item $j: ${item.runtimeType}');
                  if (item is Map) {
                    print('      Keys: ${item.keys.toList()}');
                    print('      Time: ${item['time']}');
                    print('      Location: ${item['location']}');
                    print('      Activity: ${item['activity']}');
                  }
                }
              }
            }
            if (day is Map<String, dynamic>) {
              print('  Day keys: ${day.keys.toList()}');
              final activities = day['activities'] ?? day['items'];
              print('  Activities/Items: ${activities.runtimeType}');
              if (activities is List && activities.isNotEmpty) {
                final firstActivity = activities[0];
                print('  First activity: $firstActivity');
                if (firstActivity is Map<String, dynamic>) {
                  print('    Activity keys: ${firstActivity.keys.toList()}');
                  print('    Time: "${firstActivity['time']}"');
                  print('    Location: "${firstActivity['location']}"');
                  print('    Activity: "${firstActivity['activity']}"');
                }
              }
            }
          }
        }
        // Extract clean response text (without JSON) to use as description
        String cleanResponseText = response;
        final jsonStartIndex = response.indexOf('{');
        final jsonEndIndex = response.lastIndexOf('}');
        
        if (jsonStartIndex != -1 && jsonEndIndex != -1 && jsonEndIndex > jsonStartIndex) {
          // Remove JSON from response, keeping text before and after
          final beforeJson = response.substring(0, jsonStartIndex).trim();
          final afterJson = response.substring(jsonEndIndex + 1).trim();
          cleanResponseText = [beforeJson, afterJson].where((s) => s.isNotEmpty).join('\n\n');
        }
        
        final newTrip = _jsonToTrip(json, cleanResponseText);
        
        // Store the extracted trip for save button functionality
        _currentExtractedTrip = newTrip;
        
        // Create clean response without JSON and add separate trip card
        if (_messages.isNotEmpty) {
          final lastIndex = _messages.length - 1;
          
          // Clean the response by removing JSON content
          String cleanResponse = response;
          final jsonStartIndex = response.indexOf('{');
          final jsonEndIndex = response.lastIndexOf('}');
          
          if (jsonStartIndex != -1 && jsonEndIndex != -1 && jsonEndIndex > jsonStartIndex) {
            // Remove JSON from response, keeping text before and after
            final beforeJson = response.substring(0, jsonStartIndex).trim();
            final afterJson = response.substring(jsonEndIndex + 1).trim();
            cleanResponse = [beforeJson, afterJson].where((s) => s.isNotEmpty).join('\n\n');
          }
          
          // Update the main message with clean response and stop streaming
          _messages[lastIndex] = _messages[lastIndex].copyWith(
            content: cleanResponse.isEmpty ? 'Here\'s your trip plan:' : cleanResponse,
            isStreaming: false,
          );
          
          // Add a separate trip card message
           final tripCardMessage = ChatMessage(
             id: DateTime.now().millisecondsSinceEpoch.toString() + '_trip',
             content: 'Trip Card', // Placeholder content
             type: ChatMessageType.assistant,
             timestamp: DateTime.now(),
             isStreaming: false,
             tripId: newTrip.id, // Use tripId to identify trip cards
           );
           
           // Store the trip object for rendering
           _tripCards[tripCardMessage.id] = newTrip;
          
          _messages.add(tripCardMessage);
          setState(() {});
        }
        
        // If we have an existing trip, show diff
        if (widget.currentTrip != null) {
          _showTripDiff(widget.currentTrip!, newTrip);
        }
        
        // Notify parent about the new trip
        if (widget.onTripGenerated != null) {
          widget.onTripGenerated!(newTrip);
        }
      }
    } catch (e) {
      print('Error in _handleTripResponse: $e');
      // Ignore JSON parsing errors - not all responses contain trip data
    }
  }

  void _showTripDiff(Trip oldTrip, Trip newTrip) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              AppBar(
                title: const Text('Itinerary Changes'),
                automaticallyImplyLeading: false,
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
              Expanded(
                child: ItineraryDiffWidget(
                  oldTrip: oldTrip,
                  newTrip: newTrip,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTripResponse(Trip trip) {
    final buffer = StringBuffer();
    
    // Enhanced trip header with more details
    buffer.writeln('# 🌟 ${trip.title}');
    buffer.writeln('**📅 ${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}** (${trip.days.length} days)');
    buffer.writeln();
    
    // Enhanced daily itinerary with richer formatting
    for (int i = 0; i < trip.days.length; i++) {
      final day = trip.days[i];
      buffer.writeln('## 📆 Day ${i + 1}: ${day.summary}');
      buffer.writeln('*${_formatDate(day.date)}*');
      buffer.writeln();
      
      for (final item in day.items) {
        buffer.writeln('### 🕐 ${item.time} - ${item.activity}');
        
        if (item.location.isNotEmpty) {
          buffer.writeln('📍 **Location:** ${item.location}');
        }
        
        if (item.description != null && item.description!.isNotEmpty) {
          buffer.writeln('ℹ️ **Details:** ${item.description}');
        }
        
        if (item.cost != null && item.cost!.isNotEmpty) {
          buffer.writeln('💰 **Cost:** ${item.cost}');
        }
        
        if (item.notes != null && item.notes!.isNotEmpty) {
          buffer.writeln('📝 **Notes:** ${item.notes}');
        }
        
        if (item.latitude != null && item.longitude != null) {
          buffer.writeln('🗺️ **Coordinates:** ${item.latitude?.toStringAsFixed(6)}, ${item.longitude?.toStringAsFixed(6)}');
        }
        
        // Add some spacing between activities
        buffer.writeln();
      }
      
      // Add separator between days (except for the last day)
      if (i < trip.days.length - 1) {
        buffer.writeln('---');
        buffer.writeln();
      }
    }
    
    // Add footer with helpful information
    buffer.writeln('---');
    buffer.writeln('✨ *Have a wonderful trip! Remember to check local weather and opening hours.*');
    
    return buffer.toString();
  }
  
  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
  


  Trip _enhanceTestTrip(Trip trip) {
    // Return the original trip without enhancement to improve performance
    return trip;
  }

  Future<void> _saveTrip(Trip trip) async {
    try {
      await ref.read(tripNotifierProvider.notifier).saveTrip(trip);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void clearChat() {
    setState(() {
      _messages.clear();
      _currentExtractedTrip = null;
      _currentResponse = '';
      _isProcessing = false;
      _isTyping = false;
    });
    _textController.clear();
    if (widget.onClearChat != null) {
      widget.onClearChat!();
    }
  }

  Trip _jsonToTrip(Map<String, dynamic> json, [String? description]) {
    try {
      // Validate required fields exist and are not null
      if (json['title'] == null || json['days'] == null) {
        throw Exception('Missing required fields in JSON: title or days');
      }
      
      final daysData = json['days'];
      if (daysData is! List) {
        throw Exception('Days field is not a valid list');
      }
      
      // Generate start and end dates if not provided
      final now = DateTime.now();
      final startDate = json['startDate'] != null 
          ? DateTime.parse(json['startDate'] as String)
          : now;
      final endDate = json['endDate'] != null 
          ? DateTime.parse(json['endDate'] as String)
          : startDate.add(Duration(days: daysData.length - 1));
      
      final days = daysData.asMap().entries.map((entry) {
        final index = entry.key;
        final dayJson = entry.value;
        
        if (dayJson == null || dayJson is! Map<String, dynamic>) {
          throw Exception('Invalid day data structure');
        }
        
        // Handle both 'items' and 'activities' fields
        final activitiesData = dayJson['activities'] ?? dayJson['items'];
        final items = <ItineraryItem>[];
        
        if (activitiesData != null && activitiesData is List) {
          for (int actIndex = 0; actIndex < activitiesData.length; actIndex++) {
            final activityJson = activitiesData[actIndex];
            
            if (activityJson is String) {
              // Handle simple string activities
              items.add(ItineraryItem(
                time: 'TBD',
                activity: activityJson,
                location: 'TBD',
                description: null,
                cost: null,
                notes: null,
                latitude: null,
                longitude: null,
              ));
            } else if (activityJson is Map<String, dynamic>) {
              // Handle structured activity objects
              final time = activityJson['time'] as String? ?? '';
              final activity = activityJson['activity'] as String? ?? activityJson['title'] as String? ?? '';
              var location = activityJson['location'] as String? ?? '';
              
              // Extract location from title or description if not explicitly provided
              if (location.isEmpty) {
                final title = activityJson['title'] as String? ?? '';
                final description = activityJson['description'] as String? ?? '';
                final venue = activityJson['venue'] as String? ?? '';
                final place = activityJson['place'] as String? ?? '';
                
                // First try venue or place fields
                if (venue.isNotEmpty) {
                  location = venue;
                } else if (place.isNotEmpty) {
                  location = place;
                } else {
                  // Try to extract location from title (look for patterns like "at Location", "in Location", etc.)
                  final titleLocationMatch = RegExp(r'(?:at|in|visit|explore|near|to)\s+([^,\n\(\)]+)', caseSensitive: false).firstMatch(title);
                  if (titleLocationMatch != null && titleLocationMatch.groupCount > 0) {
                    location = titleLocationMatch.group(1)?.trim() ?? '';
                  } else {
                    // Try to extract from description
                    final descLocationMatch = RegExp(r'(?:at|in|visit|explore|near|to|located)\s+([^,\n\.\(\)]+)', caseSensitive: false).firstMatch(description);
                    if (descLocationMatch != null && descLocationMatch.groupCount > 0) {
                      location = descLocationMatch.group(1)?.trim() ?? '';
                    } else {
                      // Look for location patterns like "Location Name (City)" or "Location - City"
                      final locationPattern = RegExp(r'([A-Z][a-zA-Z\s]+(?:Museum|Park|Tower|Bridge|Cathedral|Church|Palace|Market|Square|Street|Avenue|Center|Centre|Gallery|Theater|Theatre|Restaurant|Cafe|Hotel))', caseSensitive: false).firstMatch(title + ' ' + description);
                      if (locationPattern != null && locationPattern.groupCount > 0) {
                        location = locationPattern.group(1)?.trim() ?? '';
                      } else if (title.isNotEmpty && !title.toLowerCase().contains('breakfast') && !title.toLowerCase().contains('lunch') && !title.toLowerCase().contains('dinner')) {
                        // Use the title as location if no specific location pattern found and it's not a meal
                        location = title;
                      }
                    }
                  }
                }
              }
              
              // If location is still empty but we have coordinates, use them
              if (location.isEmpty && activityJson['latitude'] != null && activityJson['longitude'] != null) {
                final lat = activityJson['latitude'] as double?;
                final lng = activityJson['longitude'] as double?;
                if (lat != null && lng != null) {
                  location = '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
                }
              }
              
              items.add(ItineraryItem(
                time: time,
                activity: activity,
                location: location,
                description: activityJson['description'] as String?,
                cost: activityJson['cost'] as String?,
                notes: activityJson['notes'] as String?,
                latitude: activityJson['latitude'] as double?,
                longitude: activityJson['longitude'] as double?,
              ));
            }
          }
        }
        
        // Calculate the date for this day
        final dayDate = startDate.add(Duration(days: index));
        
        // Parse date with fallback for invalid formats
        DateTime parsedDate = dayDate;
        if (dayJson['date'] != null) {
          try {
            final dateStr = dayJson['date'] as String;
            // Only parse if it looks like a proper date format (contains numbers and dashes/slashes)
            if (RegExp(r'\d{4}-\d{2}-\d{2}|\d{1,2}/\d{1,2}/\d{4}').hasMatch(dateStr)) {
              parsedDate = DateTime.parse(dateStr);
            }
          } catch (e) {
            // Use calculated date if parsing fails
            parsedDate = dayDate;
          }
        }
        
        // Generate a descriptive day title based on activities
        String dayTitle = dayJson['summary'] as String? ?? dayJson['title'] as String? ?? '';
        
        if (dayTitle.isEmpty && items.isNotEmpty) {
          // Create title from first few activities
          final mainActivities = items.take(2).map((item) {
            if (item.location.isNotEmpty && item.location != item.activity) {
              return item.location;
            }
            return item.activity;
          }).where((title) => title.isNotEmpty).toList();
          
          if (mainActivities.isNotEmpty) {
            dayTitle = 'Day ${index + 1}: ${mainActivities.join(' & ')}';
          } else {
            dayTitle = 'Day ${index + 1}';
          }
        } else if (dayTitle.isEmpty) {
          dayTitle = 'Day ${index + 1}';
        } else if (!dayTitle.toLowerCase().contains('day')) {
          dayTitle = 'Day ${index + 1}: $dayTitle';
        }
        
        return DayItinerary(
          date: parsedDate,
          summary: dayTitle,
          items: items,
        );
      }).toList();
      
      return Trip(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] as String? ?? 'Untitled Trip',
        description: description?.isNotEmpty == true ? description : null,
        startDate: startDate,
        endDate: endDate,
        days: days,
        createdAt: DateTime.now(),
        totalTokensUsed: json['totalTokensUsed'] as int? ?? 0,
      );
    } catch (e) {
      print('❌ Error in _jsonToTrip: $e');
      rethrow;
    }
  }

  Map<String, dynamic> _tripToJson(Trip trip) {
    return {
      'title': trip.title,
      'startDate': trip.startDate.toIso8601String().split('T')[0],
      'endDate': trip.endDate.toIso8601String().split('T')[0],
      'days': trip.days.map((day) => {
        'date': day.date.toIso8601String().split('T')[0],
        'summary': day.summary,
        'items': day.items.map((item) => {
          'time': item.time,
          'activity': item.activity,
          'location': item.location,
          'description': item.description,
          'cost': item.cost,
          'notes': item.notes,
          'latitude': item.latitude,
          'longitude': item.longitude,
        }).toList(),
      }).toList(),
      'totalTokensUsed': trip.totalTokensUsed,
    };
  }
}

// Extension to add copyWith method to ChatMessage
extension ChatMessageExtension on ChatMessage {
  ChatMessage copyWith({
    String? id,
    String? content,
    ChatMessageType? type,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}