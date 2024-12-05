import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rmd_koval_ki407_lab2/main.dart'; 
import 'package:rmd_koval_ki407_lab2/globals.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:rmd_koval_ki407_lab2/uv_index_widget.dart';
import 'package:rmd_koval_ki407_lab2/view_appointments_page.dart';
import 'package:rmd_koval_ki407_lab2/login_page.dart'; 
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';

class UserProfilePage extends StatefulWidget {
   final int? patientId;
   final int? appointmentId;
   const UserProfilePage({Key? key, required this.patientId, this.appointmentId}) : super(key: key);

  @override
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  
  bool isConnectedToInternet = false;
  StreamSubscription? _internetConnectionStreamSubscription;
  String name = '';
  String email = '';
  String password = '';
  String? imagePath; // Local image path
  String? firebaseImageUrl; // Image URL from Firebase

String generateSalt([int length = 16]) {
  final random = Random.secure();
  final saltBytes = List<int>.generate(length, (_) => random.nextInt(256));
  return base64Url.encode(saltBytes);
}

// Оновлений метод для хешування пароля з використанням солі
String hashPasswordWithSalt(String password, String salt) {
  final key = utf8.encode(salt);
  final bytes = utf8.encode(password);
  final hmacSha256 = Hmac(sha256, key);
  final digest = hmacSha256.convert(bytes);
  return digest.toString();
}

  @override
  void initState() {
    super.initState();
    print('Patient ID in UserProfilePage: ${widget.patientId}');
    _loadUserData();

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
void showMessage(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
Future<void> updatePassword(String newPassword) async {
  // Генеруємо нову сіль
  String salt = generateSalt();
  // Хешуємо новий пароль з новою сіллю
  String hashedPassword = hashPasswordWithSalt(newPassword, salt);
  print('Hashed password to be saved: $hashedPassword');
  print('Salt to be saved: $salt');

  // Оновлюємо хеш і сіль у базі даних
  final response = await Supabase.instance.client
      .from('patients')
      .update({'password': hashedPassword, 'salt': salt})
      .eq('patient_id', widget.patientId)
      .execute();

  if (response.error == null) {
    // Оновлення пароля у SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('password');
    await prefs.setString('password', hashedPassword);
    await prefs.setString('salt', salt); // Зберігаємо сіль локально для перевірки

    print('Stored hashed password in SharedPreferences: $hashedPassword');
    print('Stored salt in SharedPreferences: $salt');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password changed successfully')),
    );
  } else {
    print('Failed to update password in Supabase: ${response.error?.message}');
  }
}

 Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? '';
      email = prefs.getString('email') ?? '';
      imagePath = prefs.getString('user_image_${widget.patientId}') ?? 'assets/images/icon.jpg';
      print('Loaded imagePath: $imagePath');
    });
  }
 Future<void> updateProfile(String newName, String newEmail) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', newName);
    await prefs.setString('email', newEmail);

    setState(() {
      name = newName;
      email = newEmail;
    });

    final response = await Supabase.instance.client
        .from('patients')
        .update({'name': newName, 'email': newEmail})
        .eq('patient_id', widget.patientId)
        .execute();

    if (response.error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    } else {
      print('Failed to update profile in Supabase: ${response.error?.message}');
    }
  }
  Future<void> _changeProfilePicture() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);

  if (image != null) {
    String fileName = image.name;
    File imageFile = File(image.path);

    try {
      // Завантаження в Firebase Storage
      Reference storageRef = FirebaseStorage.instance.ref().child('profile_images/$fileName');
      await storageRef.putFile(imageFile);

      // Отримання URL зображення
      firebaseImageUrl = await storageRef.getDownloadURL();

      setState(() {
        imagePath = firebaseImageUrl; // Встановлюємо новий шлях до зображення
      });

      final prefs = await SharedPreferences.getInstance();
      int? patientId = prefs.getInt('patient_id');

      // Зберігаємо нове зображення тільки для поточного користувача
      await prefs.setString('user_image_$patientId', firebaseImageUrl!);

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
Future<void> _showLogoutDialog() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log out'),
          content: const Text('Are you sure you want to log out?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Log out'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      
      // Видаляємо дані авторизації, щоб вимагати введення пароля при повторному вході
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('password'); // Видаляємо збережений пароль
      await prefs.remove('email'); // Видаляємо збережений email

      loggedOut = true;
      connectForInet = isConnectedToInternet;

      Navigator.pushReplacementNamed(context, '/login'); // Переходимо на сторінку логіна
    }
}
Future<void> deleteAccount() async {
  // Спочатку видаляємо всі записи з `available_times`, що посилаються на поточного пацієнта
   final updateAppointmentsResponse = await Supabase.instance.client
      .from('available_times')
      .update({
        'is_available': true,
        'patient_id': null,
      })
      .eq('patient_id', widget.patientId)
      .execute();

  if (updateAppointmentsResponse.error != null) {
    print('Failed to update appointments in available_times: ${updateAppointmentsResponse.error?.message}');
    return;
  }
  // Після успішного видалення відповідних записів видаляємо акаунт з `patients`
  final response = await Supabase.instance.client
      .from('patients')
      .delete()
      .eq('patient_id', widget.patientId)
      .execute();

  if (response.error == null) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account deleted successfully')),
    );

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  } else {
    print('Failed to delete account in patients: ${response.error?.message}');
  }
}
Future<void> _showDeleteAccountDialog() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: const Text('Are you sure you want to delete your account? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await deleteAccount(); // Call account deletion method
    }
  }
Future<void> _showChangePasswordDialog() async {
  final TextEditingController newPasswordController = TextEditingController();

  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: newPasswordController,
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
            child: const Text('Save'),
            onPressed: () async {
              if (!isConnectedToInternet) {
                showMessage("No internet connection.");
                return;
              }

              String newPassword = newPasswordController.text;
              await updatePassword(newPassword); // Викликаємо функцію для зміни пароля на сервері

              _loadUserData(); // Оновлюємо дані в SharedPreferences

              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed successfully')),
              );
            },
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
          ConnectionStatusWidget(isConnected: isConnectedToInternet),
          const SizedBox(width: 16),
          const MusicContextMenu(), 
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
                  backgroundImage: imagePath != null && imagePath!.startsWith('http')
                  ? NetworkImage(imagePath!) // Використовуємо зображення з Firebase
                  : AssetImage('assets/images/icon.jpg') as ImageProvider,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name.isNotEmpty ? name : 'No Name', // Show default text if no name
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                email.isNotEmpty ? email : 'No Email', // Show default text if no email
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
                onPressed: _showChangePasswordDialog, // Call change password dialog
                child: const Text('Change Password'),
              ),
              const SizedBox(height:16),
              ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewAppointmentsPage(patientId: widget.patientId, appointmentId: widget.appointmentId,),
      ),
    );
  },
  child: const Text('View Appointments'),
),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showLogoutDialog, // Call logout dialog
                child: const Text('Log out'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showDeleteAccountDialog, // Call delete account dialog
                child: const Text('Delete Account'),
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
              onPressed: () async {
                // Перевірка на наявність інтернету
                if (!isConnectedToInternet) {
                  showMessage ("No internet connection.");;
                  return;
                }
                setState(() {
                  name = nameController.text; // Update name
                  email = emailController.text; // Update email
                });
                await updateProfile(name, email); // Замість updateProfile(name, email, password)
                _loadUserData(); // Update locally in SharedPreferences
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
              },
            ),
          ],
        );
      },
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
