// lib/models/chat_message.dart
// Phase 3: Conversational Interface - Chat message model

import 'package:uuid/uuid.dart';

/// Represents who sent the message
enum MessageSender {
  user,
  mentor,
}

/// Represents a single message in the chat conversation
class ChatMessage {
  final String id;
  final MessageSender sender;
  final String content;
  final DateTime timestamp;
  final bool isTyping; // For showing typing indicator
  final Map<String, dynamic>? metadata; // Optional metadata (e.g., related goal ID)

  ChatMessage({
    String? id,
    required this.sender,
    required this.content,
    DateTime? timestamp,
    this.isTyping = false,
    this.metadata,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender.toString(),
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isTyping': isTyping,
      'metadata': metadata,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      sender: MessageSender.values.firstWhere(
        (e) => e.toString() == json['sender'],
      ),
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isTyping: json['isTyping'] ?? false,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  ChatMessage copyWith({
    String? content,
    bool? isTyping,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id,
      sender: sender,
      content: content ?? this.content,
      timestamp: timestamp,
      isTyping: isTyping ?? this.isTyping,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isFromUser => sender == MessageSender.user;
  bool get isFromMentor => sender == MessageSender.mentor;
}

/// Represents a conversation session
class Conversation {
  final String id;
  final String title; // e.g., "Chat about Career Goals"
  final DateTime createdAt;
  final DateTime? lastMessageAt;
  final List<ChatMessage> messages;

  Conversation({
    String? id,
    required this.title,
    DateTime? createdAt,
    this.lastMessageAt,
    List<ChatMessage>? messages,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        messages = messages ?? [];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'messages': messages.map((m) => m.toJson()).toList(),
    };
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'],
      title: json['title'],
      createdAt: DateTime.parse(json['createdAt']),
      lastMessageAt: json['lastMessageAt'] != null
          ? DateTime.parse(json['lastMessageAt'])
          : null,
      messages: (json['messages'] as List?)
              ?.map((m) => ChatMessage.fromJson(m))
              .toList() ??
          [],
    );
  }

  Conversation copyWith({
    String? title,
    DateTime? lastMessageAt,
    List<ChatMessage>? messages,
  }) {
    return Conversation(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messages: messages ?? this.messages,
    );
  }

  int get messageCount => messages.length;
  bool get hasMessages => messages.isNotEmpty;
}
