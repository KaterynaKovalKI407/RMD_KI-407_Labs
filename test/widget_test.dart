import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:koval_ki407/main.dart';  // Замініть на ваш шлях до додатку

void main() {
  testWidgets('Перевірка наявності кнопки, тексту та поля вводу',
   (WidgetTester tester) async {
    // Запускаємо тестовий додаток
    await tester.pumpWidget(const MyApp());

    // Перевіряємо, чи є текст "Лічильник"
    expect(find.text('Лічильник: 0'), findsOneWidget);

    // Перевіряємо наявність поля вводу
    expect(find.byType(TextField), findsOneWidget);

    // Перевіряємо наявність кнопки
    expect(find.byType(ElevatedButton), findsOneWidget);

    // Перевіряємо введення тексту та натискання кнопки
    await tester.enterText(find.byType(TextField), '5');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Тепер лічильник має стати 5
    expect(find.text('Лічильник: 5'), findsOneWidget);

    // Тест на "Avada Kedavra"
    await tester.enterText(find.byType(TextField), 'Avada Kedavra');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    // Лічильник має скинутись до 0
    expect(find.text('Лічильник: 0'), findsOneWidget);
  });
}
