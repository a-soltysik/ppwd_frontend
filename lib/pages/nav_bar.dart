import 'package:flutter/material.dart';
import 'package:ppwd_frontend/pages/graphs_page.dart';
import 'package:ppwd_frontend/pages/home_page.dart';

class NavBar extends StatefulWidget {
  const NavBar({super.key});

  @override
  NavBarState createState() => NavBarState();
}

class NavBarState extends State<NavBar> {
  final List<Widget> pages = [
    const GraphsPage(),
    const HomePage(), //conect to device
  ];

  int currentPage = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(index: currentPage, children: pages),
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: currentPage,
      onTap: (index) {
        setState(() {
          currentPage = index;
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.bluetooth),
          label: 'Connect to device',
        ),
      ],
    ),
  );
}
