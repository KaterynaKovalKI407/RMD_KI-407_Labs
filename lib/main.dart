import 'package:flutter/material.dart';
import 'package:rmd_koval_ki407_lab2/login_page.dart';
//import 'package:rmd_koval_ki407_lab2/registration_page.dart';
//import 'package:rmd_koval_ki407_lab2/user_profile_page.dart';
//import 'package:rmd_koval_ki407_lab2/main_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Lab 2',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const LoginPage(), // Початкова сторінка
    );
  }
}
