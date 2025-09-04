class BackendConfig {
  // Railway backend URL - replace with your actual Railway URL after deployment
  static const String baseUrl = 'https://aadhaar-locator-production.up.railway.app';
  
  // Local development URL (for testing)
  static const String localUrl = 'http://localhost:3000';
  
  // Use local URL in debug mode, Railway URL in release mode
  static String get backendUrl {
    // You can also use environment variables or build configurations here
    return const bool.fromEnvironment('USE_LOCAL_BACKEND', defaultValue: false) 
        ? localUrl 
        : baseUrl;
  }
  
  // API endpoints
  static String get sendPushEndpoint => '$backendUrl/sendPush';
  static String get sendPushToMultipleEndpoint => '$backendUrl/sendPushToMultiple';
  static String get healthCheckEndpoint => '$backendUrl/';
  static String get testEndpoint => '$backendUrl/test';
}
