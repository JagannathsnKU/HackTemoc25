import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import '../services/audio_service.dart';
import '../services/elevenlabs_service.dart';
import '../services/calendar_service.dart';

class VoiceBookingService {
  static final VoiceBookingService _instance = VoiceBookingService._internal();
  factory VoiceBookingService() => _instance;
  VoiceBookingService._internal();

  final stt.SpeechToText _speech = stt.SpeechToText();
  final ElevenLabsService _elevenLabs = ElevenLabsService();
  bool _isListening = false;
  String _lastWords = '';
  
  static const String baseUrl = 'http://localhost:5000';

  bool get isListening => _isListening;
  String get lastWords => _lastWords;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    if (kIsWeb) {
      // Web doesn't support native speech recognition via this package
      // Will use Web Speech API through JavaScript
      return true;
    }
    
    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      return false;
    }

    // Initialize speech recognition
    return await _speech.initialize(
      onError: (error) => print('Speech error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
  }

  /// Start listening for voice commands
  Future<void> startListening(Function(String) onResult) async {
    if (_isListening) return;

    if (kIsWeb) {
      // Use Web Speech API
      _startWebSpeechRecognition(onResult);
      return;
    }

    if (!_speech.isAvailable) {
      await initialize();
    }

    _isListening = true;
    await _speech.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords;
        if (result.finalResult) {
          onResult(_lastWords);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    _isListening = false;
    if (!kIsWeb) {
      await _speech.stop();
    }
  }

  /// Process voice command for meeting booking
  Future<Map<String, dynamic>> processVoiceBooking({
    required String voiceCommand,
    required String contactName,
    required String chatLog,
    String userName = 'Heet', // Your name
  }) async {
    try {
      print('🎤 Processing voice command: "$voiceCommand"');
      
      // 📅 STEP 1: Fetch free calendar slots FIRST
      print('📅 Fetching your free calendar slots...');
      List<FreeTimeSlot> freeSlots = [];
      try {
        freeSlots = await CalendarService.findFreeTimeSlots(
          durationMinutes: 30,
          daysAhead: 7,
        );
        print('✅ Found ${freeSlots.length} free slots');
      } catch (e) {
        print('⚠️ Could not fetch calendar: $e');
      }
      
      // Convert free slots to readable format for AI
      final freeSlotsText = freeSlots.take(5).map((slot) {
        final day = _formatDay(slot.start);
        final time = _formatTime(slot.start);
        return '$day at $time';
      }).join(', ');
      
      print('📅 Available slots: $freeSlotsText');
      
      // STEP 2: Send to backend with calendar context
      final response = await http.post(
        Uri.parse('$baseUrl/voice_book_meeting'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'voice_command': voiceCommand,
          'contact_name': contactName,
          'chat_log': chatLog,
          'user_name': userName,
          'free_calendar_slots': freeSlotsText, // ✨ NEW: Include free slots!
          'has_calendar_data': freeSlots.isNotEmpty,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Backend request timed out. Is the server running?');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        print('✅ AI Analysis received: ${data['meeting_data']?['meeting_type'] ?? 'N/A'}');
        
        // Generate voice response using ElevenLabs
        final meetingType = data['meeting_data']?['meeting_type'] ?? 'meeting';
        final suggestedTime = data['meeting_data']?['suggested_time'] ?? 'tomorrow';
        
        // ✨ Smart voice response based on calendar availability
        String voiceScript;
        if (freeSlots.isNotEmpty) {
          voiceScript = 'Hi $userName! I heard you want to book a $meetingType with $contactName. '
              'Based on your calendar, you\'re free $suggestedTime. I\'ve scheduled it for then. '
              'Would you like to add this to your calendar?';
        } else {
          voiceScript = 'Hi $userName! I heard you want to book a $meetingType with $contactName. '
              'I\'ve scheduled it for $suggestedTime. Would you like to add this to your calendar?';
        }
        
        print('🔊 Generating voice with ElevenLabs...');
        await _elevenLabs.speak(voiceScript);
        
        return {
          ...data,
          'success': true,
          'voice_played': true,
          'calendar_slots_used': freeSlots.isNotEmpty,
        };
      } else {
        print('❌ Backend error: ${response.statusCode}');
        throw Exception('Backend returned ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Backend unavailable: $e');
      print('✅ Using offline mode with calendar integration...');
      
      // 📅 Fetch calendar slots for offline mode too
      List<FreeTimeSlot> freeSlots = [];
      try {
        freeSlots = await CalendarService.findFreeTimeSlots(
          durationMinutes: 30,
          daysAhead: 7,
        );
      } catch (e) {
        print('⚠️ Could not fetch calendar in offline mode: $e');
      }
      
      // Parse the voice command locally with calendar context
      final parsedData = _parseVoiceCommandLocally(
        voiceCommand, 
        contactName,
        freeSlots: freeSlots,
      );
      
      // Generate smart voice response with calendar awareness
      final meetingType = parsedData['meeting_type'];
      final suggestedTime = parsedData['suggested_time'];
      
      String fallbackScript;
      if (freeSlots.isNotEmpty) {
        fallbackScript = 'Hi $userName! I heard you want to book a $meetingType with $contactName. '
            'Checking your calendar... you\'re free $suggestedTime. Perfect! '
            'Would you like to add this to your calendar?';
      } else {
        fallbackScript = 'Hi $userName! I heard you want to book a $meetingType with $contactName. '
            'I\'ve scheduled it for $suggestedTime. Would you like to add this to your calendar?';
      }
      
      print('🔊 Generating fallback voice response...');
      await _elevenLabs.speak(fallbackScript);
      
      return {
        'success': true,
        'offline_mode': true,
        'meeting_data': parsedData,
        'voice_script': fallbackScript,
        'fallback': true,
        'calendar_integrated': freeSlots.isNotEmpty,
      };
    }
  }

  /// 🤖 Smart local parser for voice commands (works offline!)
  /// ONLY uses the current voice command - NO past memory!
  Map<String, dynamic> _parseVoiceCommandLocally(
    String command, 
    String contactName, {
    List<FreeTimeSlot>? freeSlots,
  }) {
    final lowerCommand = command.toLowerCase();
    
    print('🤖 Parsing CURRENT command only: "$command"');
    print('📞 Booking with: $contactName');
    if (freeSlots != null && freeSlots.isNotEmpty) {
      print('📅 Using ${freeSlots.length} calendar slots');
    }
    
    // Detect meeting type from CURRENT command
    String meetingType = 'Meeting';
    if (lowerCommand.contains('coffee')) {
      meetingType = 'Coffee Meeting';
    } else if (lowerCommand.contains('lunch')) {
      meetingType = 'Lunch Meeting';
    } else if (lowerCommand.contains('dinner')) {
      meetingType = 'Dinner Meeting';
    } else if (lowerCommand.contains('call')) {
      meetingType = 'Phone Call';
    } else if (lowerCommand.contains('video')) {
      meetingType = 'Video Call';
    } else if (lowerCommand.contains('sync')) {
      meetingType = 'Sync Meeting';
    } else if (lowerCommand.contains('review')) {
      meetingType = 'Review Meeting';
    } else if (lowerCommand.contains('appointment')) {
      meetingType = 'Appointment';
    }
    
    // Detect time from CURRENT command ONLY
    String suggestedTime = 'Tomorrow at 2:00 PM';
    Duration durationValue = const Duration(minutes: 30);
    
    // Parse specific times mentioned NOW
    if (lowerCommand.contains('10')) {
      if (lowerCommand.contains('am')) {
        suggestedTime = lowerCommand.contains('tomorrow') ? 'Tomorrow at 10:00 AM' : 'Today at 10:00 AM';
      } else if (lowerCommand.contains('pm')) {
        suggestedTime = lowerCommand.contains('tomorrow') ? 'Tomorrow at 10:00 PM' : 'Today at 10:00 PM';
      } else {
        suggestedTime = lowerCommand.contains('tomorrow') ? 'Tomorrow at 10:00 AM' : 'Today at 10:00 AM';
      }
    } else if (lowerCommand.contains('2:00') || lowerCommand.contains('2 pm') || lowerCommand.contains('2pm')) {
      suggestedTime = lowerCommand.contains('tomorrow') ? 'Tomorrow at 2:00 PM' : 'Today at 2:00 PM';
    } else if (lowerCommand.contains('3:00') || lowerCommand.contains('3 pm') || lowerCommand.contains('3pm')) {
      suggestedTime = lowerCommand.contains('tomorrow') ? 'Tomorrow at 3:00 PM' : 'Today at 3:00 PM';
    } else if (lowerCommand.contains('4:00') || lowerCommand.contains('4 pm') || lowerCommand.contains('4pm')) {
      suggestedTime = lowerCommand.contains('tomorrow') ? 'Tomorrow at 4:00 PM' : 'Today at 4:00 PM';
    } else if (lowerCommand.contains('5:00') || lowerCommand.contains('5 pm') || lowerCommand.contains('5pm')) {
      suggestedTime = lowerCommand.contains('tomorrow') ? 'Tomorrow at 5:00 PM' : 'Today at 5:00 PM';
    }
    
    // Check for day references
    else if (lowerCommand.contains('tomorrow')) {
      if (lowerCommand.contains('morning')) {
        suggestedTime = 'Tomorrow at 10:00 AM';
      } else if (lowerCommand.contains('afternoon')) {
        suggestedTime = 'Tomorrow at 2:00 PM';
      } else if (lowerCommand.contains('evening')) {
        suggestedTime = 'Tomorrow at 5:00 PM';
      } else {
        suggestedTime = 'Tomorrow at 2:00 PM';
      }
    } else if (lowerCommand.contains('today')) {
      if (lowerCommand.contains('morning')) {
        suggestedTime = 'Today at 10:00 AM';
      } else if (lowerCommand.contains('afternoon')) {
        suggestedTime = 'Today at 2:00 PM';
      } else if (lowerCommand.contains('evening')) {
        suggestedTime = 'Today at 5:00 PM';
      } else {
        suggestedTime = 'Today at 3:00 PM';
      }
    } else if (lowerCommand.contains('monday')) {
      suggestedTime = 'Monday at 2:00 PM';
    } else if (lowerCommand.contains('tuesday')) {
      suggestedTime = 'Tuesday at 2:00 PM';
    } else if (lowerCommand.contains('wednesday')) {
      suggestedTime = 'Wednesday at 2:00 PM';
    } else if (lowerCommand.contains('thursday')) {
      suggestedTime = 'Thursday at 2:00 PM';
    } else if (lowerCommand.contains('friday')) {
      suggestedTime = 'Friday at 2:00 PM';
    } else if (lowerCommand.contains('next week')) {
      suggestedTime = 'Next week at 2:00 PM';
    }
    
    // Detect duration from CURRENT command
    String duration = '30 minutes';
    if (lowerCommand.contains('hour') || lowerCommand.contains('1 hour')) {
      duration = '1 hour';
      durationValue = const Duration(hours: 1);
    } else if (lowerCommand.contains('15 min')) {
      duration = '15 minutes';
      durationValue = const Duration(minutes: 15);
    } else if (lowerCommand.contains('quick')) {
      duration = '15 minutes';
      durationValue = const Duration(minutes: 15);
    } else if (lowerCommand.contains('45 min')) {
      duration = '45 minutes';
      durationValue = const Duration(minutes: 45);
    }
    
    // Detect location from CURRENT command
    String location = 'Virtual';
    if (lowerCommand.contains('office')) {
      location = 'Office';
    } else if (lowerCommand.contains('starbucks') || lowerCommand.contains('cafe')) {
      location = 'Cafe';
    } else if (lowerCommand.contains('zoom') || lowerCommand.contains('video')) {
      location = 'Zoom';
    } else if (lowerCommand.contains('teams')) {
      location = 'Microsoft Teams';
    } else if (lowerCommand.contains('meet')) {
      location = 'Google Meet';
    }
    
    print('🤖 Parsed from CURRENT command:');
    print('   Type: $meetingType');
    print('   Time: $suggestedTime');
    print('   Duration: $duration');
    print('   Location: $location');
    print('   With: $contactName');
    
    // 📅 CALENDAR INTEGRATION: Use actual free slots if available
    if (freeSlots != null && freeSlots.isNotEmpty) {
      // Find the best matching slot based on the parsed time preference
      final bestSlot = _findBestSlot(freeSlots, suggestedTime, lowerCommand);
      if (bestSlot != null) {
        suggestedTime = '${_formatDay(bestSlot.start)} at ${_formatTime(bestSlot.start)}';
        print('📅 Updated to calendar slot: $suggestedTime');
      }
    }
    
    return {
      'meeting_type': meetingType,
      'suggested_time': suggestedTime,
      'duration': duration,
      'duration_minutes': durationValue.inMinutes,
      'location': location,
      'contact_name': contactName,
      'notes': command, // Store the CURRENT command only
      'parsed_locally': true,
      'calendar_aware': freeSlots != null && freeSlots.isNotEmpty,
    };
  }
  
  /// Find the best matching free slot based on user preference
  FreeTimeSlot? _findBestSlot(List<FreeTimeSlot> slots, String preferredTime, String command) {
    if (slots.isEmpty) return null;
    
    // If user specified "tomorrow", prefer tomorrow slots
    if (command.contains('tomorrow')) {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowSlots = slots.where((slot) => 
        slot.start.day == tomorrow.day && 
        slot.start.month == tomorrow.month
      ).toList();
      if (tomorrowSlots.isNotEmpty) return tomorrowSlots.first;
    }
    
    // If user specified "today", prefer today slots
    if (command.contains('today')) {
      final today = DateTime.now();
      final todaySlots = slots.where((slot) => 
        slot.start.day == today.day && 
        slot.start.month == today.month &&
        slot.start.isAfter(DateTime.now())
      ).toList();
      if (todaySlots.isNotEmpty) return todaySlots.first;
    }
    
    // If user specified a time preference (morning/afternoon/evening)
    if (command.contains('morning')) {
      final morningSlots = slots.where((slot) => 
        slot.start.hour >= 8 && slot.start.hour < 12
      ).toList();
      if (morningSlots.isNotEmpty) return morningSlots.first;
    } else if (command.contains('afternoon')) {
      final afternoonSlots = slots.where((slot) => 
        slot.start.hour >= 12 && slot.start.hour < 17
      ).toList();
      if (afternoonSlots.isNotEmpty) return afternoonSlots.first;
    } else if (command.contains('evening')) {
      final eveningSlots = slots.where((slot) => 
        slot.start.hour >= 17
      ).toList();
      if (eveningSlots.isNotEmpty) return eveningSlots.first;
    }
    
    // Default: return first available slot
    return slots.first;
  }
  
  /// Format date as human-readable day
  String _formatDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate == today) {
      return 'Today';
    } else if (targetDate == tomorrow) {
      return 'Tomorrow';
    } else {
      // Return day of week
      const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      return days[date.weekday - 1];
    }
  }
  
  /// Format time as human-readable
  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour == 0 ? 12 : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  /// Book meeting to Google Calendar
  Future<Map<String, dynamic>> bookToGoogleCalendar({
    required String contactName,
    required String contactEmail,
    required DateTime startTime,
    required DateTime endTime,
    required String description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/book_google_calendar'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact_name': contactName,
          'contact_email': contactEmail,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'description': description,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Google Calendar booking error: $e');
    }

    return {
      'success': false,
      'error': 'Failed to book to Google Calendar',
    };
  }

  /// Web Speech Recognition (for Chrome)
  void _startWebSpeechRecognition(Function(String) onResult) {
    _isListening = true;
    
    // Inject and execute JavaScript directly
    html.window.console.log('🎤 Starting Web Speech Recognition via JS...');
    
    // Create recognition using JavaScript eval
    js.context.callMethod('eval', ['''
      (function() {
        const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
        if (!SpeechRecognition) {
          console.error('❌ Browser does not support Web Speech API');
          return null;
        }
        
        const recognition = new SpeechRecognition();
        recognition.continuous = false;
        recognition.interimResults = true;
        recognition.lang = 'en-US';
        recognition.maxAlternatives = 1;
        
        recognition.onresult = function(event) {
          try {
            const results = event.results;
            const lastIndex = results.length - 1;
            const result = results[lastIndex];
            const transcript = result[0].transcript;
            const isFinal = result.isFinal;
            
            console.log('🎤 Transcript: ' + transcript + ' (final: ' + isFinal + ')');
            
            // Send to Dart
            window.lastTranscript = transcript;
            window.lastIsFinal = isFinal;
            
            if (isFinal) {
              window.finalTranscript = transcript;
            }
          } catch (e) {
            console.error('❌ Result processing error:', e);
          }
        };
        
        recognition.onerror = function(event) {
          console.error('❌ Speech recognition error:', event.error);
          window.recognitionError = event.error;
        };
        
        recognition.onend = function() {
          console.log('🎤 Speech recognition ended');
          window.recognitionEnded = true;
        };
        
        recognition.start();
        console.log('🎤 Recognition started!');
        window.activeRecognition = recognition;
        return recognition;
      })();
    ''']);
    
    // Poll for results
    _pollForTranscript(onResult);
  }
  
  void _pollForTranscript(Function(String) onResult) {
    // Check every 500ms for new transcript
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isListening) return;
      
      try {
        // Check for errors
        final error = js.context['recognitionError'];
        if (error != null) {
          js.context['recognitionError'] = null;
          final errorStr = error.toString();
          print('❌ Recognition error: $errorStr');
          _isListening = false;
          
          if (errorStr.contains('not-allowed') || errorStr.contains('permission-denied')) {
            onResult('Error: Microphone permission denied. Please allow microphone access.');
          } else {
            onResult('Error: Speech recognition failed. Please try again.');
          }
          return;
        }
        
        // Check if ended
        final ended = js.context['recognitionEnded'];
        if (ended == true) {
          js.context['recognitionEnded'] = null;
          final finalTranscript = js.context['finalTranscript'];
          
          if (finalTranscript != null && finalTranscript.toString().isNotEmpty) {
            _lastWords = finalTranscript.toString();
            print('✅ Final transcript: $_lastWords');
            _isListening = false;
            js.context['finalTranscript'] = null;
            onResult(_lastWords);
            return;
          }
          
          _isListening = false;
          return;
        }
        
        // Check for interim results
        final transcript = js.context['lastTranscript'];
        if (transcript != null && transcript.toString().isNotEmpty) {
          _lastWords = transcript.toString();
          print('🎤 Interim: $_lastWords');
        }
        
        // Continue polling
        _pollForTranscript(onResult);
        
      } catch (e) {
        print('❌ Polling error: $e');
        _isListening = false;
      }
    });
  }

  void dispose() {
    _speech.cancel();
  }
}
