import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rmd_koval_ki407_lab2/main.dart'; 
import 'package:rmd_koval_ki407_lab2/main_page.dart';
import 'package:rmd_koval_ki407_lab2/registration_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:rmd_koval_ki407_lab2/globals.dart';
import 'package:rmd_koval_ki407_lab2/uv_index_widget.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';  

var isConnectedToInternet = connectForInet;

class LoginPage extends StatefulWidget {
  final int? patientId;
  const LoginPage({Key? key, this.patientId}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  StreamSubscription? _internetConnectionStreamSubscription;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
   
  String hashPasswordWithSalt(String password, String salt) {
    final key = utf8.encode(salt); // Використовуємо сіль як ключ
    final bytes = utf8.encode(password);
    final hmacSha256 = Hmac(sha256, key); // Використовуємо HMAC-SHA256
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }

  @override
  void initState() {
    super.initState();
    checkAutoLogin();
    _internetConnectionStreamSubscription ??= InternetConnectionCheckerPlus().onStatusChange.listen((event) {
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

    if (isLoggedIn && widget.patientId != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MainPage(patientId: widget.patientId!),
        ),
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
    if (!isConnectedToInternet) {
      _showLoginResultDialog(false, message: 'No internet connection.');
      return;
    }

    String enteredEmail = emailController.text.trim();
    String enteredPassword = passwordController.text.trim();

    print('Entered email: $enteredEmail');
    print('Entered raw password: $enteredPassword');

    if (enteredEmail.isEmpty || enteredPassword.isEmpty) {
      _showLoginResultDialog(false, message: 'Please fill in all fields.');
      return;
    }

    try {
      // Отримуємо дані користувача з бази даних, включаючи сіль і хешований пароль
      final response = await Supabase.instance.client
          .from('patients')
          .select('patient_id, name, password, salt')
          .eq('email', enteredEmail)
          .limit(1)
          .execute();

      print('Response from Supabase: ${response.data}');
      if (response.error != null) {
        print('Supabase error: ${response.error?.message}');
      }

      if (response.data != null && (response.data as List).isNotEmpty) {
        final patientData = response.data[0];
        final patientId = patientData['patient_id'] as int;
        final storedHashedPassword = patientData['password'] as String;
        final salt = patientData['salt'] as String;

        // Хешуємо введений пароль з використанням витягнутої солі
        String hashedPassword = hashPasswordWithSalt(enteredPassword, salt);
        print('Hashed password with salt: $hashedPassword');

        // Порівнюємо хешований введений пароль з хешованим паролем в базі даних
        if (hashedPassword == storedHashedPassword) {
          // Збереження даних користувача в SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setInt('patient_id', patientId);
          await prefs.setString('email', enteredEmail);
          await prefs.setString('name', patientData['name'] as String);

          print('Patient ID retrieved and saved: $patientId');
          print('Redirecting to MainPage with patient ID: $patientId');

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainPage(patientId: patientId)),
          );
        } else {
          print('Login failed: Invalid email or password.');
          _showLoginResultDialog(false, message: 'Invalid email or password.');
        }
      } else {
        print('Login failed: Invalid email or password.');
        _showLoginResultDialog(false, message: 'Invalid email or password.');
      }
    } catch (error) {
      print('Login error: $error');
      _showLoginResultDialog(false, message: 'Server error.');
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        centerTitle: true,
        actions: [
          UVIndexWidget(),
          const SizedBox(width: 16),
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
            Text(
              'Healthy',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
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