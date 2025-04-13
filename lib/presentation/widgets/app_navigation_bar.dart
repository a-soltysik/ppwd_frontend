import 'package:flutter/material.dart';
import 'package:ppwd_frontend/presentation/pages/board_connection_page.dart';
import 'package:ppwd_frontend/presentation/pages/sensor_data_page.dart';

class AppNavigationBar extends StatefulWidget {
  const AppNavigationBar({super.key});

  @override
  AppNavigationBarState createState() => AppNavigationBarState();
}

class AppNavigationBarState extends State<AppNavigationBar> {
  final List<Widget> pages = [
    const BoardConnectionPage(),
    const SensorDataPage(),
  ];

  int currentPage = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: pages[currentPage],
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: currentPage,
      onTap: (value) {
        setState(() {
          currentPage = value;
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.bluetooth), label: 'Connect'),
        BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Graphs'),
      ],
    ),
  );
}
