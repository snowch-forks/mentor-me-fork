// lib/screens/chat_screen.dart
// Phase 3: Conversational Interface - Chat UI

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/chat_provider.dart';
import '../providers/goal_provider.dart';
import '../providers/habit_provider.dart';
import '../providers/journal_provider.dart';
import '../models/chat_message.dart';
import '../theme/app_spacing.dart';
import '../constants/app_strings.dart';
import '../services/feature_discovery_service.dart';

class ChatScreen extends StatefulWidget {
  final String? initialMessage;

  const ChatScreen({super.key, this.initialMessage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Pre-fill message if provided
    if (widget.initialMessage != null) {
      _messageController.text = widget.initialMessage!;
    }

    // Track that user has discovered chat feature
    FeatureDiscoveryService().markChatOpened();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final chatProvider = context.read<ChatProvider>();
    final goalProvider = context.read<GoalProvider>();
    final habitProvider = context.read<HabitProvider>();
    final journalProvider = context.read<JournalProvider>();

    // Send user message (adds to conversation, sets typing state)
    await chatProvider.sendUserMessage(text, skipAutoResponse: true);
    _scrollToBottom();

    // Generate contextual AI response with full user context
    try {
      final response = await chatProvider.generateContextualResponse(
        userMessage: text,
        goals: goalProvider.goals,
        habits: habitProvider.habits,
        journalEntries: journalProvider.entries,
      );

      await chatProvider.addMentorMessage(response);
      _scrollToBottom();
    } catch (e) {
      // Error already handled in provider
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.psychology,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            AppSpacing.gapHorizontalMd,
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.yourMentor,
                  style: TextStyle(fontSize: 16),
                ),
                const Text(
                  'Here to help',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showMenu(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final messages = chatProvider.messages;

                if (messages.isEmpty) {
                  return _buildEmptyState(context);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  itemCount: messages.length + (chatProvider.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == messages.length) {
                      // Typing indicator
                      return _buildTypingIndicator(key: const ValueKey('typing_indicator'));
                    }

                    final message = messages[index];
                    return _buildMessageBubble(
                      context,
                      message,
                      key: ValueKey(message.id),
                    );
                  },
                );
              },
            ),
          ),

          // Input field
          _buildMessageInput(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            AppSpacing.gapLg,
            Text(
              'Start a conversation',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            AppSpacing.gapSm,
            Text(
              'Ask me about your goals, get advice, or just chat!',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.gapXl,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _buildSuggestionChip(context, 'How am I doing overall?'),
                _buildSuggestionChip(context, 'What should I focus on today?'),
                _buildSuggestionChip(context, 'Why am I not making progress?'),
                _buildSuggestionChip(context, 'Help me reflect on my week'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(BuildContext context, String text) {
    return ActionChip(
      label: Text(text),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      side: BorderSide(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
      ),
      onPressed: () {
        _messageController.text = text;
        _sendMessage();
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message, {Key? key}) {
    final isUser = message.isFromUser;

    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.psychology,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            AppSpacing.gapHorizontalSm,
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: isUser
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(AppRadius.lg),
                  topRight: const Radius.circular(AppRadius.lg),
                  bottomLeft: Radius.circular(isUser ? AppRadius.lg : 4),
                  bottomRight: Radius.circular(isUser ? 4 : AppRadius.lg),
                ),
              ),
              child: isUser
                  ? Text(
                      message.content,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    )
                  : MarkdownBody(
                      data: message.content,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        strong: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                        em: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                        listBullet: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            AppSpacing.gapHorizontalSm,
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.person,
                size: 16,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator({Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.psychology,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          AppSpacing.gapHorizontalSm,
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                AppSpacing.gapHorizontalXs,
                _buildTypingDot(150),
                AppSpacing.gapHorizontalXs,
                _buildTypingDot(300),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int delay) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withOpacity(0.3 + (value * 0.7)),
            shape: BoxShape.circle,
          ),
        );
      },
      onEnd: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Message your mentor...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          AppSpacing.gapHorizontalMd,
          IconButton.filled(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
          ),
        ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Start New Conversation'),
              onTap: () {
                Navigator.pop(context);
                context.read<ChatProvider>().startNewConversation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Clear Current Chat'),
              onTap: () {
                Navigator.pop(context);
                context.read<ChatProvider>().clearCurrentConversation();
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('View Conversation History'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to conversation history screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
