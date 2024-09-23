import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Магічний інтерфейс'),
        ),
        body: const Center(
          child: MagicIncrementor(),
        ),
      ),
    );
  }
}

class MagicIncrementor extends StatefulWidget {
  const MagicIncrementor({super.key});

  @override
  MagicIncrementorState createState() => MagicIncrementorState();
}

class MagicIncrementorState extends State<MagicIncrementor> {
  int _counter = 0;
  Color _backgroundColor = Colors.white;
  Color _textColor = Colors.black;
  double _textSize = 24;

  final TextEditingController _controller = TextEditingController();

  void _handleInput(String input) {
    setState(() {
      input = input.trim(); // Очищення від зайвих пробілів

      if (input == 'Avada Kedavra') {
        _counter = 0;
        _backgroundColor = Colors.red; // Робимо фон червоним
        _textColor = Colors.white;     // Текст білий
        _textSize = 32;              // Шрифт більший
      } else if (int.tryParse(input) != null) {
        // Якщо це число
        _counter += int.parse(input);
        _backgroundColor = Colors.green; // Якщо ввели число, фон стає зеленим
        _textColor = Colors.black;       // Текст чорний
        _textSize = 24;                // Шрифт стандартний
      } else {
        // Якщо введений текст
        _backgroundColor = Colors.blue;  // Якщо текст, фон стає синім
        _textColor = Colors.yellow;      // Текст жовтий
        _textSize = 28;                // Шрифт трохи більший
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _backgroundColor, // Колір фону змінюється
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Лічильник: $_counter',
            style: TextStyle(
              fontSize: _textSize, // Розмір тексту змінюється
              color: _textColor,   // Колір тексту змінюється
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Введіть текст або число',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              _handleInput(_controller.text);
              _controller.clear(); // Очищуємо поле вводу
            },
            child: const Text('Обробити введення'),
          ),
        ],
      ),
    );
  }
}
