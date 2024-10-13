import 'package:flutter/material.dart';
import 'package:rmd_koval_ki407_lab2/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rmd_koval_ki407_lab2/main.dart';

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Створення контролерів для текстових полів
    final TextEditingController nameController = TextEditingController();
    final TextEditingController emailController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
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
              label: 'Name',
              icon: Icons.person,
              controller: nameController, // Передача контролера
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Email',
              icon: Icons.email,
              controller: emailController, // Передача контролера
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Password',
              icon: Icons.lock,
              obscureText: true,
              controller: passwordController, // Передача контролера
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                // Логіка для реєстрації
                final prefs = await SharedPreferences.getInstance();
                // Отримати дані з полів та зберегти їх у SharedPreferences
                String name = nameController.text;
                String email = emailController.text;
                String password = passwordController.text;

                // Зберегти дані (додайте власну логіку валідації тут)
                // Наприклад:
                prefs.setString('user_name', name);
                prefs.setString('user_email', email);
                prefs.setString('user_password', password);

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              },
              child: const Text('Register'),
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
  final TextEditingController controller; // Додано контролер

  const CustomTextField({
    required this.label,
    required this.icon,
    required this.controller, // Контролер обов'язковий
    this.obscureText = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, // Використання контролера
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
