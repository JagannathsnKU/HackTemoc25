import 'package:just_audio/just_audio.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> playAudio(String assetPath) async {
    try {
      await _audioPlayer.setAsset(assetPath);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing audio: $e');
      // Fail silently if audio file doesn't exist
    }
  }

  Future<void> playAudioFromUrl(String url) async {
    try {
      // Handle both local server URLs and remote URLs
      if (url.isEmpty) {
        print('Warning: Empty audio URL');
        return;
      }
      
      // If it's a relative path, make it absolute
      String audioUrl = url;
      if (url.startsWith('/audio/')) {
        audioUrl = 'http://localhost:5000$url';
      }
      
      print('Playing audio from: $audioUrl');
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
    } catch (e) {
      print('Error playing audio from URL: $e');
      // Fail silently if audio URL is not available
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}
