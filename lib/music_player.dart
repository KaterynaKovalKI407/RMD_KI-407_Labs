import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class MusicPlayer with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<String> _playlist = [
    'music/cola.mp3',
    'music/time.mp3',
    'music/die.mp3',
    'music/dmd.mp3',
    'music/wc.mp3',
    'music/ultraviolence.mp3', 
  ];
  int _currentTrackIndex = 0;

  bool _isPlaying = false;
  double _volume = 1.0; // Значення гучності від 0.0 до 1.0

  MusicPlayer() {
    // Додаємо слухача на завершення треку
    _audioPlayer.onPlayerComplete.listen((event) {
      _playNextTrack();
    });
  }

  Future<void> toggleMusic() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _playTrack(_playlist[_currentTrackIndex]);
    }
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  Future<void> _playTrack(String track) async {
    await _audioPlayer.play(AssetSource(track));
    await _audioPlayer.setVolume(_volume);
    _isPlaying = true;
    notifyListeners();
  }

  void _playNextTrack() {
    if (_currentTrackIndex < _playlist.length - 1) {
      _currentTrackIndex++;
      _playTrack(_playlist[_currentTrackIndex]);
    } else {
      // Якщо пісні закінчилися, скидаємо індекс або зупиняємо плеєр
      _currentTrackIndex = 0; // Скинути до першого треку
      _isPlaying = false; // Зупинити плеєр
      notifyListeners(); // Оновити стан
    }
  }

  Future<void> setVolume(double volume) async {
    _volume = volume; // Оновити значення гучності
    await _audioPlayer.setVolume(volume);
  }

  bool get isPlaying => _isPlaying;
}
