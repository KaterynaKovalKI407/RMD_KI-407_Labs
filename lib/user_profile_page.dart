import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rmd_koval_ki407_lab2/main.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  String name = '';
  String email = '';
  String password = '';
  String? imagePath; // Локальний шлях до зображення
  String? firebaseImageUrl; // URL зображення з Firebase

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('user_name') ?? 'John Doe';
      email = prefs.getString('user_email') ?? 'john.doe@example.com';
      password = prefs.getString('user_password') ?? '';
      firebaseImageUrl = prefs.getString('user_image_url'); // Завантажуємо URL зображення з Firebase
      imagePath = prefs.getString('user_image'); // Завантажуємо локальний шлях до зображення
    });
  }

  Future<void> _updateUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setString('user_password', password);
    if (firebaseImageUrl != null) {
      await prefs.setString('user_image_url', firebaseImageUrl!); // Зберігаємо URL зображення
    } else {
      await prefs.remove('user_image_url'); // Якщо URL null, видаляємо його
    }
    if (imagePath != null) {
      await prefs.setString('user_image', imagePath!); // Зберігаємо локальний шлях до зображення
    } else {
      await prefs.remove('user_image'); // Якщо шлях null, видаляємо його з SharedPreferences
    }
  }

  Future<void> _changeProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Завантажуємо зображення в Firebase
      String fileName = image.name;
      File imageFile = File(image.path);
      try {
        // Завантажуємо зображення в Firebase Storage
        Reference storageRef = FirebaseStorage.instance.ref().child('profile_images/$fileName');
        await storageRef.putFile(imageFile);

        // Отримуємо URL зображення
        firebaseImageUrl = await storageRef.getDownloadURL();

        setState(() {
          imagePath = image.path; // Зберігаємо локальний шлях
        });

        await _updateUserData(); // Зберігаємо новий URL до зображення
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated')),
        );
      } catch (e) {
        print('Error uploading image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          const MusicContextMenu(), // Контекстне меню на всіх сторінках
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: _changeProfilePicture,
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: firebaseImageUrl != null
                      ? NetworkImage(firebaseImageUrl!) // Завантаження зображення з Firebase
                      : const AssetImage('assets/images/icon.jpg') as ImageProvider,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                email,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  await _showEditDialog();
                },
                child: const Text('Edit Profile'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await _showChangePasswordDialog();
                },
                child: const Text('Change Password'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Back to Main'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog() async {
    final TextEditingController nameController = TextEditingController(text: name);
    final TextEditingController emailController = TextEditingController(text: email);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Profile'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                setState(() {
                  name = nameController.text;
                  email = emailController.text;
                });
                _updateUserData();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showChangePasswordDialog() async {
    final TextEditingController passwordController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: TextField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: 'New Password'),
            obscureText: true,
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Change'),
              onPressed: () {
                setState(() {
                  password = passwordController.text;
                });
                _updateUserData();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
