class ChatMessageModel {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  ChatMessageModel({
    required this.message,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
