import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/realtime_whiteboard_service.dart';
import '../models/session.dart';
import '../models/whiteboard_user.dart';

class ParticipantList extends StatelessWidget {
  final List<WhiteboardUser>? collaborators;
  final Function(String)? onRemove;

  const ParticipantList({
    super.key, 
    this.collaborators,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<RealtimeWhiteboardService>(context);
    final participants = collaborators ?? [];
    final participantCount = service.participantCount.value;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'Participants ($participantCount)',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(),
          Flexible(
            child: participants.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Text('No participants yet'),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: participants.length,
                    itemBuilder: (context, index) {
                      final participant = participants[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getAvatarColor(participant['user_id'] ?? 'unknown'),
                          child: Text(
                            (participant['role'] ?? 'U').substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(participant['user_id'] ?? 'Unknown User'),
                        subtitle: Text(participant['role'] ?? 'participant'),
                        trailing: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String id) {
    // Generate a consistent color based on user ID
    final colors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
    ];
    
    final colorIndex = id.hashCode % colors.length;
    return colors[colorIndex.abs()];
  }
}