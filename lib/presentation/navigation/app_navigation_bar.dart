import 'package:flutter/material.dart';
import 'package:ppwd_frontend/presentation/bluetooth/pages/board_connection_page.dart';
import 'package:ppwd_frontend/presentation/sensor_data/pages/sensor_data_page.dart';

import '../prediction/pages/prediction_page.dart';

class AppNavigationBar extends StatefulWidget {
  const AppNavigationBar({super.key});

  @override
  AppNavigationBarState createState() => AppNavigationBarState();
}

class AppNavigationBarState extends State<AppNavigationBar> {
  int currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getCurrentPage(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentPage,
        onTap: (value) => setState(() => currentPage = value),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth),
            label: 'Connect',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bakery_dining_sharp),
            label: 'Predictions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Graphs',
          ),
        ],
      ),
    );
  }

  Widget _getCurrentPage() {
    switch (currentPage) {
      case 0:
        return const BoardConnectionPage();
      case 1:
        return const PredictionPage();
      case 2:
        return const SensorDataPage();
      default:
        return const BoardConnectionPage();
    }
  }
}
