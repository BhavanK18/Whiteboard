import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config.dart';
import '../../models/drawing.dart';

class SocketService {
  static final SocketService instance = SocketService._internal();
  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentSessionId;
  
  // Callbacks
  final ValueNotifier<int> participantCount = ValueNotifier<int>(1);
  final ValueNotifier<List<String>> messages = ValueNotifier<List<String>>([]);

  // Stream controllers for drawing events
  final drawElementCallbacks = <void Function(DrawElement element, String pageId)>[];
  final updateElementCallbacks = <void Function(DrawElement element, String pageId)>[];
  final deleteElementCallbacks = <void Function(String elementId, String pageId)>[];
  final clearBoardCallbacks = <void Function(String pageId)>[];
  final userJoinedCallbacks = <Function(Map<String, dynamic>)>[];
  final userLeftCallbacks = <Function(Map<String, dynamic>)>[];
  final sessionInfoCallbacks = <Function(Map<String, dynamic>)>[];
  final joinSuccessCallbacks = <Function(Map<String, dynamic>)>[];
  final joinErrorCallbacks = <Function(String)>[];
  
  // Constructor
  factory SocketService() => instance;
  
  SocketService._internal();
  
  bool get isConnected => _isConnected;
  String? get currentSessionId => _currentSessionId;
  
  // Generic method to emit any event
  void emit(String event, Map<String, dynamic> data) {
    if (_socket != null && _isConnected) {
      _socket!.emit(event, data);
    } else {
      debugPrint('Socket not connected, cannot emit $event');
    }
  }
  
  // Initialize socket connection
  void initSocket() {
    try {
      debugPrint('Initializing socket connection to ${Config.socketUrl}');
      
      _socket = IO.io(Config.socketUrl, <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });
      
      _setupSocketListeners();
      
      _socket!.connect();
      
    } catch (e) {
      debugPrint('Error initializing socket: $e');
    }
  }
  
  // Setup socket event listeners
  void _setupSocketListeners() {
    _socket!.onConnect((_) {
      debugPrint('Socket connected');
      _isConnected = true;
    });
    
    _socket!.onDisconnect((_) {
      debugPrint('Socket disconnected');
      _isConnected = false;
      _currentSessionId = null;
      participantCount.value = 1;
    });
    
    _socket!.onError((error) {
      debugPrint('Socket error: $error');
    });
    
    _socket!.onConnectError((error) {
      debugPrint('Socket connect error: $error');
    });
    
    // Handle drawing element received
    _socket!.on('draw_element', (payload) {
      try {
        final data = Map<String, dynamic>.from(payload as Map);
        final pageId = data['pageId'] as String? ?? 'default';
        final element = DrawElement.fromJson(
          Map<String, dynamic>.from(data['element'] as Map),
        );
        for (var callback in drawElementCallbacks) {
          callback(element, pageId);
        }
      } catch (e) {
        debugPrint('Error handling draw_element event: $e');
      }
    });
    
    // Handle element update
    _socket!.on('update_element', (payload) {
      try {
        final data = Map<String, dynamic>.from(payload as Map);
        final pageId = data['pageId'] as String? ?? 'default';
        final element = DrawElement.fromJson(
          Map<String, dynamic>.from(data['element'] as Map),
        );
        for (var callback in updateElementCallbacks) {
          callback(element, pageId);
        }
      } catch (e) {
        debugPrint('Error handling update_element event: $e');
      }
    });
    
    // Handle element deletion
    _socket!.on('delete_element', (payload) {
      try {
        final data = Map<String, dynamic>.from(payload as Map);
        final elementId = data['elementId'] as String?;
        final pageId = data['pageId'] as String? ?? 'default';
        if (elementId == null) return;
        for (var callback in deleteElementCallbacks) {
          callback(elementId, pageId);
        }
      } catch (e) {
        debugPrint('Error handling delete_element event: $e');
      }
    });
    
    // Handle clear board
    _socket!.on('clear_board', (payload) {
      try {
        final data = payload == null
            ? <String, dynamic>{'pageId': 'default'}
            : Map<String, dynamic>.from(payload as Map);
        final pageId = data['pageId'] as String? ?? 'default';
        for (var callback in clearBoardCallbacks) {
          callback(pageId);
        }
      } catch (e) {
        debugPrint('Error handling clear_board event: $e');
      }
    });
    
    // Handle user joined
    _socket!.on('user_joined', (data) {
      try {
        participantCount.value = data['count'] ?? 1;
        for (var callback in userJoinedCallbacks) {
          callback(data);
        }
      } catch (e) {
        debugPrint('Error handling user_joined event: $e');
      }
    });
    
    // Handle user left
    _socket!.on('user_left', (data) {
      try {
        participantCount.value = data['count'] ?? 1;
        for (var callback in userLeftCallbacks) {
          callback(data);
        }
      } catch (e) {
        debugPrint('Error handling user_left event: $e');
      }
    });
    
    // Handle join success
    _socket!.on('join_success', (data) {
      try {
        participantCount.value = data['participants']?.length ?? 1;
        for (var callback in joinSuccessCallbacks) {
          callback(data);
        }
      } catch (e) {
        debugPrint('Error handling join_success event: $e');
      }
    });
    
    // Handle join error
    _socket!.on('join_error', (data) {
      try {
        final error = data['error'] ?? 'Failed to join session';
        for (var callback in joinErrorCallbacks) {
          callback(error);
        }
      } catch (e) {
        debugPrint('Error handling join_error event: $e');
      }
    });
    
    // Handle chat messages
    _socket!.on('chat_message', (data) {
      try {
        final message = data['message'] ?? data.toString();
        final currentMessages = messages.value;
        messages.value = [...currentMessages, message];
      } catch (e) {
        debugPrint('Error handling chat_message event: $e');
      }
    });
  }
  
  // Join a session - accepts both guests and logged-in users
  void joinSession(String sessionId, {String? userName}) {
    if (_isConnected && _socket != null) {
      _socket!.emit('join_session', {
        'sessionId': sessionId,
        'userName': userName ?? 'Anonymous'
      });
      _currentSessionId = sessionId;
      debugPrint('Joining session: $sessionId as ${userName ?? "Anonymous"}');
    } else {
      debugPrint('Cannot join session, socket not connected');
    }
  }
  
  // Leave the current session
  void leaveSession() {
    if (_currentSessionId != null && _socket != null) {
      _socket!.emit('leave-session', _currentSessionId);
      _currentSessionId = null;
      participantCount.value = 1;
      debugPrint('Left session');
    }
  }
  
  // Send a drawing element
  void sendDrawElement(DrawElement element, String pageId) {
    if (_currentSessionId != null && _socket != null) {
      final data = {
        'sessionId': _currentSessionId,
        'pageId': pageId,
        'element': element.toJson(),
      };
      _socket!.emit('draw_element', data);
    }
  }
  
  // Update an element
  void sendUpdateElement(DrawElement element, String pageId) {
    if (_currentSessionId != null && _socket != null) {
      final data = {
        'sessionId': _currentSessionId,
        'pageId': pageId,
        'element': element.toJson(),
      };
      _socket!.emit('update_element', data);
    }
  }
  
  // Delete an element
  void sendDeleteElement(String elementId, String pageId) {
    if (_currentSessionId != null && _socket != null) {
      final data = {
        'sessionId': _currentSessionId,
        'pageId': pageId,
        'elementId': elementId,
      };
      _socket!.emit('delete_element', data);
    }
  }
  
  // Clear the board
  void sendClearBoard(String pageId) {
    if (_currentSessionId != null && _socket != null) {
      _socket!.emit('clear_board', {
        'sessionId': _currentSessionId,
        'pageId': pageId,
      });
    }
  }
  
  // Send a chat message
  void sendChatMessage(String message) {
    if (_currentSessionId != null && _socket != null) {
      final data = {
        'sessionId': _currentSessionId,
        'message': message,
      };
      _socket!.emit('chat-message', data);
    }
  }
  
  // Register callbacks
  void onDrawElement(void Function(DrawElement element, String pageId) callback) {
    drawElementCallbacks.add(callback);
  }
  
  void onUpdateElement(void Function(DrawElement element, String pageId) callback) {
    updateElementCallbacks.add(callback);
  }
  
  void onDeleteElement(void Function(String elementId, String pageId) callback) {
    deleteElementCallbacks.add(callback);
  }
  
  void onClearBoard(void Function(String pageId) callback) {
    clearBoardCallbacks.add(callback);
  }
  
  void onUserJoined(Function(Map<String, dynamic>) callback) {
    userJoinedCallbacks.add(callback);
  }
  
  void onUserLeft(Function(Map<String, dynamic>) callback) {
    userLeftCallbacks.add(callback);
  }
  
  void onSessionInfo(Function(Map<String, dynamic>) callback) {
    sessionInfoCallbacks.add(callback);
  }
  
  // Disconnect socket
  void disconnect() {
    if (_socket != null) {
      if (_currentSessionId != null) {
        leaveSession();
      }
      _socket!.disconnect();
      _isConnected = false;
    }
  }
  
  // Dispose resources
  void dispose() {
    disconnect();
    participantCount.dispose();
    messages.dispose();
    drawElementCallbacks.clear();
    updateElementCallbacks.clear();
    deleteElementCallbacks.clear();
    clearBoardCallbacks.clear();
    userJoinedCallbacks.clear();
    userLeftCallbacks.clear();
    sessionInfoCallbacks.clear();
  }
}