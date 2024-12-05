
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
import 'package:rmd_koval_ki407_lab2/uv_provider.dart';
//import 'package:rmd_koval_ki407_lab2/uv_index_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

Future <void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
   await Supabase.initialize(
    url: 'https://ovnxbohzhvmhokxdgxix.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im92bnhib2h6aHZtaG9reGRneGl4Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzExMDI5NTAsImV4cCI6MjA0NjY3ODk1MH0.Op_T9IjutUYAhuuBVb6wIWu6cZWCTlCSGa7eAWOoHtg',
  );

SharedPreferences prefs = await SharedPreferences.getInstance();
bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
int patientId = prefs.getInt('patient_id') ?? 0; // Якщо значення null, встановлюється значення за замовчуванням 0  // Додаємо перевірку з логом
print('Patient ID at startup: $patientId');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MusicPlayerState()),
        ChangeNotifierProvider(create: (context) => UVProvider()),
      ],
      child: MyApp(isLoggedIn: isLoggedIn, patientId:patientId),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final int patientId;
   const MyApp({super.key, required this.isLoggedIn, required this.patientId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isLoggedIn ?  MainPage(patientId: patientId) : 
      LoginPage(patientId: patientId),
      routes: {
        '/main': (context) => MainPage(patientId: patientId),
        '/register': (context) => const RegistrationPage(),
        '/profile': (context) => UserProfilePage(patientId: patientId),
        '/login': (context) => LoginPage(patientId: patientId),
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
