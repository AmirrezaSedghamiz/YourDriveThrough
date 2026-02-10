import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:application/GlobalWidgets/ReusableComponents/AppBar.dart';
import 'package:application/GlobalWidgets/ReusableComponents/FlexSwitch.dart';
import 'package:application/Handlers/Repository/OrderRepo.dart';
import 'package:application/MainProgram/Manager/DashboardManager/DashboardManagerState.dart';
import 'package:application/MainProgram/Manager/DashboardManager/DashboardManagerViewModel.dart';
import 'package:application/MainProgram/Manager/HistoryOrders/HistoryOrders.dart';
import 'package:application/MainProgram/Manager/OngoingOrders/OnGoingOrders.dart';
import 'package:application/MainProgram/Manager/PendingOrders/PendingOrders.dart';
import 'package:application/MockTester/MockOrder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';

class DashboardManager extends ConsumerStatefulWidget {
  final int initialPage;
  const DashboardManager({super.key, required this.initialPage});

  @override
  ConsumerState<DashboardManager> createState() => _DashboardManagerState();
}

class _DashboardManagerState extends ConsumerState<DashboardManager>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  DateTime? _lastPressedTime; // Just track the last press time

  //TESTER
  late final MockOrdersApi _api;
  bool flexTest = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage);
    _api = MockOrdersApi(totalPages: 4, pageSize: 10);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(dashboardManagerViewModelProvider.notifier)
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
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(dashboardManagerViewModelProvider);
    final viewModel = ref.read(dashboardManagerViewModelProvider.notifier);
    ref.listen<DashboardManagerState>(
      dashboardManagerViewModelProvider,
      (prev, next) {},
    );
    String titleText = state.currentPage == 0
        ? "Pending Orders"
        : state.currentPage == 1
        ? "Accepted Orders"
        : state.currentPage == 2
        ? "History"
        : "Settings";
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: AppAppBar(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.notifications_none, color: Colors.white),
          ),
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.2),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                titleText,
                key: ValueKey(titleText), // 👈 IMPORTANT
                style: textTheme.bodyLarge,
              ),
            ),
          ),
          subtitle: Text("FastBites Kitchen", style: textTheme.bodyMedium),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(flexTest ? "Open" : "Closed", style: textTheme.bodyMedium),
              SizedBox(width: 16),
              FlexSwitch(
                value: flexTest,
                onChanged: (value) => setState(() => flexTest = value),
                thumbColor: AppColors.lightGray,
                activeThumbColor: AppColors.lightGray,
                inactiveThumbColor: AppColors.lightGray,
                trackColor: AppColors.coal,
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.coal,
                thumbSize: 23.0,
                // Track properties
                trackHeight: 20.0,
                trackWidth: 40.0,
                // Animation
                animationDuration: const Duration(milliseconds: 200),
                splashRadius: 50.0,
                borderRadius: 20.0,
              ),
            ],
          ),
          elevation: 2,
        ),
        body: PageView(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          onPageChanged: (index) {
            viewModel.togglePage(index);
          },
          children: [
            PendingOrdersPagedList(
              fetchPage: OrderRepo().getOrderList,
              onAccept: (order) => _api.accept(order.id),
              onDecline: (order) => _api.decline(order.id),
              pageSize: 10,
              firstPageKey: 1,
            ),
            OnGoingOrdersPagedList(
              fetchPage: OrderRepo().getOrderList,
              onMarkReady: (order) => _api.accept(order.id),
              pageSize: 10,
              firstPageKey: 1,
            ),
            OrdersHistoryPagedList(
              fetchPage: OrderRepo().getOrderList,
            ),
             
             SizedBox(),
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
      _navigationBarIcons(Icons.notifications, "Pending"),
      _navigationBarIcons(Icons.check_circle_sharp, "Accepted"),
      _navigationBarIcons(Icons.history, "History"),
      _navigationBarIcons(Icons.settings, "Settings"),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
