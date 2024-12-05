import 'dart:convert';
import 'package:http/http.dart' as http;

class UVService {
  final String apiKey = 'e4f5ac52cb5a4044b63e8b968cc4a462'; // Замініть на свій API ключ

  Future<double> getUVIndex() async {
    final url = 'https://api.weatherbit.io/v2.0/current?city=Lviv&key=$apiKey'; // Використовуйте apiKey
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['data'][0]['uv'] as num).toDouble(); // Витягуємо УФ-індекс
    } else {
      throw Exception('Помилка завантаження даних УФ-індексу');
    }
  }
}
