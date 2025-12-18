import 'package:flutter/material.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:water_quality/Screens/Graph.dart';
import 'package:water_quality/Screens/HomeScreen.dart';
import 'package:water_quality/Screens/Settings.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotchBottomBarController _controller = NotchBottomBarController(
    index: 0,
  );
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    Home(),
    SensorGraphScreen(),
    Settings()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: AnimatedNotchBottomBar(
        notchBottomBarController: _controller,
        bottomBarWidth: MediaQuery.of(context).size.width,
        showTopRadius: false,
        showBottomRadius: true,
        notchColor: Colors.green,
        showShadow: true,
        elevation: 0,
        showLabel: true,
        color: Colors.white,
        shadowElevation: 0,
        textAlign: TextAlign.center,
        itemLabelStyle: TextStyle(color: Colors.black),
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _controller.jumpTo(index);
        },
        bottomBarItems: const [
          BottomBarItem(
            inActiveItem: Icon(Icons.home, color: Colors.green),
            activeItem: Icon(Icons.home, color: Colors.white),
            itemLabel: 'Home',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.line_axis, color: Colors.green),
            activeItem: Icon(Icons.line_axis, color: Colors.white),
            itemLabel: 'Graph',
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.settings, color: Colors.green),
            activeItem: Icon(Icons.settings, color: Colors.white),
            itemLabel: 'Settings',
          ),
        ],
        kIconSize: 20,
        kBottomRadius: 30,
      ),
    );
  }
}
