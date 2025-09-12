import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CancellationFeeWarningModal extends StatelessWidget {
  final String sessionTitle;
  final DateTime sessionStartTime;
  final Map<String, dynamic> cancellationPolicy;
  final Map<String, dynamic> sessionTypeData;
  final String action; // 'cancel' or 'reschedule'
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const CancellationFeeWarningModal({
    super.key,
    required this.sessionTitle,
    required this.sessionStartTime,
    required this.cancellationPolicy,
    required this.sessionTypeData,
    required this.action,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final hasCancellationFee = cancellationPolicy['hasCancellationFee'] as bool? ?? true;
    final cancellationTimeBefore = cancellationPolicy['cancellationTimeBefore'] as int? ?? 18;
    final cancellationTimeUnit = cancellationPolicy['cancellationTimeUnit'] as String? ?? 'hours';
    final cancellationFeeAmount = cancellationPolicy['cancellationFeeAmount'] as int? ?? 100;
    final cancellationFeeType = cancellationPolicy['cancellationFeeType'] as String? ?? '%';
    
    // Calculate actual fee amount
    final sessionPrice = sessionTypeData['price'] as int? ?? 100;
    final actualFeeAmount = cancellationFeeType == '%' 
        ? (cancellationFeeAmount * sessionPrice / 100).round()
        : cancellationFeeAmount;

    // Calculate time remaining until session
    final now = DateTime.now();
    final timeUntilSession = sessionStartTime.difference(now);
    final hoursUntilSession = timeUntilSession.inHours;
    final minutesUntilSession = timeUntilSession.inMinutes;

    // Determine if within cancellation window
    final cancellationWindowInMinutes = cancellationTimeUnit == 'hours' 
        ? cancellationTimeBefore * 60 
        : cancellationTimeBefore;
    final isWithinCancellationWindow = timeUntilSession.inMinutes <= cancellationWindowInMinutes;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Colors.orange[600],
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Cancellation Fee Warning',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Session Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Session: $sessionTitle',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${DateFormat.yMMMd().format(sessionStartTime)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Time: ${DateFormat.jm().format(sessionStartTime)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Time Information
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.blue[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Time Information',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isWithinCancellationWindow
                          ? '⚠️ You are within the cancellation window'
                          : '✅ You are outside the cancellation window',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isWithinCancellationWindow ? Colors.orange[700] : Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Time until session: ${_formatTimeRemaining(hoursUntilSession, minutesUntilSession)}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cancellation window: $cancellationTimeBefore $cancellationTimeUnit before session',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Fee Information
              if (hasCancellationFee && isWithinCancellationWindow) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: Colors.red[600], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Cancellation Fee',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You will be charged \$$actualFeeAmount for ${action}ing this session.',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Colors.red[700],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This fee helps compensate the instructor for the lost booking opportunity.',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (hasCancellationFee && !isWithinCancellationWindow) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'No cancellation fee will be charged since you are outside the cancellation window.',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isWithinCancellationWindow ? Colors.red[600] : Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isWithinCancellationWindow 
                            ? '${action.capitalize()} (Pay Fee)'
                            : '${action.capitalize()} (Free)',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimeRemaining(int hours, int minutes) {
    if (hours > 0) {
      return '${hours}h ${minutes % 60}m';
    } else {
      return '${minutes}m';
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}