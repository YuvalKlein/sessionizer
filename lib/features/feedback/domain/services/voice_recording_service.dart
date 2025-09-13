import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class VoiceRecordingService {
  static html.MediaRecorder? _mediaRecorder;
  static List<html.Blob> _recordedChunks = [];
  static html.MediaStream? _stream;

  /// Start recording audio from microphone
  static Future<String> startRecording() async {
    try {
      if (!kIsWeb) {
        throw Exception('Voice recording is only supported on web platform');
      }

      // Request microphone permission
      _stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
          'sampleRate': 44100,
        }
      });

      if (_stream == null) {
        throw Exception('Failed to access microphone');
      }

      // Clear previous recordings
      _recordedChunks.clear();

      // Create MediaRecorder
      _mediaRecorder = html.MediaRecorder(_stream!, {
        'mimeType': 'audio/webm;codecs=opus',
      });

      // Set up event handlers
      _mediaRecorder!.addEventListener('dataavailable', (event) {
        final data = (event as html.BlobEvent).data;
        if (data != null && data.size > 0) {
          _recordedChunks.add(data);
        }
      });

      // Start recording
      _mediaRecorder!.start(100); // Record in 100ms chunks
      
      print('✅ Voice recording started');
      return 'recording_${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      print('❌ Error starting recording: $e');
      rethrow;
    }
  }

  /// Stop recording and return the audio file path
  static Future<String?> stopRecording() async {
    try {
      if (_mediaRecorder == null) {
        throw Exception('No active recording');
      }

      // Stop recording
      _mediaRecorder!.stop();
      
      // Stop all tracks to release microphone
      _stream?.getTracks().forEach((track) => track.stop());
      
      // Wait a bit for data to be available
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (_recordedChunks.isEmpty) {
        throw Exception('No audio data recorded');
      }

      // Create blob from chunks
      final audioBlob = html.Blob(_recordedChunks, 'audio/webm');
      final audioUrl = html.Url.createObjectUrl(audioBlob);
      
      print('✅ Voice recording stopped, size: ${audioBlob.size} bytes');
      return audioUrl;
    } catch (e) {
      print('❌ Error stopping recording: $e');
      return null;
    }
  }

  /// Transcribe audio to text using Web Speech API
  static Future<String> transcribeAudio(String audioPath) async {
    try {
      // For now, return a placeholder since Web Speech API transcription 
      // requires real-time processing during recording
      // We'll implement this with a proper speech-to-text service later
      return 'Transcription will be implemented with Google Speech-to-Text API';
    } catch (e) {
      print('❌ Error transcribing audio: $e');
      throw Exception('Failed to transcribe audio: $e');
    }
  }

  /// Delete a recording file
  static Future<void> deleteRecording(String recordingPath) async {
    try {
      // Revoke the object URL to free memory
      html.Url.revokeObjectUrl(recordingPath);
      _recordedChunks.clear();
      print('✅ Recording deleted');
    } catch (e) {
      print('❌ Error deleting recording: $e');
    }
  }

  /// Check if microphone permission is available
  static Future<bool> checkMicrophonePermission() async {
    try {
      if (!kIsWeb) return false;
      
      final permissions = await html.window.navigator.permissions?.query({'name': 'microphone'});
      return permissions?.state == 'granted';
    } catch (e) {
      print('❌ Error checking microphone permission: $e');
      return false;
    }
  }

  /// Request microphone permission
  static Future<bool> requestMicrophonePermission() async {
    try {
      if (!kIsWeb) return false;
      
      final stream = await html.window.navigator.mediaDevices?.getUserMedia({
        'audio': true
      });
      
      if (stream != null) {
        // Stop the stream immediately - we just wanted to check permission
        stream.getTracks().forEach((track) => track.stop());
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ Error requesting microphone permission: $e');
      return false;
    }
  }
}
