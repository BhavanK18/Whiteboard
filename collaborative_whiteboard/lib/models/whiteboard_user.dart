import 'package:flutter/material.dart';

class WhiteboardUser {
  final String id;
  final String name;
  final String? email;
  final String? avatarUrl;
  final DateTime createdAt;
  final String? displayName;
  final String? photoURL;
  final bool isOnline;
  Color? cursorColor;

  WhiteboardUser({
    required this.id,
    required this.name,
    this.email,
    this.avatarUrl,
    required this.createdAt,
    this.displayName,
    this.photoURL,
    this.isOnline = false,
    this.cursorColor,
  });

  // Allow accessing user data with indexing for compatibility with old code
  dynamic operator [](String key) {
    switch(key) {
      case 'id': return id;
      case 'name': return name;
      case 'email': return email;
      case 'avatarUrl': return avatarUrl;
      case 'createdAt': return createdAt;
      case 'user_id': return id;
      case 'display_name': return displayName ?? name;
      case 'role': return 'participant'; // Default role
      default: return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'displayName': displayName ?? name,
      'photoURL': photoURL ?? avatarUrl,
      'isOnline': isOnline,
      'cursorColor': cursorColor?.value,
    };
  }

  factory WhiteboardUser.fromJson(Map<String, dynamic> json) {
    return WhiteboardUser(
      id: json['id'],
      name: json['name'] ?? json['displayName'] ?? 'Unknown User',
      email: json['email'],
      avatarUrl: json['avatarUrl'] ?? json['photoURL'],
      createdAt: json['createdAt'] != null 
        ? (json['createdAt'] is int 
            ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
            : DateTime.parse(json['createdAt'].toString())) 
        : DateTime.now(),
      displayName: json['displayName'],
      photoURL: json['photoURL'],
      isOnline: json['isOnline'] ?? false,
      cursorColor: json['cursorColor'] != null ? Color(json['cursorColor']) : null,
    );
  }
}