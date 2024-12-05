import 'package:flutter/material.dart';
import 'uv_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class UVProvider with ChangeNotifier {
  double _uvIndex = 0.0;
  double get uvIndex => _uvIndex;
  bool _isConnected = false;

  final UVService _uvService = UVService();

  Future<void> fetchUVIndex() async {
     // Перевірка підключення до інтернету
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print("Немає підключення до інтернету");
      
  try {
    _uvIndex = await _uvService.getUVIndex();
    print('Fetched UV Index: $_uvIndex');
    notifyListeners();
  } catch (error) {
    print("Error fetching UV Index: $error");
  }
}
}
}