class Config {
  // Server URLs
  static const String baseUrl = 'http://localhost:3000';
  static const String apiUrl = '$baseUrl/api';
  static const String socketUrl = baseUrl;
  
  // API endpoints
  static const String usersEndpoint = '$apiUrl/users';
  static const String sessionsEndpoint = '$apiUrl/sessions';
  static const String whiteboardsEndpoint = '$apiUrl/whiteboards';
  
  // Session storage keys
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userDisplayNameKey = 'user_display_name';
  
  // Feature flags
  static const bool enableOfflineMode = true;
  static const bool enableAutoSave = true;
  static const bool enableShareLinks = true;
}