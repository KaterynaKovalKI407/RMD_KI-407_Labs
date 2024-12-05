import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rmd_koval_ki407_lab2/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rmd_koval_ki407_lab2/main.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:rmd_koval_ki407_lab2/uv_index_widget.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({Key? key}) : super(key: key);

  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}
class _RegistrationPageState extends State<RegistrationPage> {
  // Connection status
  bool isConnectedToInternet = false;
  StreamSubscription? _internetConnectionStreamSubscription;
 
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initial internet connection check
    InternetConnectionCheckerPlus().hasConnection.then((status) {
      setState(() {
        isConnectedToInternet = status;
        print("Initial internet connection status: $isConnectedToInternet");
      });
    });

    // Stream for ongoing status updates
    _internetConnectionStreamSubscription =
        InternetConnectionCheckerPlus().onStatusChange.listen((event) {
      print("Connection status changed: $event");
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
   String generateSalt([int length = 16]) {
    final random = Random.secure();
    final saltBytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(saltBytes);
  }
 String hashPassword(String password, String salt) {
    final key = utf8.encode(salt);
    final bytes = utf8.encode(password);
    final hmacSha256 = Hmac(sha256, key); 
    final digest = hmacSha256.convert(bytes);
    return digest.toString();
  }
// Метод для реєстрації користувача
  Future<void> _registerUser() async {
  // Перевірка на наявність інтернету
  if (!isConnectedToInternet) {
    _showDialog('Error', 'No internet connection.');
    return;
  }
  String name = nameController.text.trim();
  String email = emailController.text.trim();
  String password = passwordController.text.trim();

  // Перевірка на заповненість полів
  if (name.isEmpty || email.isEmpty || password.isEmpty) {
    _showDialog('Error', 'Please fill in all fields.');
    return;
  }

 final salt = generateSalt();
  final hashedPassword = hashPassword(password, salt);
  try {
    // Перевірка, чи існує користувач з такою ж електронною поштою в базі даних
    final response = await Supabase.instance.client
        .from('patients')
        .select('email')
        .eq('email', email)
        .execute();

    if (response.data != null && (response.data as List).isNotEmpty) {
      _showDialog('Error', 'An account with this email already exists.');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }
    // Реєструємо нового користувача
    final insertResponse = await Supabase.instance.client.from('patients').insert({
      'name': name,
      'email': email,
      'password': hashedPassword,
      'salt': salt,
    }).execute();

    if (insertResponse.error == null && insertResponse.data != null) {
      // Отримуємо `patient_id` з відповіді
      final patientId = insertResponse.data[0]['patient_id'] as int;

      // Збереження даних у SharedPreferences, включаючи `patient_id`
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', name);
      await prefs.setString('email', email);
      await prefs.setString('password', hashedPassword); // Збереження хешованого пароля
      await prefs.setString('salt', salt);
      await prefs.setInt('patient_id', patientId); // Збереження patient_id
      await prefs.setBool('isLoggedIn', false);

      print('Patient ID saved in SharedPreferences: $patientId');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } else {
      _showDialog('Error', 'User registration failed.');
    }
  } catch (e) {
    _showDialog('Error', 'An error occurred during registration.');
    print('Error: $e');
  }
}
  // Відображення діалогового вікна з повідомленням
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text(''),
      centerTitle: true,
      actions: [
        UVIndexWidget(), // Віджет з УФ-індексом для Львова
        const SizedBox(width: 16),
        ConnectionStatusWidget(
          isConnected: isConnectedToInternet,
        ), // Wi-Fi icon in AppBar
        const SizedBox(width: 16), // Space between icons
        const MusicContextMenu(),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
        crossAxisAlignment: CrossAxisAlignment.center, // Center content horizontally
        children: [
          Text('Registration',style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
          const SizedBox(height: 16),
          const SizedBox(height: 32), // Space between title and form
          CustomTextField(
            label: 'Name',
            icon: Icons.person,
            controller: nameController,
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
            onPressed: _registerUser,
              child : const Text ('Register'),
            ), 
  ],
        ),
      ),
    );
  }
}
   
  void _showAccountExistsDialog(BuildContext context, int patientId) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Account Already Exists'),
        content: const Text(
            'An account with this email already exists. Please log in.'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginPage(patientId: patientId)),
              );
            },
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}
   

  void _showEmptyFieldsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Empty Fields'),
          content: const Text('Please fill in all fields before registering.'),
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


void _showRegistrationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Error'),
        content: const Text('No internet connection.'),
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

class ConnectionStatusWidget extends StatelessWidget {
  final bool isConnected;

  const ConnectionStatusWidget({required this.isConnected, Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Icon(
      isConnected ? Icons.wifi_outlined : Icons.wifi_off_outlined,
      color: isConnected ? Colors.green : Colors.red,
      size: 40,
    );
  }
}
