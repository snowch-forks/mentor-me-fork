// lib/providers/chat_provider.dart
// Phase 3: Conversational Interface - Chat state management

import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/goal.dart';
import '../models/habit.dart';
import '../models/journal_entry.dart';
import '../services/storage_service.dart';
import '../services/ai_service.dart';

class ChatProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final AIService _ai = AIService();

  List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  bool _isTyping = false;

  List<Conversation> get conversations => _conversations;
  Conversation? get currentConversation => _currentConversation;
  bool get isTyping => _isTyping;
  List<ChatMessage> get messages => _currentConversation?.messages ?? [];

  ChatProvider() {
    _loadConversations();
  }

  /// Extract text content from a journal entry regardless of type
  String _extractEntryText(JournalEntry entry) {
    if (entry.type == JournalEntryType.quickNote) {
      return entry.content ?? '';
    } else if (entry.type == JournalEntryType.guidedJournal && entry.qaPairs != null) {
      return entry.qaPairs!
          .map((pair) => '${pair.question}\n${pair.answer}')
          .join('\n\n');
    }
    return '';
  }

  /// Load conversations from storage
  Future<void> _loadConversations() async {
    try {
      final data = await _storage.getConversations();
      if (data != null) {
        _conversations = (data as List)
            .map((json) => Conversation.fromJson(json))
            .toList();

        // Load the most recent conversation as current
        if (_conversations.isNotEmpty) {
          _conversations.sort((a, b) =>
              (b.lastMessageAt ?? b.createdAt).compareTo(a.lastMessageAt ?? a.createdAt));
          _currentConversation = _conversations.first;
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    }
  }

  /// Reload conversations from storage (used when data is cleared/reset)
  Future<void> reload() async {
    _conversations = [];
    _currentConversation = null;
    _isTyping = false;
    await _loadConversations();
    notifyListeners();
  }

  /// Save conversations to storage
  Future<void> _saveConversations() async {
    try {
      final data = _conversations.map((c) => c.toJson()).toList();
      await _storage.saveConversations(data);
    } catch (e) {
      debugPrint('Error saving conversations: $e');
    }
  }

  /// Start a new conversation
  Future<void> startNewConversation({String? title}) async {
    final conversation = Conversation(
      title: title ?? 'Chat ${_conversations.length + 1}',
    );

    _conversations.insert(0, conversation);
    _currentConversation = conversation;

    // Add welcome message from mentor
    await addMentorMessage(
      "Hi! I'm here to help you on your journey. What's on your mind?",
    );

    notifyListeners();
  }

  /// Switch to a different conversation
  void switchConversation(String conversationId) {
    _currentConversation = _conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => _currentConversation!,
    );
    notifyListeners();
  }

  /// Send a user message
  Future<void> sendUserMessage(String content, {bool skipAutoResponse = false}) async {
    if (_currentConversation == null) {
      await startNewConversation();
    }

    final userMessage = ChatMessage(
      sender: MessageSender.user,
      content: content,
    );

    _addMessageToCurrentConversation(userMessage);
    notifyListeners();

    // Generate AI response (unless caller will handle it with context)
    if (!skipAutoResponse) {
      await _generateMentorResponse(content);
    }
  }

  /// Add a message from the mentor
  Future<void> addMentorMessage(String content, {Map<String, dynamic>? metadata}) async {
    final mentorMessage = ChatMessage(
      sender: MessageSender.mentor,
      content: content,
      metadata: metadata,
    );

    _addMessageToCurrentConversation(mentorMessage);
    notifyListeners();
  }

  /// Generate AI response based on user message and context
  Future<void> _generateMentorResponse(String userMessage) async {
    _isTyping = true;
    notifyListeners();

    try {
      // This will be implemented with full context in the next step
      // For now, use a simple AI call
      final response = await _ai.getCoachingResponse(prompt: userMessage);

      _isTyping = false;
      await addMentorMessage(response);
    } catch (e) {
      debugPrint('Error generating mentor response: $e');
      _isTyping = false;
      await addMentorMessage(
        "I'm having trouble connecting right now. Please try again in a moment.",
      );
    }
  }

  /// Generate context-aware AI response with full user data
  Future<String> generateContextualResponse({
    required String userMessage,
    required List<Goal> goals,
    required List<Habit> habits,
    required List<JournalEntry> journalEntries,
  }) async {
    // Build comprehensive context
    final context = _buildContext(
      goals: goals,
      habits: habits,
      journalEntries: journalEntries,
    );

    // Build conversation history
    final conversationHistory = _buildConversationHistory();

    // Create system prompt
    final systemPrompt = '''
You are a supportive, encouraging personal mentor helping the user achieve their goals and become their best self.

Your tone is: warm, supportive, direct but not harsh, encouraging but not saccharine.

Context about the user:
$context

Recent conversation:
$conversationHistory

User's message: $userMessage

Respond as their mentor. Be specific and reference their actual data (goals, habits, progress) when relevant. Keep responses concise (2-3 sentences max unless explaining something complex).
''';

    try {
      final response = await _ai.getCoachingResponse(prompt: systemPrompt);
      return response;
    } catch (e) {
      debugPrint('Error in contextual response: $e');
      return "I'm having trouble processing that right now. Could you try again?";
    }
  }

  /// Build context string from user data
  String _buildContext({
    required List<Goal> goals,
    required List<Habit> habits,
    required List<JournalEntry> journalEntries,
  }) {
    final buffer = StringBuffer();

    // Goals context
    final activeGoals = goals.where((g) => g.isActive).toList();
    if (activeGoals.isNotEmpty) {
      buffer.writeln('\nActive Goals:');
      for (final goal in activeGoals) {
        buffer.writeln(
            '- ${goal.title} (${goal.currentProgress}% complete, ${goal.category})');
      }
    }

    // Habits context
    if (habits.isNotEmpty) {
      buffer.writeln('\nHabits:');
      for (final habit in habits.take(5)) {
        buffer.writeln(
            '- ${habit.title} (${habit.currentStreak} day streak, ${habit.isActive ? "active" : "inactive"})');
      }
    }

    // Recent journal entries (emotional context)
    final recentJournals = journalEntries.take(3).toList();
    if (recentJournals.isNotEmpty) {
      buffer.writeln('\nRecent Journal Entries:');
      for (final entry in recentJournals) {
        final entryText = _extractEntryText(entry);
        final preview = entryText.length > 100
            ? '${entryText.substring(0, 100)}...'
            : entryText;
        buffer.writeln('- ${_formatDate(entry.createdAt)}: $preview');
      }
    }

    return buffer.toString();
  }

  /// Build conversation history string
  String _buildConversationHistory() {
    if (_currentConversation == null || _currentConversation!.messages.isEmpty) {
      return '(This is the start of the conversation)';
    }

    final buffer = StringBuffer();
    final recentMessages = _currentConversation!.messages.reversed.take(6).toList().reversed;

    for (final msg in recentMessages) {
      final sender = msg.isFromUser ? 'User' : 'Mentor';
      buffer.writeln('$sender: ${msg.content}');
    }

    return buffer.toString();
  }

  /// Helper to add message to current conversation
  void _addMessageToCurrentConversation(ChatMessage message) {
    if (_currentConversation == null) return;

    final updatedMessages = [..._currentConversation!.messages, message];
    _currentConversation = _currentConversation!.copyWith(
      messages: updatedMessages,
      lastMessageAt: DateTime.now(),
    );

    // Update in list
    final index = _conversations.indexWhere((c) => c.id == _currentConversation!.id);
    if (index != -1) {
      _conversations[index] = _currentConversation!;
    }

    _saveConversations();
  }

  /// Delete a conversation
  Future<void> deleteConversation(String conversationId) async {
    _conversations.removeWhere((c) => c.id == conversationId);

    if (_currentConversation?.id == conversationId) {
      _currentConversation = _conversations.isNotEmpty ? _conversations.first : null;
    }

    await _saveConversations();
    notifyListeners();
  }

  /// Clear current conversation (start fresh)
  Future<void> clearCurrentConversation() async {
    if (_currentConversation != null) {
      _currentConversation = _currentConversation!.copyWith(messages: []);

      final index = _conversations.indexWhere((c) => c.id == _currentConversation!.id);
      if (index != -1) {
        _conversations[index] = _currentConversation!;
      }

      await _saveConversations();
      notifyListeners();
    }
  }

  /// Format date helper
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    return '${date.month}/${date.day}';
  }
}
