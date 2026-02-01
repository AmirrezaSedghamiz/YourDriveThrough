// import 'package:application/GlobalWidgets/AppTheme/Colors.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_svg/svg.dart';

// class Dashboard extends StatefulWidget {
//   final int initialPage;

//   const Dashboard({super.key, required this.initialPage});
//   @override
//   _DashboardState createState() => _DashboardState();
// }

// class _DashboardState extends State<Dashboard> {
//   late final PageController _pageController;
//   late int _selectedIndex;

//   @override
//   void initState() {
//     _pageController = PageController(initialPage: widget.initialPage);
//     _selectedIndex = widget.initialPage;
//     super.initState();
//   }

//   void _onItemTapped(int index) {
//     setState(() {
//       _selectedIndex = index;
//       _pageController.animateToPage(
//         index,
//         duration: const Duration(milliseconds: 1),
//         curve: Curves.easeInOut,
//       );

//     });
//   }

//   bool _showExitPrompt = false;
//   DateTime? _lastPressedTime;
//   double _exitPromptOpacity = 0.0;

//   Future<bool> _onWillPop() async {
//     final currentTime = DateTime.now();
//     if (_lastPressedTime == null ||
//         currentTime.difference(_lastPressedTime!) >
//             const Duration(seconds: 2)) {
//       _lastPressedTime = currentTime;
//       setState(() {
//         _showExitPrompt = true;
//         _exitPromptOpacity = 1.0;
//       });

//       Future.delayed(const Duration(milliseconds: 2000), () {
//         setState(() {
//           _exitPromptOpacity = 0.0;
//         });

//         Future.delayed(const Duration(milliseconds: 300), () {
//           setState(() {
//             _showExitPrompt = false;
//           });
//         });
//       });

//       return Future.value(false);
//     }
//     return Future.value(true);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: _onWillPop,
//       child: Scaffold(
//         backgroundColor: const Color(0xFFFFFFFF),
//         // backgroundColor: const Color(0xFFFFFFFF),
//         resizeToAvoidBottomInset: true,
//         appBar: ekeepsAppBar(),
//         body: PageView(
//           controller: _pageController,
//           physics: const BouncingScrollPhysics(),
//           onPageChanged: (index) {
//             setState(() {
//               _selectedIndex = index;
//             });
//           },
//           children: [
//             const DashboardNotifications(),
//             DashboardEkeeps(),
//             DashboardFriends(),
//           ],
//         ),
//         bottomNavigationBar: Container(
//           decoration: const BoxDecoration(boxShadow: [
//             BoxShadow(color: Color(0x91656565), blurRadius: 6.5)
//           ]),
//           child: BottomNavigationBar(
//             currentIndex: _selectedIndex,
//             onTap: _onItemTapped,
//             items: [
//               BottomNavigationBarItem(
//                 icon: Stack(
//                   clipBehavior: Clip.none,
//                   children: [
//                     SvgPicture.asset(
//                       'assets/icons/notification.svg',
//                       width: 24,
//                       height: 24,
//                       color: AppColors.metal,
//                     ),
//                   ],
//                 ),
//                 activeIcon: Stack(
//                   clipBehavior: Clip.none,
//                   children: [
//                     SvgPicture.asset(
//                       'assets/icons/notification.svg',
//                       width: 24,
//                       height: 24,
//                       color: AppColors.primary,
//                     ),
//                   ],
//                 ),
//                 label: AppLocalizations.of(context).fa22,
//               ),
//               BottomNavigationBarItem(
//                 icon: SvgPicture.asset(
//                   'assets/icons/EkeepIcon.svg',
//                   width: 28,
//                   height: 28,
//                   color: AppColors.metal,
//                 ),
//                 activeIcon: SvgPicture.asset(
//                   'assets/icons/EkeepIcon.svg',
//                   width: 28,
//                   height: 28,
//                   color: AppColors.primary,
//                 ),
//                 label: AppLocalizations.of(context).fa23,
//               ),
//               BottomNavigationBarItem(
//                 icon: SvgPicture.asset(
//                   'assets/icons/Friends.svg',
//                   width: 28,
//                   height: 28,
//                   color: AppColors.metal,
//                 ),
//                 activeIcon: SvgPicture.asset(
//                   'assets/icons/Friends.svg',
//                   width: 28,
//                   height: 28,
//                   color: AppColors.primary,
//                 ),
//                 label: AppLocalizations.of(context).fa24,
//               ),
//             ],
//             selectedItemColor: AppColors.primary,
//             unselectedItemColor: AppColors.metal,
//             showUnselectedLabels: true,
//             type: BottomNavigationBarType.fixed,
//             backgroundColor: AppColors.white,
//           ),
//         ),
//       ),
//     );
//   }
// }

