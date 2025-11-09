import 'dart:async';

/// Calendar Service - provides calendar integration and free time slot detection
/// This is a mock implementation that can be replaced with real Google Calendar API
class CalendarService {
  // Mock calendar events for demonstration
  static List<CalendarEvent> _mockEvents = [
    CalendarEvent(
      title: 'Team Standup',
      start: DateTime.now().add(const Duration(hours: 1)),
      end: DateTime.now().add(const Duration(hours: 1, minutes: 30)),
    ),
    CalendarEvent(
      title: 'Client Presentation',
      start: DateTime.now().add(const Duration(hours: 3)),
      end: DateTime.now().add(const Duration(hours: 4)),
    ),
    CalendarEvent(
      title: 'Lunch Break',
      start: DateTime.now().add(const Duration(hours: 5)),
      end: DateTime.now().add(const Duration(hours: 6)),
    ),
  ];

  // Get upcoming events
  static Future<List<CalendarEvent>> getUpcomingEvents({
    int daysAhead = 7,
  }) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    final now = DateTime.now();
    final endDate = now.add(Duration(days: daysAhead));
    
    return _mockEvents.where((event) {
      return event.start.isAfter(now) && event.start.isBefore(endDate);
    }).toList();
  }

  // Find free time slots for a meeting
  static Future<List<FreeTimeSlot>> findFreeTimeSlots({
    required int durationMinutes,
    int daysAhead = 7,
    int startHour = 9,  // 9 AM
    int endHour = 17,   // 5 PM
  }) async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));
    
    final freeSlots = <FreeTimeSlot>[];
    final now = DateTime.now();
    final events = await getUpcomingEvents(daysAhead: daysAhead);

    // Check each day
    for (int day = 0; day < daysAhead; day++) {
      final currentDay = now.add(Duration(days: day));
      
      // Skip weekends
      if (currentDay.weekday == DateTime.saturday || 
          currentDay.weekday == DateTime.sunday) {
        continue;
      }

      // Create time slots for the day (every 30 minutes)
      for (int hour = startHour; hour < endHour; hour++) {
        for (int minute = 0; minute < 60; minute += 30) {
          final slotStart = DateTime(
            currentDay.year,
            currentDay.month,
            currentDay.day,
            hour,
            minute,
          );
          final slotEnd = slotStart.add(Duration(minutes: durationMinutes));

          // Skip if slot is in the past
          if (slotStart.isBefore(now)) continue;

          // Check if this slot conflicts with any event
          bool hasConflict = false;
          for (var event in events) {
            // Check for overlap
            if (slotStart.isBefore(event.end) && slotEnd.isAfter(event.start)) {
              hasConflict = true;
              break;
            }
          }

          if (!hasConflict) {
            freeSlots.add(FreeTimeSlot(
              start: slotStart,
              end: slotEnd,
              dayOfWeek: _getDayName(slotStart.weekday),
            ));
          }
        }
      }
    }

    // Return top 10 slots
    return freeSlots.take(10).toList();
  }

  // Get busy times for a specific date range
  static Future<List<BusyPeriod>> getBusyTimes({
    required DateTime start,
    required DateTime end,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final events = await getUpcomingEvents(daysAhead: 30);
    final busyPeriods = <BusyPeriod>[];
    
    for (var event in events) {
      if (event.start.isAfter(start) && event.start.isBefore(end)) {
        busyPeriods.add(BusyPeriod(
          start: event.start,
          end: event.end,
          summary: event.title,
        ));
      }
    }

    return busyPeriods;
  }

  // Helper method to get day name
  static String _getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday: return 'Monday';
      case DateTime.tuesday: return 'Tuesday';
      case DateTime.wednesday: return 'Wednesday';
      case DateTime.thursday: return 'Thursday';
      case DateTime.friday: return 'Friday';
      case DateTime.saturday: return 'Saturday';
      case DateTime.sunday: return 'Sunday';
      default: return '';
    }
  }

  // Format free slot for display
  static String formatFreeSlot(FreeTimeSlot slot) {
    final startTime = _formatTime(slot.start);
    final endTime = _formatTime(slot.end);
    final date = _formatDate(slot.start);
    
    return '$date at $startTime - $endTime';
  }

  static String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'Tomorrow';
    } else {
      final weekday = _getDayName(date.weekday);
      return '$weekday ${date.month}/${date.day}';
    }
  }
}

// Calendar event model
class CalendarEvent {
  final String title;
  final DateTime start;
  final DateTime end;

  CalendarEvent({
    required this.title,
    required this.start,
    required this.end,
  });
}

// Free time slot model
class FreeTimeSlot {
  final DateTime start;
  final DateTime end;
  final String dayOfWeek;

  FreeTimeSlot({
    required this.start,
    required this.end,
    required this.dayOfWeek,
  });
}

// Busy period model
class BusyPeriod {
  final DateTime start;
  final DateTime end;
  final String summary;

  BusyPeriod({
    required this.start,
    required this.end,
    required this.summary,
  });
}
