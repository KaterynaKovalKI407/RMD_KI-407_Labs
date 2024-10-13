import 'package:flutter/material.dart';
import 'package:rmd_koval_ki407_lab2/user_profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rmd_koval_ki407_lab2/user_preferences.dart';
import 'package:rmd_koval_ki407_lab2/main.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserEmail();
  }

  // Додаємо асинхронну функцію для отримання електронної пошти користувача
  Future<void> _loadUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final userPreferences = UserPreferences(prefs);
    String? email = userPreferences.getUserEmail();
    setState(() {
      userEmail = email;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
        actions: [
          const MusicContextMenu(), // Контекстне меню на всіх сторінках
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to the Main Page!',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 24),
            if (userEmail != null)
              Text('Logged in as: $userEmail'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserProfilePage()),
                );
              },
              child: const Text('Go to Profile'),
            ),
          ],
        ),
      ),
    );
  }
}
