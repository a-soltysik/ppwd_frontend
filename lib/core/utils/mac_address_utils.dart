import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MacAddressInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) {
      if (oldValue.selection.baseOffset > 0 &&
          oldValue.selection.baseOffset <= oldValue.text.length &&
          oldValue.selection.baseOffset - 1 < oldValue.text.length &&
          oldValue.text[oldValue.selection.baseOffset - 1] == ':') {
        final int colonPos = oldValue.selection.baseOffset - 1;
        if (colonPos > 0) {
          final newText =
              oldValue.text.substring(0, colonPos - 1) +
              oldValue.text.substring(colonPos + 1);
          return TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: colonPos - 1),
          );
        }
      }
      return newValue;
    }

    if (newValue.text.length == oldValue.text.length + 1 &&
        newValue.text.substring(
              newValue.selection.baseOffset - 1,
              newValue.selection.baseOffset,
            ) ==
            ':') {
      return oldValue;
    }

    String text = newValue.text.toUpperCase().replaceAll(
      RegExp(r'[^0-9A-F]'),
      '',
    );

    StringBuffer formatted = StringBuffer();
    int hexDigitCount = 0;

    int insertedChars = 0;
    int originalCursorPos = newValue.selection.baseOffset;
    int newCursorPos = 0;

    for (int i = 0; i < text.length && formatted.length < 17; i++) {
      if (hexDigitCount > 0 && hexDigitCount % 2 == 0 && hexDigitCount < 12) {
        formatted.write(':');
        if (insertedChars < originalCursorPos) {
          newCursorPos++;
        }
      }

      formatted.write(text[i]);
      hexDigitCount++;
      insertedChars++;

      if (insertedChars <= originalCursorPos) {
        newCursorPos++;
      }
    }

    if (hexDigitCount > 0 && hexDigitCount % 2 == 0 && hexDigitCount < 12) {
      formatted.write(':');
      if (insertedChars == originalCursorPos) {
        newCursorPos++;
      }
    }

    return TextEditingValue(
      text: formatted.toString(),
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }
}

class MacAddressTextField extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;

  const MacAddressTextField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Enter a MAC address of device',
        hintText: 'Format: XX:XX:XX:XX:XX:XX',
        prefixIcon: Icon(Icons.bluetooth),
        helperText: 'Colons will be added automatically',
      ),
      enabled: enabled,
      inputFormatters: [
        MacAddressInputFormatter(),
        LengthLimitingTextInputFormatter(17), // XX:XX:XX:XX:XX:XX = 17 chars
      ],
      textCapitalization: TextCapitalization.characters,
      autocorrect: false,
      enableSuggestions: false,
    );
  }
}
