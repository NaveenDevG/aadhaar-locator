class AppConfig {
  // Development mode settings
  static const bool isDevelopment = true;
  
  // Firebase settings
  static const bool enableRecaptcha = false; // Disable for development
  static const bool enableStrictMode = false; // Disable strict validation for development
  
  // API endpoints
  static const String firebaseProjectId = 'aadhaar-locator-app';
  
  // Feature flags
  static const bool enableLocationSharing = true;
  static const bool enablePushNotifications = true;
  static const bool enableAadhaarValidation = true;
  
  // Debug settings
  static const bool showDebugInfo = true;
  static const bool enableLogging = true;
  
  // Timeout settings
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration authTimeout = Duration(seconds: 60);
  
  // Device-specific settings for RMX and similar devices
  static const bool enableRetryLogic = true;
  static const int maxRetryAttempts = 3;
  static const int retryDelaySeconds = 2;
  
  // Google Play Services fallback
  static const bool enablePlayServicesFallback = true;
}
