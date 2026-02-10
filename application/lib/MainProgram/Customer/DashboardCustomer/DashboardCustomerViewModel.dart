import 'package:application/MainProgram/Customer/DashboardCustomer/DashboardCustomerState.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardCustomerViewModel extends Notifier<DashboardCustomerState> {
  @override
  DashboardCustomerState build() {
    return DashboardCustomerState();
  }

  void togglePage(int page) {
    if (state.currentPage == page) return;
    state = state.copyWith(
      currentPage: page
    );
  }

}

final dashboardCustomerViewModelProvider = NotifierProvider<DashboardCustomerViewModel, DashboardCustomerState>(
  () => DashboardCustomerViewModel(),
);
