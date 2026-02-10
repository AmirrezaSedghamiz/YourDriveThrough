// ignore_for_file: public_member_api_docs, sort_constructors_first
class DashboardManagerState {
  int currentPage;
  bool isOpen;
  DashboardManagerState({this.currentPage = 0, this.isOpen = false});

  DashboardManagerState copyWith({int? currentPage, bool? isOpen}) {
    return DashboardManagerState(
      currentPage: currentPage ?? this.currentPage,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}
