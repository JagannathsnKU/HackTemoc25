import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

/// Direct ElevenLabs Text-to-Speech Service
/// Bypasses backend to avoid CORS issues
class ElevenLabsService {
  static final ElevenLabsService _instance = ElevenLabsService._internal();
  factory ElevenLabsService() => _instance;
  ElevenLabsService._internal();

  // ElevenLabs Configuration
  static const String apiKey = 'sk_03167a5025adcc45a25a234c6131ca7229915188c752e062';
  static const String voiceId = 'EXAVITQu4vr4xnSDxMaL'; // Rachel voice
  static const String baseUrl = 'https://api.elevenlabs.io/v1';
  
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Generate speech from text using ElevenLabs API
  Future<Uint8List?> generateSpeech(String text) async {
    try {
      print('🔊 ElevenLabs: Generating speech for: "${text.substring(0, text.length > 50 ? 50 : text.length)}..."');
      
      final response = await http.post(
        Uri.parse('$baseUrl/text-to-speech/$voiceId'),
        headers: {
          'Accept': 'audio/mpeg',
          'Content-Type': 'application/json',
          'xi-api-key': apiKey,
        },
        body: jsonEncode({
          'text': text,
          'model_id': 'eleven_monolingual_v1',
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.75,
          },
        }),
      );

      if (response.statusCode == 200) {
        print('✅ ElevenLabs: Speech generated successfully (${response.bodyBytes.length} bytes)');
        return response.bodyBytes;
      } else {
        print('❌ ElevenLabs error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ ElevenLabs exception: $e');
      return null;
    }
  }

  /// Generate and play speech directly
  Future<bool> speak(String text) async {
    try {
      final audioData = await generateSpeech(text);
      
      if (audioData == null) {
        return false;
      }

      // Play audio from bytes
      await _audioPlayer.setAudioSource(
        _ByteAudioSource(audioData),
      );
      
      print('🔊 Playing voice message...');
      await _audioPlayer.play();
      
      return true;
    } catch (e) {
      print('❌ Error playing speech: $e');
      return false;
    }
  }

  /// Stop current playback
  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}

/// Custom audio source for playing audio from bytes
class _ByteAudioSource extends StreamAudioSource {
  final Uint8List _buffer;

  _ByteAudioSource(this._buffer);

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    start ??= 0;
    end ??= _buffer.length;
    
    return StreamAudioResponse(
      sourceLength: _buffer.length,
      contentLength: end - start,
      offset: start,
      stream: Stream.value(_buffer.sublist(start, end)),
      contentType: 'audio/mpeg',
    );
  }
}
