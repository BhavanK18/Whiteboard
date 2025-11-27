// This is the Session class required by RealtimeWhiteboardService
// Note: The app already has WhiteboardSession in session.dart, but this class
// is specifically for the realtime implementation

// SessionModel is an alias of Session for better naming consistency
typedef SessionModel = Session;
class Session {
  final String id;
  final String name;
  final String creatorId;
  final List<String> participants;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isActive;
  final String code; // Session code for sharing
  final String whiteboardId; // ID of the associated whiteboard

  Session({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.participants,
    required this.createdAt,
    this.expiresAt,
    this.isActive = true,
    this.code = '',
    this.whiteboardId = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'creatorId': creatorId,
      'participants': participants,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'isActive': isActive,
      'code': code,
      'whiteboardId': whiteboardId,
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? 'Session',
      creatorId: json['creatorId'] ?? json['ownerId'] ?? '',
      participants: json['participants'] != null 
          ? List<String>.from(json['participants']) 
          : <String>[],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      expiresAt: json['expiresAt'] != null 
          ? DateTime.parse(json['expiresAt']) 
          : null,
      isActive: json['isActive'] ?? true,
      code: json['code'] ?? '',
      whiteboardId: json['whiteboardId'] ?? json['id'] ?? '', // Default to session id if not provided
    );
  }
}