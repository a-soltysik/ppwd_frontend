import 'package:flutter/material.dart';

class ScanningTips extends StatelessWidget {
  const ScanningTips({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Tips:", style: TextStyle(fontWeight: FontWeight.bold)),
          Text("• Make sure your device is powered on"),
          Text("• Keep your device within range (1-2 meters)"),
          Text("• Using MAC address is the most reliable method"),
          Text("• Fully charged devices connect more reliably"),
        ],
      ),
    );
  }
}
