
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'uv_provider.dart';
//import 'uv_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class UVIndexWidget extends StatelessWidget {
  

  UVIndexWidget();

  @override
  Widget build(BuildContext context) {
    final uvProvider = Provider.of<UVProvider>(context);

    return FutureBuilder(
      future: Connectivity().checkConnectivity(), // Перевірка з'єднання
      builder: (context, connectivitySnapshot) {
        if (connectivitySnapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator(); // Показати індикатор завантаження під час перевірки з'єднання
        } else if (connectivitySnapshot.hasError || connectivitySnapshot.data == ConnectivityResult.none) {
          return Text('Немає підключення до інтернету', style: TextStyle(color: Colors.red, fontSize: 16));
        } else {
          // Якщо з'єднання є, завантажуємо УФ-індекс
          return FutureBuilder(
            future: uvProvider.fetchUVIndex(), // Виклик функції для отримання УФ-індексу
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator(); // Показати індикатор завантаження
              } else if (snapshot.hasError) {
                return Text('Error loading UV index', style: TextStyle(color: Colors.red, fontSize: 16));
              } else {
                // Перевіряємо, чи значення індексу отримано
                print('UV Index: ${uvProvider.uvIndex}');
                return Row(
                  children: [
                    Icon(Icons.wb_sunny, color: Colors.yellow, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'UV Index: ${uvProvider.uvIndex.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                );
              }
            },
          );
        }
      },
    );
}
}