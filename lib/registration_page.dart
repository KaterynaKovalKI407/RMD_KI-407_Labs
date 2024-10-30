import 'dart:async';
import 'package:flutter/material.dart';
import 'package:rmd_koval_ki407_lab2/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rmd_koval_ki407_lab2/main.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
        centerTitle: true,
        actions: [
          ConnectionStatusWidget(
              isConnected: isConnectedToInternet), // Wi-Fi icon in AppBar
          const SizedBox(width: 16), // Space between icons
          const MusicContextMenu(), // Context menu on all pages
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Center content vertically
          crossAxisAlignment:
              CrossAxisAlignment.center, // Center content horizontally
          children: [
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
              onPressed: () async {
                // Перевірка на наявність інтернету
                if (!isConnectedToInternet) {
                  _showRegistrationDialog(context);
                  return;
                }

                String name = nameController.text;
                String email = emailController.text;
                String password = passwordController.text;

                // Check if fields are filled
                if (name.isEmpty || email.isEmpty || password.isEmpty) {
                  _showEmptyFieldsDialog(
                      context); // Show dialog if fields are empty
                  return;
                }

                final prefs = await SharedPreferences.getInstance();

                // Check if account already exists
                String? storedEmail = prefs.getString('user_email');
                if (email == storedEmail) {
                  _showAccountExistsDialog(context);
                } else {
                  // Save user data if new account
                  prefs.setString('user_name', name);
                  prefs.setString('user_email', email);
                  prefs.setString('user_password', password);

                  // Navigate to the login page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                }
              },
              child: const Text('Register'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAccountExistsDialog(BuildContext context) {
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
                  MaterialPageRoute(builder: (context) => const LoginPage()),
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
