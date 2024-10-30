import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:rmd_koval_ki407_lab2/login_page.dart';
import 'package:rmd_koval_ki407_lab2/main_page.dart';
import 'package:rmd_koval_ki407_lab2/registration_page.dart';
import 'package:rmd_koval_ki407_lab2/user_profile_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Провайдер для управління музичним плеєром
class MusicPlayerState extends ChangeNotifier {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  double _volume = 1.0;

  // Список пісень
  final List<String> _songs = [
    'music/cola.mp3',
    'music/time.mp3',
    'music/die.mp3',
    'music/wc.mp3',
    'music/ultraviolence.mp3',
  ];
  int _currentSongIndex = 0;

  MusicPlayerState() {
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerComplete.listen((event) {
      print('Current song finished. Playing next song...');
      _playNextSong();
    });
  }

  bool get isPlaying => _isPlaying;
  double get volume => _volume;

  Future<void> toggleMusic() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _playCurrentSong();
    }
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  Future<void> _playCurrentSong() async {
    print('Playing song: ${_songs[_currentSongIndex]}');
    await _audioPlayer.play(AssetSource(_songs[_currentSongIndex]));
    await _audioPlayer.setVolume(_volume);
  }

  Future<void> _playNextSong() async {
    _currentSongIndex = (_currentSongIndex + 1) % _songs.length; // Переходьте до наступної пісні
    print('Playing next song: ${_songs[_currentSongIndex]}');
    await _playCurrentSong();
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

// Віджет для контекстного меню музики
class MusicContextMenu extends StatelessWidget {
  const MusicContextMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final musicPlayer = context.watch<MusicPlayerState>();

    return Row(
      children: [
        // Кнопка меню музики
        PopupMenuButton<String>(
          icon: const Icon(Icons.music_note, size: 30),
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
              child: VolumeSlider(),
            ),
          ],
        ),
      ],
    );
  }
}

// Віджет для слайдера гучності
class VolumeSlider extends StatelessWidget {
  const VolumeSlider({super.key});

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MusicPlayerState()),
      ],
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Lab 2',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isLoggedIn ? const MainPage() : const LoginPage(),
      routes: {
        '/main': (context) => const MainPage(),
        '/register': (context) => const RegistrationPage(),
        '/profile': (context) => const UserProfilePage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}

// Віджет для відображення статусу з'єднання
class ConnectionStatusWidget extends StatelessWidget {
  final bool isConnected;

  const ConnectionStatusWidget({required this.isConnected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(
      isConnected ? Icons.signal_wifi_4_bar : Icons.signal_wifi_off,
      color: isConnected ? Colors.green : Colors.red,
      size: 40,
    );
  }
}
