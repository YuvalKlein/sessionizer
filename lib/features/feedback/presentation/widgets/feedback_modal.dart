import 'package:flutter/material.dart';
import 'package:myapp/features/feedback/domain/services/feedback_service.dart';
import 'package:myapp/features/feedback/domain/services/voice_recording_service.dart';
import 'package:myapp/features/feedback/domain/services/device_info_service.dart';

class FeedbackModal extends StatefulWidget {
  const FeedbackModal({super.key});

  @override
  State<FeedbackModal> createState() => _FeedbackModalState();
}

class _FeedbackModalState extends State<FeedbackModal> with TickerProviderStateMixin {
  bool _isRecording = false;
  bool _hasRecording = false;
  bool _isProcessing = false;
  String? _transcription;
  String? _recordingPath;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 450, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.feedback,
                  color: Colors.orange[600],
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Voice Feedback',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tap the microphone to record your feedback. We\'ll capture your screen and device info automatically.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Recording Area
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Microphone Button
                  GestureDetector(
                    onTap: _isProcessing ? null : _toggleRecording,
                    child: AnimatedBuilder(
                      animation: _isRecording ? _pulseController : _waveController,
                      builder: (context, child) {
                        return Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isRecording 
                                ? Colors.red[600] 
                                : _hasRecording 
                                    ? Colors.green[600]
                                    : Colors.orange[600],
                            boxShadow: _isRecording
                                ? [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.3 + (_pulseController.value * 0.3)),
                                      blurRadius: 20 + (_pulseController.value * 20),
                                      spreadRadius: 5 + (_pulseController.value * 10),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.grey.withValues(alpha: 0.3),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                          ),
                          child: Icon(
                            _isRecording 
                                ? Icons.stop 
                                : _hasRecording 
                                    ? Icons.check
                                    : Icons.mic,
                            size: 50,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Status Text
                  Text(
                    _isProcessing
                        ? 'Processing...'
                        : _isRecording
                            ? 'Recording... Tap to stop'
                            : _hasRecording
                                ? 'Recording ready to send'
                                : 'Tap to start recording',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Transcription Preview
                  if (_transcription != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.text_fields, color: Colors.grey[600], size: 16),
                              const SizedBox(width: 8),
                              Text(
                                'Transcription:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _transcription!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Action Buttons
            if (_hasRecording && !_isProcessing) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deleteRecording,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _sendFeedback,
                      icon: const Icon(Icons.send),
                      label: const Text('Send Feedback'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Processing Indicator
            if (_isProcessing) ...[
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Processing your feedback...'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      // Stop recording
      await _stopRecording();
    } else {
      // Start recording
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      setState(() => _isRecording = true);
      _pulseController.repeat();
      
      final recordingPath = await VoiceRecordingService.startRecording();
      
      setState(() {
        _recordingPath = recordingPath;
      });
    } catch (e) {
      setState(() => _isRecording = false);
      _pulseController.stop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to start recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      setState(() => _isRecording = false);
      _pulseController.stop();
      
      final audioPath = await VoiceRecordingService.stopRecording();
      
      if (audioPath != null) {
        setState(() {
          _hasRecording = true;
          _recordingPath = audioPath;
          _isProcessing = true;
        });

        // Transcribe the audio
        try {
          final transcription = await VoiceRecordingService.transcribeAudio(audioPath);
          setState(() {
            _transcription = transcription;
            _isProcessing = false;
          });
        } catch (e) {
          setState(() => _isProcessing = false);
          print('Transcription failed: $e');
          // Continue without transcription
        }
      }
    } catch (e) {
      setState(() {
        _isRecording = false;
        _isProcessing = false;
      });
      _pulseController.stop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to stop recording: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteRecording() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recording'),
        content: const Text('Are you sure you want to delete this recording?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Clean up recording
      if (_recordingPath != null) {
        await VoiceRecordingService.deleteRecording(_recordingPath!);
      }
      
      setState(() {
        _hasRecording = false;
        _transcription = null;
        _recordingPath = null;
      });
    }
  }

  Future<void> _sendFeedback() async {
    if (_recordingPath == null) return;

    setState(() => _isProcessing = true);

    try {
      // Collect device information
      final deviceInfo = await DeviceInfoService.getDeviceInfo();
      
      // Skip screenshot capture for now
      
      // Send feedback
      await FeedbackService.submitFeedback(
        audioPath: _recordingPath!,
        transcription: _transcription,
        deviceInfo: deviceInfo,
        screenshotPath: null,
      );

      // Show success message
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback sent successfully! Thank you!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send feedback: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
