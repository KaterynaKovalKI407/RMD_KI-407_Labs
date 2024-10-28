import 'package:flutter/material.dart';
import 'package:rmd_koval_ki407_lab2/main_page.dart';
import 'package:rmd_koval_ki407_lab2/registration_page.dart';
import 'package:rmd_koval_ki407_lab2/user_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rmd_koval_ki407_lab2/main.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        actions: [
          const MusicContextMenu(), // Контекстне меню на всіх сторінках
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomTextField(
              label: 'Email',
              icon: Icons.email,
              controller: emailController, // Додаємо контролер
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Password',
              icon: Icons.lock,
              obscureText: true,
              controller: passwordController, // Додаємо контролер
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                final userPreferences = UserPreferences(prefs);

                final String? storedEmail = userPreferences.getUserEmail();
                final String? storedPassword = userPreferences.getUserPassword();

                // Отримуємо значення з полів введення
                final String enteredEmail = emailController.text;
                final String enteredPassword = passwordController.text;

                // Перевіряємо, чи введені дані правильні
                if (enteredEmail == storedEmail && enteredPassword == storedPassword) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MainPage()),
                  );
                } else {
                  // Виводимо повідомлення про помилку
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid credentials')),
                  );
                }
              },
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

class CustomTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextEditingController controller; // Додаємо контролер

  const CustomTextField({required this.label, required this.icon, required this.controller, super.key,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, // Встановлюємо контролер
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
