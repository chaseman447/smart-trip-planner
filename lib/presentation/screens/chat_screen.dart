import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/trip.dart';
import '../providers/trip_provider.dart';
import '../widgets/multimodal_chat_widget.dart';
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
  Trip? _currentTrip;
  VoidCallback? _clearChatCallback;

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
      body: MultimodalChatWidget(
        currentTrip: _currentTrip,
        onTripGenerated: _handleTripGenerated,
        onClearChat: () {
          setState(() {
            _currentTrip = null;
          });
        },
        onRegisterClearCallback: (callback) {
          _clearChatCallback = callback;
        },
      ),
    );
  }

  // Removed _buildChatList and _handleSendMessage - now using MultimodalChatWidget

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
    // Clear the chat widget's state as well
    if (_clearChatCallback != null) {
      _clearChatCallback!();
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
}