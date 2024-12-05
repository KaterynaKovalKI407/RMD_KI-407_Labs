import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider with ChangeNotifier {
  bool _isConnected = true;
  late StreamSubscription<List<ConnectivityResult>> _subscription; // Зміна типу

  ConnectivityProvider() {
    _startMonitoring();
  }

  bool get isConnected => _isConnected;

  void _startMonitoring() {
    // Слухаємо зміни в стані підключення
    _subscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> resultList) {
      // Припускаємо, що resultList містить список, але ми беремо перший елемент
      final result = resultList.isNotEmpty ? resultList.first : ConnectivityResult.none;

      // Оновлюємо стан залежно від результату
      if (result == ConnectivityResult.none) {
        _isConnected = false;
      } else {
        _isConnected = true;
      }

      notifyListeners(); // Оповіщаємо слухачів
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
