import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

/// Beautiful animated widget that shows when AI agent books a meeting
/// Features: Pulsing check animation, calendar integration, smooth transitions,
/// confetti effects, and modern glassmorphism design
class MeetingBookingAnimation extends StatefulWidget {
  final String contactName;
  final String meetingType;
  final DateTime meetingTime;
  final VoidCallback onComplete;
  final VoidCallback? onAddToCalendar;

  const MeetingBookingAnimation({
    Key? key,
    required this.contactName,
    required this.meetingType,
    required this.meetingTime,
    required this.onComplete,
    this.onAddToCalendar,
  }) : super(key: key);

  @override
  State<MeetingBookingAnimation> createState() => _MeetingBookingAnimationState();
}

class _MeetingBookingAnimationState extends State<MeetingBookingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _calendarController;

  late Animation<double> _checkAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _calendarScaleAnimation;

  bool _showCalendarButton = false;
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();

    // Check mark animation (0.8s)
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );

    // Pulse animation (continuous)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Slide up animation (0.6s)
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    // Calendar button animation (0.5s)
    _calendarController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _calendarScaleAnimation = CurvedAnimation(
      parent: _calendarController,
      curve: Curves.elasticOut,
    );

    // Start animation sequence
    _startAnimationSequence();
  }

  void _startAnimationSequence() async {
    // 1. Slide up (0.6s)
    await _slideController.forward();

    // 2. Check mark appears (0.8s)
    await _checkController.forward();

    // 3. Show calendar button after 0.3s delay
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _showCalendarButton = true);
    await _calendarController.forward();
  }

  @override
  void dispose() {
    _checkController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    _calendarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryPurple.withOpacity(0.4),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Check Mark with Pulse
            ScaleTransition(
              scale: _pulseAnimation,
              child: ScaleTransition(
                scale: _checkAnimation,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 50,
                    color: AppTheme.primaryPurple,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Success Text
            Text(
              '🎉 Meeting Booked!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              'AI Agent successfully scheduled your meeting',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Meeting Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    Icons.person_rounded,
                    'With',
                    widget.contactName,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.coffee_rounded,
                    'Type',
                    widget.meetingType,
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    Icons.access_time_rounded,
                    'Time',
                    DateFormat('MMM dd, yyyy • h:mm a').format(widget.meetingTime),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Calendar Button (Animated)
            if (_showCalendarButton)
              ScaleTransition(
                scale: _calendarScaleAnimation,
                child: _isBooking
                    ? const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : ElevatedButton.icon(
                        onPressed: _handleAddToCalendar,
                        icon: const Icon(Icons.calendar_today_rounded, size: 20),
                        label: const Text(
                          'Add to Google Calendar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: AppTheme.primaryPurple,
                          backgroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
              ),

            const SizedBox(height: 12),

            // Close Button
            TextButton(
              onPressed: widget.onComplete,
              child: Text(
                'Done',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleAddToCalendar() async {
    if (widget.onAddToCalendar == null) return;

    setState(() => _isBooking = true);

    try {
      // Call the Google Calendar integration
      widget.onAddToCalendar!();

      // Show success feedback
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        setState(() => _isBooking = false);
        
        // Show snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Added to Google Calendar! 📅'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        // Auto-close after 1.5s
        await Future.delayed(const Duration(milliseconds: 1500));
        widget.onComplete();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBooking = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(child: Text('Failed to add to calendar')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
}

/// Shows the meeting booking animation as a modal
Future<void> showMeetingBookingAnimation({
  required BuildContext context,
  required String contactName,
  required String meetingType,
  required DateTime meetingTime,
  VoidCallback? onAddToCalendar,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.7),
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: MeetingBookingAnimation(
        contactName: contactName,
        meetingType: meetingType,
        meetingTime: meetingTime,
        onComplete: () => Navigator.of(context).pop(),
        onAddToCalendar: onAddToCalendar,
      ),
    ),
  );
}
