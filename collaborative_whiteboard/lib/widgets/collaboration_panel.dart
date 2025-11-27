import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../services/realtime_whiteboard_service.dart';
import '../models/session.dart';

class CollaborationPanel extends StatefulWidget {
  const CollaborationPanel({super.key});

  @override
  State<CollaborationPanel> createState() => _CollaborationPanelState();
}

class _CollaborationPanelState extends State<CollaborationPanel> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _sessionCodeController = TextEditingController();
  bool _isCreatingSession = false;
  bool _isJoiningSession = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    _sessionCodeController.dispose();
    super.dispose();
  }

  // Create a new session
  Future<void> _createSession(RealtimeWhiteboardService service) async {
    setState(() {
      _isCreatingSession = true;
      _errorMessage = null;
    });

    try {
      await service.createSession();
      // Success!
    } catch (e) {
      setState(() {
        _errorMessage = 'Error creating session: $e';
      });
    } finally {
      setState(() {
        _isCreatingSession = false;
      });
    }
  }

  // Join an existing session
  Future<void> _joinSession(RealtimeWhiteboardService service) async {
    if (_sessionCodeController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a session code';
      });
      return;
    }

    setState(() {
      _isJoiningSession = true;
      _errorMessage = null;
    });

    try {
      await service.joinSession(_sessionCodeController.text.trim());
      // Success!
      _sessionCodeController.clear();
    } catch (e) {
      setState(() {
        _errorMessage = 'Error joining session: $e';
      });
    } finally {
      setState(() {
        _isJoiningSession = false;
      });
    }
  }

  // Leave current session
  void _leaveSession(RealtimeWhiteboardService service) {
    service.leaveSession();
  }

  // Send a chat message
  void _sendMessage(RealtimeWhiteboardService service) {
    if (_messageController.text.isNotEmpty) {
      service.sendChatMessage(_messageController.text);
      _messageController.clear();
    }
  }

  // Copy session code to clipboard
  Future<void> _copySessionCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session code copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RealtimeWhiteboardService>(
      builder: (context, service, child) {
        final isCollaborating = service.isCollaborating;
        final session = service.currentSession;
        final participantCount = service.participantCount;
        final messages = service.chatMessages;

        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(context).colorScheme.surfaceVariant,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isCollaborating
                          ? 'Collaboration Mode'
                          : 'Start Collaborating',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (isCollaborating)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.people, size: 16, color: Colors.white),
                              const SizedBox(width: 4),
                              ValueListenableBuilder<int>(
                                valueListenable: participantCount,
                                builder: (context, count, _) {
                                  return Text(
                                    '$count',
                                    style: const TextStyle(color: Colors.white),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => _leaveSession(service),
                          tooltip: 'Leave session',
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Error message
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Theme.of(context).colorScheme.errorContainer,
                width: double.infinity,
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ),

            // Session info
            if (isCollaborating && session != null)
              Container(
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session Code: ${session.code}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Share this code to invite others to collaborate',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () => _copySessionCode(session.code),
                      tooltip: 'Copy session code',
                    ),
                  ],
                ),
              ),

            // Either collaboration controls or chat
            Expanded(
              child: isCollaborating
                  ? _buildChatSection(messages, service)
                  : _buildCollaborationControls(service),
            ),
          ],
        );
      },
    );
  }

  // Build the chat section
  Widget _buildChatSection(
      ValueNotifier<List<String>> messages, RealtimeWhiteboardService service) {
    return Column(
      children: [
        // Messages
        Expanded(
          child: ValueListenableBuilder<List<String>>(
            valueListenable: messages,
            builder: (context, messageList, _) {
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: messageList.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(messageList[index]),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // Message input
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(service),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _sendMessage(service),
                tooltip: 'Send message',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Build controls to start collaboration
  Widget _buildCollaborationControls(RealtimeWhiteboardService service) {
    return Column(
      children: [
        // Tab bar
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Create Session'),
            Tab(text: 'Join Session'),
          ],
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // Create session tab
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Create a new collaborative session to share your whiteboard',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isCreatingSession
                            ? null
                            : () => _createSession(service),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: _isCreatingSession
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Create Collaboration Session'),
                      ),
                    ],
                  ),
                ),
              ),

              // Join session tab
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Enter a session code to join an existing whiteboard session',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _sessionCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Session Code',
                          hintText: 'Enter 6-character code',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          letterSpacing: 4,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLength: 6,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isJoiningSession
                            ? null
                            : () => _joinSession(service),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: _isJoiningSession
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Join Session'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}