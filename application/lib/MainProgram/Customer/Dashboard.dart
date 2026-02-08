import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class Dashboard extends StatefulWidget {
  final int initialPage;
  const Dashboard({super.key, required this.initialPage});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  late final PageController _pageController;
  late int _selectedIndex;
  DateTime? _lastPressedTime; // Just track the last press time

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage);
    _selectedIndex = widget.initialPage;
  }

  void _onItemTapped(int index) {
    // Only rebuild if index actually changes
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<bool> _onWillPop() async {
    final currentTime = DateTime.now();

    if (_lastPressedTime == null ||
        currentTime.difference(_lastPressedTime!) >
            const Duration(seconds: 2)) {
      _lastPressedTime = currentTime;
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            // Only call setState if index actually changed
            if (_selectedIndex != index) {
              setState(() {
                _selectedIndex = index;
              });
            }
          },
          children: const [
            SizedBox(),
            SizedBox(),
            SizedBox(),
            SizedBox(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            boxShadow: [BoxShadow(color: Color(0x91656565), blurRadius: 6.5)],
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            items: _buildNavigationItems(),
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.metal,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.white,
          ),
        ),
      ),
    );
  }

  Icon _activeIcons(IconData iconData) {
    return Icon(iconData, color: AppColors.primary, size: 24);
  }

  Icon _deactiveIcons(IconData iconData) {
    return Icon(iconData, color: AppColors.coal, size: 24);
  }

  BottomNavigationBarItem _navigationBarIcons(IconData icon, String label) {
    return BottomNavigationBarItem(
      label: label,
      icon: _deactiveIcons(icon),
      activeIcon: _activeIcons(icon),
    );
  }

  List<BottomNavigationBarItem> _buildNavigationItems() {
    return [
      _navigationBarIcons(Icons.home, "home"),
      _navigationBarIcons(Icons.map, "map"),
      _navigationBarIcons(Icons.restaurant, "orders"),
      _navigationBarIcons(Icons.person, "profile"),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
