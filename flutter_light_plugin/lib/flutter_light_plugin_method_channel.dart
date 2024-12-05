import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'flutter_light_plugin_platform_interface.dart';

/// An implementation of [FlutterLightPluginPlatform] that uses method channels.
class MethodChannelFlutterLightPlugin extends FlutterLightPluginPlatform {
  static const MethodChannel _channel =
      MethodChannel('flutter_light_plugin');

  @override
  Future<String?> onLight() async {
    // Відправка запиту до нативної частини на iOS
    final String? result = await _channel.invokeMethod('onLight');
    return result;
  }

  @override
  Future<String?> getPlatformVersion() async {
    // Отримання версії платформи
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
