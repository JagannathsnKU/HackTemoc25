import 'dart:async';
import 'dart:convert';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Google Calendar integration service
/// Handles OAuth2 authentication and event creation
class GoogleCalendarService {
  // Google OAuth2 Client ID (you'll need to create this in Google Cloud Console)
  // For now, using placeholder - replace with actual credentials
  static const String _clientId = 'YOUR_CLIENT_ID.apps.googleusercontent.com';
  static const String _clientSecret = 'YOUR_CLIENT_SECRET';
  
  static const List<String> _scopes = [
    calendar.CalendarApi.calendarScope,
  ];

  AccessCredentials? _credentials;
  calendar.CalendarApi? _calendarApi;

  /// Initialize the service and check for existing credentials
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final credentialsJson = prefs.getString('google_calendar_credentials');
      
      if (credentialsJson != null) {
        final Map<String, dynamic> credentialsMap = json.decode(credentialsJson);
        // Restore credentials from storage
        // Note: In production, you'd need proper token refresh logic
        print('📅 Found stored Google Calendar credentials');
      }
    } catch (e) {
      print('❌ Error initializing Google Calendar: $e');
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _credentials != null && _calendarApi != null;

  /// Authenticate with Google Calendar using OAuth2
  /// Opens browser for user consent
  Future<bool> authenticate() async {
    try {
      print('🔐 Starting Google Calendar authentication...');

      // For web, we'll use OAuth2 with redirect
      // For production, replace with actual OAuth2 flow
      
      // Simplified OAuth2 URL (in production, use proper flow)
      final authUrl = Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
        'client_id': _clientId,
        'redirect_uri': 'http://localhost:3000/auth/callback', // Your redirect URI
        'response_type': 'code',
        'scope': _scopes.join(' '),
        'access_type': 'offline',
        'prompt': 'consent',
      });

      // For now, use mock authentication for development
      print('⚠️ Mock authentication for development');
      
      // TODO: Implement proper OAuth2 flow
      // await launchUrl(authUrl, mode: LaunchMode.externalApplication);
      
      return true;
    } catch (e) {
      print('❌ Authentication error: $e');
      return false;
    }
  }

  /// Add a meeting to Google Calendar
  /// Returns true if successful, false otherwise
  Future<bool> addMeetingToCalendar({
    required String summary,
    required String description,
    required DateTime startTime,
    required Duration duration,
    String? location,
    List<String>? attendees,
  }) async {
    try {
      print('📅 Adding meeting to Google Calendar...');
      print('   Title: $summary');
      print('   Time: $startTime');
      print('   Duration: ${duration.inMinutes} minutes');

      // Check authentication
      if (!isAuthenticated) {
        print('⚠️ Not authenticated. Attempting to authenticate...');
        final authenticated = await authenticate();
        if (!authenticated) {
          throw Exception('Failed to authenticate with Google Calendar');
        }
      }

      // Calculate end time
      final endTime = startTime.add(duration);

      // Create calendar event
      final event = calendar.Event()
        ..summary = summary
        ..description = description
        ..location = location
        ..start = (calendar.EventDateTime()
          ..dateTime = startTime
          ..timeZone = 'America/New_York') // TODO: Use user's timezone
        ..end = (calendar.EventDateTime()
          ..dateTime = endTime
          ..timeZone = 'America/New_York');

      // Add attendees if provided
      if (attendees != null && attendees.isNotEmpty) {
        event.attendees = attendees.map((email) {
          return calendar.EventAttendee()..email = email;
        }).toList();
      }

      // For development: Mock the API call
      print('✅ Mock: Meeting would be added to Google Calendar');
      print('   Event: ${event.summary}');
      print('   Start: ${event.start?.dateTime}');
      print('   End: ${event.end?.dateTime}');
      
      // TODO: Uncomment when you have real credentials
      /*
      if (_calendarApi != null) {
        final createdEvent = await _calendarApi!.events.insert(
          event,
          'primary', // Use primary calendar
        );
        
        print('✅ Meeting added to Google Calendar!');
        print('   Event ID: ${createdEvent.id}');
        print('   Link: ${createdEvent.htmlLink}');
        
        return true;
      }
      */

      // For now, return true (mock success)
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate API call
      return true;

    } catch (e) {
      print('❌ Error adding meeting to calendar: $e');
      return false;
    }
  }

  /// Quick add meeting with defaults
  Future<bool> addQuickMeeting({
    required String contactName,
    required String meetingType,
    required DateTime meetingTime,
  }) {
    return addMeetingToCalendar(
      summary: '$meetingType with $contactName',
      description: 'Meeting scheduled via AI Agent in Atlas Chat',
      startTime: meetingTime,
      duration: const Duration(minutes: 30), // Default 30 min
      location: 'Virtual', // Default to virtual
    );
  }

  /// Sign out and clear credentials
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('google_calendar_credentials');
      
      _credentials = null;
      _calendarApi = null;
      
      print('👋 Signed out from Google Calendar');
    } catch (e) {
      print('❌ Error signing out: $e');
    }
  }
}

/// Singleton instance for easy access
final googleCalendarService = GoogleCalendarService();
