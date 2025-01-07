import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import 'message_bubble.dart';

class ChatMessage extends StatelessWidget {
  final ChatMessageModel message;

  const ChatMessage({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          MessageBubble(message: message),
        ],
      ),
    );
  }
}
