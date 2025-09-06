import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/trip.dart';
import '../providers/trip_provider.dart';
import '../widgets/chat_message_widget.dart';
import '../widgets/chat_input.dart';
import '../widgets/typing_indicator.dart';
import '../../core/constants/app_constants.dart';
import '../../data/datasources/ai_agent_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String? existingTripId;

  const ChatScreen({super.key, this.existingTripId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  bool _isGenerating = false;
  Trip? _currentTrip;

  @override
  void initState() {
    super.initState();
    _loadExistingTrip();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingTrip() async {
    if (widget.existingTripId != null) {
      final trip = await ref.read(tripByIdProvider(widget.existingTripId!).future);
      if (trip != null) {
        setState(() {
          _currentTrip = trip;
        });
        ref.read(tripNotifierProvider.notifier).setTrip(trip);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatMessages = ref.watch(chatNotifierProvider);
    final tripState = ref.watch(tripNotifierProvider);
    final streamState = ref.watch(itineraryStreamNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentTrip?.title ?? 'New Trip'),
        actions: [
          if (_currentTrip != null)
            IconButton(
              onPressed: () => context.push('/trip/${_currentTrip!.id}'),
              icon: const Icon(Icons.visibility),
              tooltip: 'View Trip',
            ),
          IconButton(
            onPressed: _clearChat,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildChatList(chatMessages, streamState),
          ),
          if (_isGenerating) const TypingIndicator(),
          ChatInput(
            controller: _textController,
            onSend: _handleSendMessage,
            isEnabled: !_isGenerating,
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(List<ChatMessage> messages, AsyncValue<String> streamState) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: messages.length + (streamState.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < messages.length) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
            child: ChatMessageWidget(
              message: messages[index],
              onTripGenerated: _handleTripGenerated,
            ),
          );
        } else {
          // Show streaming message
          return Padding(
            padding: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
            child: ChatMessageWidget(
              message: ChatMessage(
                id: 'streaming',
                content: streamState.value ?? '',
                type: ChatMessageType.assistant,
                timestamp: DateTime.now(),
                isStreaming: true,
              ),
              onTripGenerated: _handleTripGenerated,
            ),
          );
        }
      },
    );
  }

  Future<void> _handleSendMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Add user message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: message.trim(),
      type: ChatMessageType.user,
      timestamp: DateTime.now(),
    );

    ref.read(chatNotifierProvider.notifier).addMessage(userMessage);
    _textController.clear();
    _scrollToBottom();

    setState(() {
      _isGenerating = true;
    });

    try {
      // Use enhanced chat with function calling
      final aiService = ref.read(aiAgentServiceProvider);
      final chatMessages = ref.read(chatNotifierProvider);
      String fullResponse = '';
      
      // Create streaming assistant message
      final assistantMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '',
        type: ChatMessageType.assistant,
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      
      ref.read(chatNotifierProvider.notifier).addMessage(assistantMessage);
      
      await for (final chunk in aiService.chatWithFunctions(chatMessages)) {
        fullResponse += chunk;
        
        // Update the streaming message
        final updatedMessage = ChatMessage(
          id: assistantMessage.id,
          content: fullResponse,
          type: ChatMessageType.assistant,
          timestamp: assistantMessage.timestamp,
          isStreaming: true,
        );
        
        ref.read(chatNotifierProvider.notifier).updateLastMessage(updatedMessage);
        _scrollToBottom();
      }
      
      // Mark message as complete
      final finalMessage = ChatMessage(
        id: assistantMessage.id,
        content: fullResponse,
        type: ChatMessageType.assistant,
        timestamp: assistantMessage.timestamp,
        isStreaming: false,
      );
      
      ref.read(chatNotifierProvider.notifier).updateLastMessage(finalMessage);

    } catch (error) {
      // Add error message
      final errorMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Sorry, I encountered an error: ${error.toString()}',
        type: ChatMessageType.assistant,
        timestamp: DateTime.now(),
      );

      ref.read(chatNotifierProvider.notifier).addMessage(errorMessage);
    } finally {
      setState(() {
        _isGenerating = false;
      });
      ref.read(itineraryStreamNotifierProvider.notifier).reset();
      _scrollToBottom();
    }
  }

  void _handleTripGenerated(Trip trip) {
    setState(() {
      _currentTrip = trip;
    });
    
    // Show save dialog
    _showSaveDialog(trip);
  }

  void _showSaveDialog(Trip trip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Trip'),
        content: const Text('Would you like to save this trip itinerary?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(tripNotifierProvider.notifier).saveTrip(trip);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Trip saved successfully!'),
                  ),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _clearChat() {
    ref.read(chatNotifierProvider.notifier).clearMessages();
    ref.read(tripNotifierProvider.notifier).clearTrip();
    setState(() {
      _currentTrip = null;
    });
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
}