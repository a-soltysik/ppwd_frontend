import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class MacAddressTextField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;

  const MacAddressTextField({
    super.key,
    required this.controller,
    this.enabled = true,
  });

  @override
  State<MacAddressTextField> createState() => _MacAddressTextFieldState();
}

class _MacAddressTextFieldState extends State<MacAddressTextField> {
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _macSuggestions = [];

  @override
  void initState() {
    super.initState();
    _loadMacSuggestions();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showOverlay();
      } else {
        _removeOverlay();
      }
    });
  }

  Future<void> _loadMacSuggestions() async {
    final prefs = await SharedPreferences.getInstance();
    _macSuggestions = prefs.getStringList('mac_addresses') ?? [];
    if (mounted) setState(() {});
  }

  Future<void> _saveMacAddress(String mac) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> current = prefs.getStringList('mac_addresses') ?? [];
    if (!current.contains(mac)) {
      current.add(mac);
      await prefs.setStringList('mac_addresses', current);
      _loadMacSuggestions();
    }
  }

  Future<void> _deleteMacAddress(String mac) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> current = prefs.getStringList('mac_addresses') ?? [];
    current.remove(mac);
    await prefs.setStringList('mac_addresses', current);
    _loadMacSuggestions();
  }

  void _showOverlay() {
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;
    Offset offset = renderBox.localToGlobal(Offset.zero);

    return OverlayEntry(
      builder:
          (context) => Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0.0, size.height + 8.0),
              child: Material(
                elevation: 4.0,
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children:
                      _macSuggestions.map((mac) {
                        return Dismissible(
                          key: Key(mac),
                          direction: DismissDirection.horizontal,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) => _deleteMacAddress(mac),
                          child: ListTile(
                            title: Text(mac),
                            onTap: () {
                              widget.controller.text = mac;
                              _focusNode.unfocus();
                              _removeOverlay();
                            },
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Enter a MAC address of device',
          hintText: 'Format: XX:XX:XX:XX:XX:XX',
          prefixIcon: Icon(Icons.bluetooth),
          helperText: 'Colons will be added automatically',
        ),
        enabled: widget.enabled,
        inputFormatters: [
          MacAddressInputFormatter(),
          LengthLimitingTextInputFormatter(17),
        ],
        textCapitalization: TextCapitalization.characters,
        autocorrect: false,
        enableSuggestions: false,
        onFieldSubmitted: (value) async {
          await _saveMacAddress(value.toUpperCase());
          _focusNode.unfocus();
        },
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }
}
