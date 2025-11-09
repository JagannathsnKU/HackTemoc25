/// Widget Service - Manages iOS Home Screen Widget
/// Shows contacts you haven't replied to in a while
/// 
/// DISABLED FOR WEB - home_widget package not supported on web platform
/// This is a stub implementation for web compatibility
class WidgetService {
  /// Initialize widget on app start
  static Future<void> initialize() async {
    // No-op for web - home_widget not supported
  }

  /// Update widget with latest unreplied contacts
  static Future<void> updateWidget() async {
    // No-op for web - home_widget not supported
  }

  /// Get widget data (for testing)
  static Future<Map<String, dynamic>> getWidgetData() async {
    return {};
  }

  /// Clear widget data
  static Future<void> clearWidget() async {
    // No-op for web - home_widget not supported
  }

  /// Handle widget tap - launch to specific conversation
  static void setupInteractivity() {
    // No-op for web - home_widget not supported
  }
}
