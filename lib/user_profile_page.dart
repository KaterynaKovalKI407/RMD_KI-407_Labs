import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rmd_koval_ki407_lab2/main.dart'; 
import 'package:rmd_koval_ki407_lab2/globals.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';

class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

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

  @override
  void initState() {
    super.initState();
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
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('user_name') ?? ''; // Load name from prefs
      email = prefs.getString('user_email') ?? ''; // Load email from prefs
      password = prefs.getString('user_password') ?? ''; // Load password from prefs
      firebaseImageUrl = prefs.getString('user_image_url'); // Load URL from Firebase
      imagePath = prefs.getString('user_image'); // Load local image path
    });
  }

  Future<void> _updateUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setString('user_password', password);
    if (firebaseImageUrl != null) {
      await prefs.setString('user_image_url', firebaseImageUrl!); // Save image URL
    } else {
      await prefs.remove('user_image_url'); // Remove if null
    }
    if (imagePath != null) {
      await prefs.setString('user_image', imagePath!); // Save local image path
    } else {
      await prefs.remove('user_image'); // Remove if null
    }
  }

  Future<void> _changeProfilePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      String fileName = image.name;
      File imageFile = File(image.path);
      try {
        // Upload to Firebase Storage
        Reference storageRef = FirebaseStorage.instance.ref().child('profile_images/$fileName');
        await storageRef.putFile(imageFile);

        // Get image URL
        firebaseImageUrl = await storageRef.getDownloadURL();

        setState(() {
          imagePath = image.path; // Store local path
        });

        await _updateUserData(); // Save new image URL
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
      SharedPreferences prefs = await SharedPreferences.getInstance();
      loggedOut = true;
      await prefs.setBool('isLoggedIn', false);
      connectForInet = isConnectedToInternet;
      Navigator.pushReplacementNamed(context, '/login'); // Redirect to login page
    }
  }

  Future<void> _deleteAccount() async {
    try {
      // Delete profile image from Firebase Storage
      if (firebaseImageUrl != null) {
        final ref = FirebaseStorage.instance.refFromURL(firebaseImageUrl!);
        await ref.delete();
      }

      // Delete user data from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('user_password');
      await prefs.remove('user_image_url');
      await prefs.remove('user_image');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account deleted successfully')),
      );

      // Set loggedOut flag and navigate to login page
      loggedOut = true; // Ensure this is set
      await prefs.setBool('isLoggedIn', false);
      Navigator.pushReplacementNamed(context, '/login'); // Redirect to login page
    } catch (e) {
      print('Error deleting account: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete account')),
      );
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
      await _deleteAccount(); // Call account deletion method
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final TextEditingController passwordController = TextEditingController(text: password);

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
              child: const Text('Save'),
              onPressed: () async{
                // Перевірка на наявність інтернету
                if (!isConnectedToInternet) {
                  showMessage ("No internet connection.");;
                  return;
                }
                setState(() {
                  password = passwordController.text; // Update password
                });
                _updateUserData(); // Save updated password
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
        title: const Text('User Profile'),
        centerTitle: true,
        actions: [
          ConnectionStatusWidget(isConnected: isConnectedToInternet),
          const SizedBox(width: 16),
          const MusicContextMenu(), // Context menu on all pages
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
                      ? NetworkImage(firebaseImageUrl!) // Load image from Firebase
                      : const AssetImage('assets/images/icon.jpg') as ImageProvider,
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
                _updateUserData(); // Save updated name and email
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
