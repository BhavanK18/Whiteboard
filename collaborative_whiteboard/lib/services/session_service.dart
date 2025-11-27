import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/session.dart';
import 'auth_service.dart';

class SessionService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<WhiteboardSession> _mySessions = [];
  List<WhiteboardSession> _publicSessions = [];
  
  List<WhiteboardSession> get mySessions => List.unmodifiable(_mySessions);
  List<WhiteboardSession> get publicSessions => List.unmodifiable(_publicSessions);
  
  WhiteboardSession? _currentSession;
  WhiteboardSession? get currentSession => _currentSession;
  
  List<WhiteboardUser> _currentSessionParticipants = [];
  List<WhiteboardUser> get currentSessionParticipants => 
      List.unmodifiable(_currentSessionParticipants);
  
  Future<void> fetchMySessions() async {
    try {
      if (_auth.currentUser == null) return;
      
      final userId = _auth.currentUser!.uid;
      
      final querySnapshot = await _firestore
          .collection('sessions')
          .where('participants', arrayContains: userId)
          .orderBy('createdAt', descending: true)
          .get();
          
      _mySessions = querySnapshot.docs
          .map((doc) => WhiteboardSession.fromJson(doc.data()))
          .toList();
          
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching my sessions: $e');
    }
  }
  
  Future<void> fetchPublicSessions() async {
    try {
      final querySnapshot = await _firestore
          .collection('sessions')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
          
      _publicSessions = querySnapshot.docs
          .map((doc) => WhiteboardSession.fromJson(doc.data()))
          .toList();
          
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching public sessions: $e');
    }
  }
  
  Future<WhiteboardSession> createSession(String name, bool isPublic) async {
    if (_auth.currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      final userId = _auth.currentUser!.uid;
      final userName = _auth.currentUser!.displayName ?? 'User';
      final sessionId = const Uuid().v4();
      
      final session = WhiteboardSession(
        id: sessionId,
        name: name,
        creatorId: userId,
        creatorName: userName,
        createdAt: DateTime.now(),
        participants: [userId],
        isPublic: isPublic,
      );
      
      // Save session to Firestore
      await _firestore
          .collection('sessions')
          .doc(sessionId)
          .set(session.toJson());
          
      // Initialize empty whiteboard in Realtime Database
      final ref = _database.ref().child('whiteboard_data/$sessionId');
      await ref.set({'elements': {}});
      
      _mySessions.insert(0, session);
      notifyListeners();
      
      return session;
    } catch (e) {
      debugPrint('Error creating session: $e');
      rethrow;
    }
  }
  
  Future<void> joinSession(String sessionId) async {
    if (_auth.currentUser == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      final userId = _auth.currentUser!.uid;
      final sessionDoc = await _firestore.collection('sessions').doc(sessionId).get();
      
      if (!sessionDoc.exists) {
        throw Exception('Session does not exist');
      }
      
      final session = WhiteboardSession.fromJson(sessionDoc.data()!);
      
      // Add current user to participants list if not already in
      if (!session.participants.contains(userId)) {
        await _firestore
            .collection('sessions')
            .doc(sessionId)
            .update({
              'participants': FieldValue.arrayUnion([userId])
            });
      }
      
      _currentSession = session;
      await _fetchSessionParticipants();
      
      // Update presence
      final presenceRef = _database
          .ref()
          .child('whiteboard_data/$sessionId/presence/$userId');
          
      await presenceRef.set({
        'id': userId,
        'displayName': _auth.currentUser!.displayName ?? 'User',
        'photoURL': _auth.currentUser!.photoURL,
        'lastActive': ServerValue.timestamp,
        'isOnline': true,
      });
      
      // Set disconnect handler to update online status
      presenceRef.onDisconnect().update({'isOnline': false});
      
      // Listen for participant changes
      _setupParticipantListeners(sessionId);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error joining session: $e');
      rethrow;
    }
  }
  
  Future<void> leaveSession() async {
    if (_currentSession == null || _auth.currentUser == null) return;
    
    try {
      final userId = _auth.currentUser!.uid;
      final sessionId = _currentSession!.id;
      
      // Update presence
      final presenceRef = _database
          .ref()
          .child('whiteboard_data/$sessionId/presence/$userId');
      
      await presenceRef.update({'isOnline': false});
      
      _currentSession = null;
      _currentSessionParticipants = [];
      notifyListeners();
    } catch (e) {
      debugPrint('Error leaving session: $e');
    }
  }
  
  Future<void> deleteSession(String sessionId) async {
    if (_auth.currentUser == null) return;
    
    try {
      // Check if user is the creator
      final sessionDoc = await _firestore.collection('sessions').doc(sessionId).get();
      if (!sessionDoc.exists) return;
      
      final session = WhiteboardSession.fromJson(sessionDoc.data()!);
      if (session.creatorId != _auth.currentUser!.uid) {
        throw Exception('Only the creator can delete a session');
      }
      
      // Delete session from Firestore
      await _firestore.collection('sessions').doc(sessionId).delete();
      
      // Delete whiteboard data from Realtime Database
      await _database.ref().child('whiteboard_data/$sessionId').remove();
      
      _mySessions.removeWhere((s) => s.id == sessionId);
      
      if (_currentSession?.id == sessionId) {
        _currentSession = null;
        _currentSessionParticipants = [];
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting session: $e');
      rethrow;
    }
  }
  
  Future<String> getSessionInviteLink(String sessionId) async {
    // In a real app, you would integrate a dynamic link service
    // Here we'll just return the session ID as a placeholder
    return sessionId;
  }
  
  Future<bool> isSessionValid(String sessionId) async {
    try {
      final doc = await _firestore.collection('sessions').doc(sessionId).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> _fetchSessionParticipants() async {
    if (_currentSession == null) return;
    
    try {
      _currentSessionParticipants = [];
      
      for (final userId in _currentSession!.participants) {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          
          _currentSessionParticipants.add(WhiteboardUser(
            id: userId,
            displayName: userData['displayName'] ?? 'User',
            email: userData['email'] ?? '',
            photoURL: userData['photoURL'],
          ));
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching session participants: $e');
    }
  }
  
  void _setupParticipantListeners(String sessionId) {
    final presenceRef = _database
        .ref()
        .child('whiteboard_data/$sessionId/presence');
        
    // Listen for user presence changes
    presenceRef.onChildAdded.listen((event) {
      _updateParticipantStatus(event);
    });
    
    presenceRef.onChildChanged.listen((event) {
      _updateParticipantStatus(event);
    });
    
    presenceRef.onChildRemoved.listen((event) {
      final userId = event.snapshot.key;
      if (userId != null) {
        _currentSessionParticipants
            .removeWhere((user) => user.id == userId);
        notifyListeners();
      }
    });
  }
  
  void _updateParticipantStatus(DatabaseEvent event) {
    final userId = event.snapshot.key;
    if (userId == null) return;
    
    final data = event.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return;
    
    final isOnline = data['isOnline'] ?? false;
    
    final index = _currentSessionParticipants
        .indexWhere((user) => user.id == userId);
        
    if (index >= 0) {
      // Update existing participant
      final updated = WhiteboardUser(
        id: userId,
        displayName: data['displayName'] ?? 'User',
        email: data['email'] ?? '',
        photoURL: data['photoURL'],
        isOnline: isOnline,
      );
      
      _currentSessionParticipants[index] = updated;
    } else {
      // Add new participant
      _currentSessionParticipants.add(WhiteboardUser(
        id: userId,
        displayName: data['displayName'] ?? 'User',
        email: data['email'] ?? '',
        photoURL: data['photoURL'],
        isOnline: isOnline,
      ));
    }
    
    notifyListeners();
  }
}