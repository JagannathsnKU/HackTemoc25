/// Widget Service - Web Stub
/// home_widget is not supported on web, so this is a no-op implementation
class WidgetService {
  static Future<void> initialize() async {
    // No-op for web
  }

  static Future<void> updateWidget() async {
    // No-op for web
  }

  static Future<List<Map<String, String>>> getUnrepliedContacts() async {
    return [];
  }

  static Future<void> clearWidget() async {
    // No-op for web
  }

  static void setupWidgetClickHandling(Function(String contactId) onContactTap) {
    // No-op for web
  }
}
