import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'board_plugin_method_channel.dart';

abstract class BoardPluginPlatform extends PlatformInterface {
  /// Constructs a BoardPluginPlatform.
  BoardPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static BoardPluginPlatform _instance = MethodChannelBoardPlugin();

  /// The default instance of [BoardPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelBoardPlugin].
  static BoardPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BoardPluginPlatform] when
  /// they register themselves.
  static set instance(BoardPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
