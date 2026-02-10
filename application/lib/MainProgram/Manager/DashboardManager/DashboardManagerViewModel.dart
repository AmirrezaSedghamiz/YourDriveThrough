import 'package:application/MainProgram/Manager/DashboardManager/DashboardManagerState.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardManagerViewModel extends Notifier<DashboardManagerState> {
  @override
  DashboardManagerState build() {
    return DashboardManagerState();
  }

  void toggleIsOpen() {
    state = state.copyWith(
      isOpen: !(state.isOpen)
    );
  }

  void togglePage(int page) {
    if (state.currentPage == page) return;
    state = state.copyWith(
      currentPage: page
    );
  }

}

final dashboardManagerViewModelProvider = NotifierProvider<DashboardManagerViewModel, DashboardManagerState>(
  () => DashboardManagerViewModel(),
);
