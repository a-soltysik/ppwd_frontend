class FormatUtils {
  static String formatBatteryLevel(int level) {
    if (level < 0 || level > 100) {
      return "N/A";
    }
    return "$level%";
  }

  static bool isValidMacAddress(String mac) {
    if (mac.isEmpty) {
      return false;
    }

    if (mac.length != 17) {
      return false;
    }

    // Check that colons are in the right positions
    for (int i = 2; i < 17; i += 3) {
      if (mac[i] != ':') {
        return false;
      }
    }

    // Check that other characters are valid hex digits
    for (int i = 0; i < 17; i++) {
      if (i % 3 == 2) {
        continue; // Skip colons
      }

      if (!RegExp(r'[0-9A-Fa-f]').hasMatch(mac[i])) {
        return false;
      }
    }

    return true;
  }
}
