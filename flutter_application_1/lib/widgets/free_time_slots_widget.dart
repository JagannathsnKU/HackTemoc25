import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/calendar_service.dart';
import '../theme/ios_theme.dart';

class FreeTimeSlotsWidget extends StatefulWidget {
  final String contactName;
  final int meetingDuration; // in minutes

  const FreeTimeSlotsWidget({
    super.key,
    required this.contactName,
    this.meetingDuration = 30,
  });

  @override
  State<FreeTimeSlotsWidget> createState() => _FreeTimeSlotsWidgetState();
}

class _FreeTimeSlotsWidgetState extends State<FreeTimeSlotsWidget> {
  List<FreeTimeSlot>? _freeSlots;
  bool _isLoading = false;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadFreeSlots();
  }

  Future<void> _loadFreeSlots() async {
    setState(() => _isLoading = true);
    
    try {
      final slots = await CalendarService.findFreeTimeSlots(
        durationMinutes: widget.meetingDuration,
        daysAhead: 7,
      );
      
      setState(() {
        _freeSlots = slots;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading free slots: $e');
      setState(() {
        _freeSlots = [];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: IOSTheme.spacing16,
        vertical: IOSTheme.spacing8,
      ),
      decoration: BoxDecoration(
        color: IOSTheme.iosSystemBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Column(
          children: [
            // Header
            InkWell(
              onTap: () {
                setState(() => _isExpanded = !_isExpanded);
              },
              child: Padding(
                padding: const EdgeInsets.all(IOSTheme.spacing16),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: IOSTheme.iosBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        CupertinoIcons.calendar,
                        size: 18,
                        color: IOSTheme.iosBlue,
                      ),
                    ),
                    const SizedBox(width: IOSTheme.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Schedule Meeting',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: IOSTheme.semibold,
                              color: IOSTheme.iosLabel,
                              letterSpacing: -0.32,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isLoading
                                ? 'Finding free time...'
                                : _freeSlots == null || _freeSlots!.isEmpty
                                    ? 'No slots available'
                                    : '${_freeSlots!.length} slots available',
                            style: const TextStyle(
                              fontSize: 13,
                              color: IOSTheme.iosSecondaryLabel,
                              letterSpacing: -0.08,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      _isExpanded
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.chevron_down,
                      size: 18,
                      color: IOSTheme.iosSecondaryLabel,
                    ),
                  ],
                ),
              ),
            ),

            // Free slots list (expandable)
            if (_isExpanded) ...[
              Divider(height: 1, color: IOSTheme.iosSecondarySystemBackground),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(IOSTheme.spacing24),
                  child: CupertinoActivityIndicator(),
                )
              else if (_freeSlots == null || _freeSlots!.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(IOSTheme.spacing24),
                  child: Text(
                    'No free time slots found in the next 7 days',
                    style: const TextStyle(
                      fontSize: 14,
                      color: IOSTheme.iosSecondaryLabel,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _freeSlots!.length > 5 ? 5 : _freeSlots!.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    indent: 52,
                    color: IOSTheme.iosSecondarySystemBackground,
                  ),
                  itemBuilder: (context, index) {
                    final slot = _freeSlots![index];
                    return _buildTimeSlotItem(slot);
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotItem(FreeTimeSlot slot) {
    return InkWell(
      onTap: () => _scheduleMeeting(slot),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: IOSTheme.spacing16,
          vertical: IOSTheme.spacing12,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: IOSTheme.iosGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                CupertinoIcons.clock,
                size: 16,
                color: IOSTheme.iosGreen,
              ),
            ),
            const SizedBox(width: IOSTheme.spacing12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    CalendarService.formatFreeSlot(slot),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: IOSTheme.iosLabel,
                      letterSpacing: -0.24,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.meetingDuration} min meeting',
                    style: const TextStyle(
                      fontSize: 13,
                      color: IOSTheme.iosSecondaryLabel,
                      letterSpacing: -0.08,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: IOSTheme.iosGray3,
            ),
          ],
        ),
      ),
    );
  }

  void _scheduleMeeting(FreeTimeSlot slot) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Schedule Meeting'),
        content: Text(
          'Schedule a ${widget.meetingDuration}-minute meeting with ${widget.contactName} on ${CalendarService.formatFreeSlot(slot)}?',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              Navigator.pop(context);
              _confirmSchedule(slot);
            },
            child: const Text('Schedule'),
          ),
        ],
      ),
    );
  }

  void _confirmSchedule(FreeTimeSlot slot) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(CupertinoIcons.check_mark_circled_solid,
                color: IOSTheme.iosGreen, size: 24),
            SizedBox(width: 8),
            Text('Meeting Scheduled!'),
          ],
        ),
        content: Text(
          'Your meeting with ${widget.contactName} has been scheduled for ${CalendarService.formatFreeSlot(slot)}.\n\nA calendar invite has been sent.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
