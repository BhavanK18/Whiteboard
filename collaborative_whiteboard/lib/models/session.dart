import 'package:flutter/material.dart';

class WhiteboardSession {
  final String id;
  final String name;
  final String creatorId;
  final String creatorName;
  final DateTime createdAt;
  final List<String> participants;
  final bool isPublic;
  final String sessionCode;
  final String? inviteLink;

  WhiteboardSession({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.creatorName,
    required this.createdAt,
    required this.participants,
    required this.isPublic,
    required this.sessionCode,
    this.inviteLink,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'participants': participants,
      'isPublic': isPublic,
      'sessionCode': sessionCode,
      'inviteLink': inviteLink,
    };
  }

  factory WhiteboardSession.fromJson(Map<String, dynamic> json) {
    return WhiteboardSession(
      id: json['id'],
      name: json['name'],
      creatorId: json['creatorId'],
      creatorName: json['creatorName'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt']),
      participants: List<String>.from(json['participants'] ?? []),
      sessionCode: json['sessionCode'] ?? json['code'] ?? '',
      inviteLink: json['inviteLink'],
      isPublic: json['isPublic'] ?? false,
    );
  }
}

// WhiteboardUser is now defined in whiteboard_user.dart