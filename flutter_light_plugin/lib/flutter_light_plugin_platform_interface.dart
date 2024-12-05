import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_light_plugin_method_channel.dart';

abstract class FlutterLightPluginPlatform extends PlatformInterface {
   // Конструктор
  FlutterLightPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterLightPluginPlatform _instance = MethodChannelFlutterLightPlugin();

  // Одержання поточної реалізації плагіну
  static FlutterLightPluginPlatform get instance => _instance;

  // Оголошення методу для керування ліхтарем
  Future<String?> onLight();

  // Оголошення методу для отримання версії платформи
  Future<String?> getPlatformVersion();
}
