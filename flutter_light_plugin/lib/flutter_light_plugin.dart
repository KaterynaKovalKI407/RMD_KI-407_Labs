// You have generated a new plugin project without specifying the `--platforms`
// flag. A plugin project with no platform support was generated. To add a
// platform, run `flutter create -t plugin --platforms <platforms> .` under the
// same directory. You can also find a detailed instruction on how to add
// platforms in the `pubspec.yaml` at
// https://flutter.dev/to/pubspec-plugin-platforms.

import 'flutter_light_plugin_platform_interface.dart';
import 'package:flutter/foundation.dart';

class FlutterLightPlugin {
  // Статичний метод для керування ліхтарем
  static Future<String?> onLight() async {
    // Викликає платформо-залежний код
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await FlutterLightPluginPlatform.instance.onLight();
    } else {
      // Для Android або інших платформ вивести попередження
      return Future.error('Torch is not supported on this platform');
    }
  }
static Future<String?> getPlatformVersion() async {
    return await FlutterLightPluginPlatform.instance.getPlatformVersion();
  }
}