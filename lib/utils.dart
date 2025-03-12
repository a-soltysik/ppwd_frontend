// TODO: change after getting backend url
String get apiUrl => 'https://x.azurewebsites.net/';

String getMacAddress(int number) {
  return switch (number) {
    1 => "C1:74:71:F3:94:E0",
    2 => "CF:F6:45:22:49:A9",
    int() => "C1:74:71:F3:94:E0",
  };
}
