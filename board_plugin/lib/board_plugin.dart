
import 'board_plugin_platform_interface.dart';

class BoardPlugin {
  Future<String?> getPlatformVersion() {
    return BoardPluginPlatform.instance.getPlatformVersion();
  }
}
