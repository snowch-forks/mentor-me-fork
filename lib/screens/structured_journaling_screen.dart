import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mentor_me/models/journal_template.dart';
import 'package:mentor_me/models/structured_journaling_session.dart';
import 'package:mentor_me/models/chat_message.dart';
import 'package:mentor_me/models/journal_entry.dart';
import 'package:mentor_me/providers/journal_template_provider.dart';
import 'package:mentor_me/providers/journal_provider.dart';
import 'package:mentor_me/services/structured_journaling_service.dart';
import 'package:mentor_me/services/ai_service.dart';
import 'package:mentor_me/services/debug_service.dart';
import 'package:mentor_me/theme/app_spacing.dart';

class StructuredJournalingScreen extends StatefulWidget {
  final JournalTemplate? template;
  final StructuredJournalingSession? existingSession;

  const StructuredJournalingScreen({
    super.key,
    this.template,
    this.existingSession,
  });

  @override
  State<StructuredJournalingScreen> createState() =>
      _StructuredJournalingScreenState();
}

class _StructuredJournalingScreenState extends State<StructuredJournalingScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _service = StructuredJournalingService();
  final _debug = DebugService();

  JournalTemplate? _selectedTemplate;
  StructuredJournalingSession? _currentSession;
  bool _isTyping = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    if (widget.existingSession != null) {
      _currentSession = widget.existingSession;
      _selectedTemplate = context
          .read<JournalTemplateProvider>()
          .getTemplateById(widget.existingSession!.templateId);
    } else if (widget.template != null) {
      _selectedTemplate = widget.template;
      _startNewSession();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _startNewSession() async {
    if (_selectedTemplate == null) return;

    final provider = context.read<JournalTemplateProvider>();
    final session = await provider.startSession(_selectedTemplate!);

    setState(() {
      _currentSession = session;
    });

    // Send the first AI message to start the conversation
    await _sendInitialMessage();
  }

  Future<void> _sendInitialMessage() async {
    if (_selectedTemplate == null || _currentSession == null) return;

    setState(() {
      _isTyping = true;
    });

    try {
      final systemPrompt = _service.generateSystemPrompt(
        _selectedTemplate!,
        _currentSession!.currentStep ?? 0,
      );

      final response = await AIService().generateCoachingResponse(
        prompt: 'Start the journaling session. Greet the user warmly and ask the first question.',
        context: {'systemPrompt': systemPrompt},
      );

      final aiMessage = ChatMessage(
        content: response,
        sender: MessageSender.mentor,
        timestamp: DateTime.now(),
      );

      final updatedSession = _currentSession!.copyWith(
        conversation: [..._currentSession!.conversation, aiMessage],
        currentStep: 0,
      );

      await context.read<JournalTemplateProvider>().updateSession(updatedSession);

      setState(() {
        _currentSession = updatedSession;
      });

      _scrollToBottom();
    } catch (e, stackTrace) {
      await _debug.error(
        'StructuredJournalingScreen',
        'Failed to send initial message',
        
        stackTrace: stackTrace.toString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to start session. Please try again.')),
        );
      }
    } finally {
      setState(() {
        _isTyping = false;
      });
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentSession == null || _selectedTemplate == null) {
      return;
    }

    _messageController.clear();

    // Add user message
    final userMessage = ChatMessage(
      content: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    final updatedConversation = [..._currentSession!.conversation, userMessage];
    var updatedSession = _currentSession!.copyWith(
      conversation: updatedConversation,
    );

    await context.read<JournalTemplateProvider>().updateSession(updatedSession);

    setState(() {
      _currentSession = updatedSession;
      _isTyping = true;
    });

    _scrollToBottom();

    // Generate AI response
    try {
      final currentStep = _currentSession!.currentStep ?? 0;
      final nextStep = currentStep + 1;

      final systemPrompt = _service.generateSystemPrompt(
        _selectedTemplate!,
        nextStep,
      );

      // Build conversation context
      final conversationContext = _currentSession!.conversation
          .map((m) => '${m.sender.name}: ${m.content}')
          .join('\n');

      final isComplete = nextStep >= _selectedTemplate!.fields.length;

      final prompt = isComplete
          ? 'The user has completed all fields. Provide a warm summary and closing message.'
          : 'Continue the conversation. Move to the next question.';

      final response = await AIService().generateCoachingResponse(
        prompt: '$prompt\n\nConversation so far:\n$conversationContext',
        context: {'systemPrompt': systemPrompt},
      );

      final aiMessage = ChatMessage(
        content: response,
        sender: MessageSender.mentor,
        timestamp: DateTime.now(),
      );

      updatedSession = updatedSession.copyWith(
        conversation: [...updatedSession.conversation, aiMessage],
        currentStep: nextStep,
        isComplete: isComplete,
      );

      await context.read<JournalTemplateProvider>().updateSession(updatedSession);

      setState(() {
        _currentSession = updatedSession;
      });

      _scrollToBottom();

      // If complete, show save option
      if (isComplete) {
        _showSaveDialog();
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'StructuredJournalingScreen',
        'Failed to generate AI response',
        
        stackTrace: stackTrace.toString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get response. Please try again.')),
        );
      }
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  Future<void> _saveSession() async {
    if (_currentSession == null || _selectedTemplate == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Extract structured data
      final structuredData = await _service.extractStructuredData(
        _selectedTemplate!,
        _currentSession!.conversation,
      );

      // Update session with extracted data
      final finalSession = _currentSession!.copyWith(
        extractedData: structuredData,
        isComplete: true,
      );

      await context.read<JournalTemplateProvider>().updateSession(finalSession);

      // Create journal entry
      final journalEntry = JournalEntry(
        type: JournalEntryType.structuredJournal,
        structuredSessionId: finalSession.id,
        structuredData: structuredData,
        content: null, // Content is in the session conversation
        createdAt: finalSession.createdAt,
      );

      await context.read<JournalProvider>().addEntry(journalEntry);

      await _debug.info(
        'StructuredJournalingScreen',
        'Saved structured journal entry',
        metadata: {
          'templateId': _selectedTemplate!.id,
          'sessionId': finalSession.id,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Journal entry saved!')),
        );

        Navigator.of(context).pop();
      }
    } catch (e, stackTrace) {
      await _debug.error(
        'StructuredJournalingScreen',
        'Failed to save session',
        
        stackTrace: stackTrace.toString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save entry. Please try again.')),
        );
      }
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _showSaveDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Session Complete'),
        content: const Text(
          'You\'ve completed all the questions! Would you like to save this journal entry?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Not yet'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              _saveSession();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Session?'),
        content: const Text(
          'Are you sure you want to discard this journaling session? Your progress will be lost.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (_currentSession != null) {
                await context
                    .read<JournalTemplateProvider>()
                    .deleteSession(_currentSession!.id);
              }
              if (mounted) {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close screen
              }
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedTemplate == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Structured Journaling')),
        body: _buildTemplateSelection(),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Row(
          children: [
            if (_selectedTemplate!.emoji != null)
              Text(_selectedTemplate!.emoji!, style: const TextStyle(fontSize: 24)),
            if (_selectedTemplate!.emoji != null) AppSpacing.gapHorizontalSm,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedTemplate!.name,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (_selectedTemplate!.showProgressIndicator &&
                      _currentSession != null)
                    Text(
                      'Step ${(_currentSession!.currentStep ?? 0) + 1} of ${_selectedTemplate!.fields.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (_currentSession != null && !_currentSession!.isComplete)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _showDiscardDialog,
              tooltip: 'Discard',
            ),
          if (_currentSession != null && _currentSession!.isComplete)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveSession,
              tooltip: 'Save',
            ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _currentSession == null
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount:
                        _currentSession!.conversation.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _currentSession!.conversation.length) {
                        return _buildTypingIndicator();
                      }

                      final message = _currentSession!.conversation[index];
                      return _buildMessageBubble(context, message);
                    },
                  ),
          ),

          // Input field
          if (_currentSession != null && !_currentSession!.isComplete)
            _buildMessageInput(context),
        ],
      ),
    );
  }

  Widget _buildTemplateSelection() {
    return Consumer<JournalTemplateProvider>(
      builder: (context, provider, child) {
        final templates = provider.allTemplates;

        if (templates.isEmpty) {
          return const Center(
            child: Text('No templates available'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: templates.length,
          itemBuilder: (context, index) {
            final template = templates[index];
            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: ListTile(
                leading: template.emoji != null
                    ? Text(template.emoji!, style: const TextStyle(fontSize: 32))
                    : const Icon(Icons.article),
                title: Text(template.name),
                subtitle: Text(template.description),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  setState(() {
                    _selectedTemplate = template;
                  });
                  _startNewSession();
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage message) {
    final isUser = message.sender == MessageSender.user;

    return Padding(
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
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
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

  Widget _buildTypingIndicator() {
    return Padding(
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
                  hintText: 'Type your response...',
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
            AppSpacing.gapHorizontalSm,
            FilledButton(
              onPressed: _isTyping ? null : _sendMessage,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(AppSpacing.md),
              ),
              child: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
