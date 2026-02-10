// ignore_for_file: public_member_api_docs, sort_constructors_first
class DashboardCustomerState {
  int currentPage;
  DashboardCustomerState({this.currentPage = 0});

  DashboardCustomerState copyWith({int? currentPage, bool? isOpen}) {
    return DashboardCustomerState(
      currentPage: currentPage ?? this.currentPage,
    );
  }
}
