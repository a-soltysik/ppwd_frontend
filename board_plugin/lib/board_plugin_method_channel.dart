import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'board_plugin_platform_interface.dart';

/// An implementation of [BoardPluginPlatform] that uses method channels.
class MethodChannelBoardPlugin extends BoardPluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('board_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
