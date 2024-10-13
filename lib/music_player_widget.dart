import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class MusicPlayerWidget extends StatefulWidget {
  const MusicPlayerWidget({Key? key}) : super(key: key);

  @override
  _MusicPlayerWidgetState createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget> with WidgetsBindingObserver {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = true; // Змінна для стану музики
  double _volume = 1.0; // Змінна для гучності (0.0 - 1.0)
  bool _showSlider = false; // Для показу/приховування повзунка

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _playMusic();
    WidgetsBinding.instance.addObserver(this); // Додати спостерігача за станом
  }

  Future<void> _playMusic() async {
    await _audioPlayer.setVolume(_volume); // Встановити гучність
    await _audioPlayer.play(AssetSource('music/cola.mp3'));
  }

  void _toggleMusic() {
    setState(() {
      _isPlaying = !_isPlaying; // Змінити стан музики
      if (_isPlaying) {
        _playMusic(); // Відтворити музику
      } else {
        _audioPlayer.stop(); // Зупинити музику
      }
    });
  }

  void _setVolume(double value) {
    setState(() {
      _volume = value; // Змінити гучність
      _audioPlayer.setVolume(_volume); // Встановити нову гучність
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    WidgetsBinding.instance.removeObserver(this); // Видалити спостерігача
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _audioPlayer.stop(); // Зупинити музику, коли додаток згортається
    } else if (state == AppLifecycleState.resumed) {
      if (_isPlaying) {
        _playMusic(); // Відтворити музику, коли додаток знову активний
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ElevatedButton(
          onPressed: _toggleMusic,
          child: Text(_isPlaying ? 'Stop' : 'Play'),
        ),
        IconButton(
          icon: const Icon(Icons.volume_up),
          onPressed: () {
            setState(() {
              _showSlider = !_showSlider; // Toggle slider visibility
            });
          },
        ),
        if (_showSlider)
          Slider(
            value: _volume,
            onChanged: _setVolume,
            min: 0.0,
            max: 1.0,
            divisions: 10,
          ),
      ],
    );
  }
}
