import 'package:flutter/material.dart';
import 'dart:async';

/// iOS-style notification system that shows notifications from the top of the screen
class NotificationService {
  static final NotificationService _instance = NotificationService._instance;
  factory NotificationService() => _instance;
  
  static OverlayEntry? _currentNotification;
  static Timer? _dismissTimer;
  
  /// Show an iOS-style notification from the top
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    String? subtitle,
    IconData icon = Icons.notifications,
    Color iconColor = Colors.blue,
    Duration duration = const Duration(seconds: 5),
    VoidCallback? onTap,
  }) {
    // Remove existing notification if any
    dismiss();
    
    _currentNotification = OverlayEntry(
      builder: (context) => _IOSNotificationOverlay(
        title: title,
        message: message,
        subtitle: subtitle,
        icon: icon,
        iconColor: iconColor,
        onTap: () {
          dismiss();
          onTap?.call();
        },
        onDismiss: dismiss,
      ),
    );
    
    // Add to overlay
    Overlay.of(context).insert(_currentNotification!);
    
    // Auto-dismiss after duration
    _dismissTimer = Timer(duration, () {
      dismiss();
    });
  }
  
  /// Dismiss current notification
  static void dismiss() {
    _dismissTimer?.cancel();
    _currentNotification?.remove();
    _currentNotification = null;
  }
}

/// iOS-style notification widget that slides from top
class _IOSNotificationOverlay extends StatefulWidget {
  final String title;
  final String message;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  
  const _IOSNotificationOverlay({
    required this.title,
    required this.message,
    this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.onDismiss,
  });
  
  @override
  State<_IOSNotificationOverlay> createState() => _IOSNotificationOverlayState();
}

class _IOSNotificationOverlayState extends State<_IOSNotificationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1), // Start from above screen
      end: Offset.zero, // Slide to normal position
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));
    
    // Start animation
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  void _dismissWithAnimation() async {
    await _controller.reverse();
    widget.onDismiss();
  }
  
  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: GestureDetector(
              onTap: widget.onTap,
              onVerticalDragUpdate: (details) {
                // Swipe up to dismiss
                if (details.delta.dy < -5) {
                  _dismissWithAnimation();
                }
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // App Icon
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: widget.iconColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.iconColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title (App name)
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                'now',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          
                          // Subtitle (optional)
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          
                          // Message
                          const SizedBox(height: 4),
                          Text(
                            widget.message,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
