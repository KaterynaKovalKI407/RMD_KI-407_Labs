// Flutter web plugin registrant file.
//
// Generated file. Do not edit.
//

// @dart = 2.13
// ignore_for_file: type=lint

import 'package:audioplayers_web/audioplayers_web.dart';
import 'package:autologin_web/autologin_web.dart';
import 'package:connectivity_plus/src/connectivity_plus_web.dart';
import 'package:firebase_core_web/firebase_core_web.dart';
import 'package:firebase_storage_web/firebase_storage_web.dart';
import 'package:image_picker_for_web/image_picker_for_web.dart';
import 'package:shared_preferences_web/shared_preferences_web.dart';
import 'package:uni_links_web/uni_links_web.dart';
import 'package:url_launcher_web/url_launcher_web.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void registerPlugins([final Registrar? pluginRegistrar]) {
  final Registrar registrar = pluginRegistrar ?? webPluginRegistrar;
  AudioplayersPlugin.registerWith(registrar);
  AutologinWeb.registerWith(registrar);
  ConnectivityPlusWebPlugin.registerWith(registrar);
  FirebaseCoreWeb.registerWith(registrar);
  FirebaseStorageWeb.registerWith(registrar);
  ImagePickerPlugin.registerWith(registrar);
  SharedPreferencesPlugin.registerWith(registrar);
  UniLinksPlugin.registerWith(registrar);
  UrlLauncherPlugin.registerWith(registrar);
  registrar.registerMessageHandler();
}
