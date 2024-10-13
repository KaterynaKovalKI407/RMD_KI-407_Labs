import 'package:flutter/material.dart';
import 'package:rmd_koval_ki407_lab2/user_profile_page.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Page'),
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
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => 
                  const UserProfilePage(),),
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
