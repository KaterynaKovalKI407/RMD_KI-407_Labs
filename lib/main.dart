import 'package:flutter/material.dart';
//import 'package:shared_preferences/shared_preferences.dart';
//import 'package:image_picker/image_picker.dart';
//import 'dart:io';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:rmd_koval_ki407_lab2/login_page.dart';
import 'package:rmd_koval_ki407_lab2/main_page.dart';
import 'package:rmd_koval_ki407_lab2/registration_page.dart';
import 'package:rmd_koval_ki407_lab2/user_profile_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

class MusicPlayerState extends ChangeNotifier {
  MusicPlayerState() {
    _audioPlayer = AudioPlayer();
  }

  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  double _volume = 1.0;

  bool get isPlaying => _isPlaying;
  double get volume => _volume;

  Future<void> toggleMusic() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(AssetSource('music/cola.mp3'));
      await _audioPlayer.setVolume(_volume);
    }
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void changeVolume(double value) {
    _volume = value;
    _audioPlayer.setVolume(_volume);
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

class MusicContextMenu extends StatelessWidget {
  const MusicContextMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final musicPlayer = context.watch<MusicPlayerState>();

    return PopupMenuButton<String>(
      icon: const Icon(Icons.music_note),
      onSelected: (value) {
        if (value == 'toggle') {
          musicPlayer.toggleMusic();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'toggle',
          child: Row(
            children: [
              Icon(musicPlayer.isPlaying ? Icons.pause : Icons.play_arrow),
              const SizedBox(width: 8),
              Text(musicPlayer.isPlaying ? 'Pause Music' : 'Play Music'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'adjust_volume',
          child: VolumeSlider(), // Додаємо повзунок гучності
        ),
      ],
    );
  }
}

class VolumeSlider extends StatefulWidget {
  const VolumeSlider({super.key});

  @override
  _VolumeSliderState createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<VolumeSlider> {
  bool _isVisible = false;

  @override
  Widget build(BuildContext context) {
    final musicPlayer = context.watch<MusicPlayerState>();

    return Column(
      children: [
        const Text('Volume'),
        Slider(
                value: musicPlayer.volume,
                onChanged: (value) {
                  musicPlayer.changeVolume(value);
                },
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: '${(musicPlayer.volume * 100).round()}%',
              ),       
      ],
    );
  }
}

void main () async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => MusicPlayerState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Lab 2',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(),
      routes: {
        '/main': (context) => const MainPage(),
        '/register': (context) => const RegistrationPage(),
        '/profile': (context) => const UserProfilePage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
