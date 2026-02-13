import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:application/Handlers/Repository/OrderRepo.dart';
import 'package:application/MainProgram/Customer/DashboardCustomer/DashboardCustomerViewModel.dart';
import 'package:application/MainProgram/Customer/MainPage/MainPage.dart';
import 'package:application/MainProgram/Customer/OrderingPage/OrderingPage.dart';
import 'package:application/MainProgram/Customer/Profile/Profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class DashboardCustomer extends ConsumerStatefulWidget {
  final int initialPage;
  const DashboardCustomer({super.key, required this.initialPage});

  @override
  ConsumerState<DashboardCustomer> createState() => _DashboardCustomerState();
}

class _DashboardCustomerState extends ConsumerState<DashboardCustomer> {
  late final PageController _pageController;
  DateTime? _lastPressedTime; // Just track the last press time

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(dashboardCustomerViewModelProvider.notifier)
          .togglePage(widget.initialPage);
    });
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
    final state = ref.watch(dashboardCustomerViewModelProvider);
    final viewModel = ref.read(dashboardCustomerViewModelProvider.notifier);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.white,
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            viewModel.togglePage(index);
          },
          children: [
            CustomerHomePage(),
            const SizedBox(),
            UserOrderHistory(fetchPage: OrderRepo().getOrderList),
            ProfilePage()  
          ],
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            boxShadow: [BoxShadow(color: Color(0x91656565), blurRadius: 6.5)],
          ),
          child: BottomNavigationBar(
            currentIndex: state.currentPage,
            onTap: (index) {
              viewModel.togglePage(index);
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
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
      _navigationBarIcons(Icons.home, "Home"),
      _navigationBarIcons(Icons.map, "Map"),
      _navigationBarIcons(Icons.restaurant, "Orders"),
      _navigationBarIcons(Icons.person, "Profile"),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
