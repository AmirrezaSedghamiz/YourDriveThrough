import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
import 'package:application/GlobalWidgets/ReusableComponents/AppBar.dart';
import 'package:application/GlobalWidgets/ReusableComponents/FlexSwitch.dart';
import 'package:application/Handlers/Repository/ManagerRepo.dart';
import 'package:application/Handlers/Repository/OrderRepo.dart';
import 'package:application/MainProgram/Manager/DashboardManager/DashboardManagerState.dart';
import 'package:application/MainProgram/Manager/DashboardManager/DashboardManagerViewModel.dart';
import 'package:application/MainProgram/Manager/HistoryOrders/HistoryOrders.dart';
import 'package:application/MainProgram/Manager/Menu/Menu.dart';
import 'package:application/MainProgram/Manager/OngoingOrders/OnGoingOrders.dart';
import 'package:application/MainProgram/Manager/PendingOrders/PendingOrders.dart';
import 'package:application/MockTester/MockOrder.dart';
import 'package:application/SourceDesign/Models/RestauarantInfo.dart';
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

  bool flexTest = false;

  RestaurantInfo? myRestaurant;

  Future<void> getRestaurant() async {
    myRestaurant = await ManagerRepo().getRestaurantProfile();
    flexTest = myRestaurant?.isOpen ?? false;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getRestaurant();
    _pageController = PageController(initialPage: widget.initialPage);
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
        appBar: myRestaurant == null
            ? AppAppBar(
                leading: const SizedBox(),
                title: const AppBarShimmerContent(),
                subtitle: const SizedBox(),
                trailing: const SizedBox(),
                elevation: 2,
              )
            : AppAppBar(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_none,
                    color: Colors.white,
                  ),
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
                      key: ValueKey(titleText),
                      style: textTheme.bodyLarge,
                    ),
                  ),
                ),
                subtitle: Text(
                  myRestaurant?.name ?? "......",
                  style: textTheme.bodyMedium,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      flexTest ? "Open" : "Closed",
                      style: textTheme.bodyMedium,
                    ),
                    SizedBox(width: 16),
                    FlexSwitch(
                      value: flexTest,
                      onChanged: (value) {
                        setState(() {
                          flexTest = value;
                        });
                        ManagerRepo().updateIsOpen(isOpen: value);
                      },
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
              onAccept: (order) => OrderRepo().updateStatus(newStatus: 'accepted', orderId: order.id),
              onDecline: (order) => OrderRepo().updateStatus(newStatus: 'canceled', orderId: order.id),
              pageSize: 10,
              firstPageKey: 1,
            ),
            OnGoingOrdersPagedList(
              fetchPage: OrderRepo().getOrderList,
              onMarkReady: (order) => OrderRepo().updateStatus(newStatus: 'done', orderId: order.id),
              pageSize: 10,
              firstPageKey: 1,
            ),
            OrdersHistoryPagedList(fetchPage: OrderRepo().getOrderList),

            RestaurantSettings(
              restaurantId: myRestaurant?.id ?? -1,
              callback: getRestaurant,
            ),
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

class ShimmerBlock extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBlock({
    super.key,
    required this.width,
    required this.height,
    this.radius = 8,
  });

  @override
  State<ShimmerBlock> createState() => _ShimmerBlockState();
}

class _ShimmerBlockState extends State<ShimmerBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  Widget build(BuildContext context) {
    const baseColor = Color(0xFFE7E7E7);

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: baseColor),
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) {
                final dx = (_controller.value * 2) - 1;
                return Transform.translate(
                  offset: Offset(dx * 200, 0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0x00FFFFFF),
                          Color(0x55FFFFFF),
                          Color(0x00FFFFFF),
                        ],
                        stops: [0.25, 0.5, 0.75],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class AppBarShimmerContent extends StatelessWidget {
  const AppBarShimmerContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Leading placeholder
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        const SizedBox(width: 12),

        // Title + subtitle
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              ShimmerBlock(width: 140, height: 18),
              SizedBox(height: 6),
              ShimmerBlock(width: 100, height: 14),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Switch placeholder
        const ShimmerBlock(width: 70, height: 28, radius: 20),
      ],
    );
  }
}
