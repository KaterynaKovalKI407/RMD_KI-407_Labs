import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_light_plugin/flutter_light_plugin.dart';
import 'package:flutter_light_plugin/flutter_light_plugin_platform_interface.dart';
import 'package:flutter_light_plugin/flutter_light_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterLightPluginPlatform
    with MockPlatformInterfaceMixin
    implements FlutterLightPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  // Реалізація методу onLight
  @override
  Future<String?> onLight() => Future.value('Torch toggled');
}

void main() {
  final FlutterLightPluginPlatform initialPlatform = FlutterLightPluginPlatform.instance;

  test('$MethodChannelFlutterLightPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelFlutterLightPlugin>());
  });

  test('getPlatformVersion', () async {
    MockFlutterLightPluginPlatform fakePlatform = MockFlutterLightPluginPlatform();

    // Викликаємо метод через клас
    expect(await FlutterLightPlugin.getPlatformVersion(), '42');
  });

  test('onLight', () async {
    MockFlutterLightPluginPlatform fakePlatform = MockFlutterLightPluginPlatform();

    // Викликаємо метод через клас
    expect(await FlutterLightPlugin.onLight(), 'Torch toggled');
  });
}