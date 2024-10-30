import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rmd_koval_ki407_lab2/main_page.dart';
import 'package:rmd_koval_ki407_lab2/registration_page.dart';
import 'package:rmd_koval_ki407_lab2/user_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rmd_koval_ki407_lab2/main.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:rmd_koval_ki407_lab2/globals.dart';

var isConnectedToInternet = connectForInet;
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  StreamSubscription? _internetConnectionStreamSubscription;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  @override
  void initState() {
    super.initState();
    checkAutoLogin();
    _internetConnectionStreamSubscription
        ?? InternetConnectionCheckerPlus().onStatusChange.listen((event) {
      switch (event) {
        case InternetConnectionStatus.connected:
          setState(() {
            isConnectedToInternet = true;
          });
          break;
        case InternetConnectionStatus.disconnected:
          setState(() {
            isConnectedToInternet = false;
          });
          break;
        default:
          setState(() {
            isConnectedToInternet = false;
          });
          break;
      }
    });
  }

  @override
  void dispose() {
    _internetConnectionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    }
  }

  void _showLoginResultDialog(bool isSuccess, {String? message}) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isSuccess ? 'Success' : 'Error'),
          content: Text(message ?? (isSuccess ? 'Login successful!' : 'Invalid credentials.')),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogin() async {
    // Перевірка на наявність інтернету
    if (!isConnectedToInternet) {
      _showLoginResultDialog(false, message: 'No internet connection.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final userPreferences = UserPreferences(prefs);

    final String? storedEmail = userPreferences.getUserEmail();
    final String? storedPassword = userPreferences.getUserPassword();

    final String enteredEmail = emailController.text.trim();
    final String enteredPassword = passwordController.text.trim();

    if (enteredEmail.isEmpty || enteredPassword.isEmpty) {
      _showLoginResultDialog(false);
      return;
    }

    if (enteredEmail == storedEmail && enteredPassword == storedPassword) {
      await prefs.setBool('isLoggedIn', true);
      _showLoginResultDialog(true);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainPage()),
      );
    } else {
      _showLoginResultDialog(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Healthy'),
        centerTitle: true,
        actions: [
          ConnectionStatusWidget(isConnected: isConnectedToInternet),
          const SizedBox(width: 16),
          const MusicContextMenu(),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Email',
              icon: Icons.email,
              controller: emailController,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Password',
              icon: Icons.lock,
              obscureText: true,
              controller: passwordController,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _performLogin,
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RegistrationPage()),
                );
              },
              child: const Text('Don\'t have an account? Register'),
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectionStatusWidget extends StatelessWidget {
  final bool isConnected;

  const ConnectionStatusWidget({required this.isConnected, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(
      isConnected ? Icons.wifi_outlined : Icons.wifi_off_outlined,
      color: isConnected ? Colors.green : Colors.red,
      size: 40,
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextEditingController controller;

  const CustomTextField({
    required this.label,
    required this.icon,
    required this.controller,
    super.key,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
