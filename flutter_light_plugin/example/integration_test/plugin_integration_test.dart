import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_light_plugin/flutter_light_plugin.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion test', (WidgetTester tester) async {
    // Викликаємо статичний метод через клас
    final String? version = await FlutterLightPlugin.getPlatformVersion();
    
    // Перевіряємо, що версія платформи не порожня
    expect(version?.isNotEmpty, true);
  });
}