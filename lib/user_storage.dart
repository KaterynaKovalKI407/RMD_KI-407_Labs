abstract class UserStorage {
  Future<void> saveUserData(String email, String password, String name);
  Future<Map<String, String>?> getUserData();
  Future<void> updateUserData(String email, String password, String name);
  Future<void> deleteUserData();
}
