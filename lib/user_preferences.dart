import 'package:shared_preferences/shared_preferences.dart';

class UserPreferences {
  final SharedPreferences _prefs;

  UserPreferences(this._prefs);

  Future<void> saveUser(String email, String password, [String? imagePath]) async {
    await _prefs.setString('user_email', email);
    await _prefs.setString('user_password', password);
    if (imagePath != null) {
      await _prefs.setString('user_image', imagePath);
    }
  }

  String? getUserEmail() {
    return _prefs.getString('user_email');
  }

  String? getUserPassword() {
    return _prefs.getString('user_password');
  }

  String? getUserImage() {
    return _prefs.getString('user_image');
  }
}
