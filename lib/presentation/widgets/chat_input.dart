import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSend;
  final bool isEnabled;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: isEnabled,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Describe your dream trip...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: isEnabled ? (value) => _handleSend() : null,
              ),
            ),
            const SizedBox(width: AppConstants.smallPadding),
            FloatingActionButton(
              onPressed: isEnabled ? _handleSend : null,
              mini: true,
              child: Icon(
                Icons.send,
                color: isEnabled ? null : theme.disabledColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleSend() {
    final text = controller.text.trim();
    if (text.isNotEmpty) {
      onSend(text);
    }
  }
}