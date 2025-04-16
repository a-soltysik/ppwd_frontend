import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    final prefs = await SharedPreferences.getInstance();
    bool inBackground = state != AppLifecycleState.resumed;
    await prefs.setBool('appInBackground', inBackground);
    print("App lifecycle changed: in background = $inBackground");
  }
}
