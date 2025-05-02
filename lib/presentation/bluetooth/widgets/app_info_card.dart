import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AppInfoCard extends StatelessWidget {
  const AppInfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  "App Information",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.left,
              text: TextSpan(
                style: TextStyle(color: AppTheme.textPrimaryColor),
                children: [
                  TextSpan(
                    text:
                        "Don't ever, for any reason, ever, no matter what,\n"
                        "no matter where, or who, or who you are with\n"
                        "or where you are going, or where you've been, ever, for any reason whatsoever,\n",
                  ),
                  TextSpan(
                    text: "do not kill this app in the task manager.",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
