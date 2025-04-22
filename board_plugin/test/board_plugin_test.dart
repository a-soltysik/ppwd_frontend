import 'package:flutter_test/flutter_test.dart';
import 'package:board_plugin/board_plugin.dart';
import 'package:board_plugin/board_plugin_platform_interface.dart';
import 'package:board_plugin/board_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBoardPluginPlatform
    with MockPlatformInterfaceMixin
    implements BoardPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final BoardPluginPlatform initialPlatform = BoardPluginPlatform.instance;

  test('$MethodChannelBoardPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBoardPlugin>());
  });

  test('getPlatformVersion', () async {
    BoardPlugin boardPlugin = BoardPlugin();
    MockBoardPluginPlatform fakePlatform = MockBoardPluginPlatform();
    BoardPluginPlatform.instance = fakePlatform;

    expect(await boardPlugin.getPlatformVersion(), '42');
  });
}
