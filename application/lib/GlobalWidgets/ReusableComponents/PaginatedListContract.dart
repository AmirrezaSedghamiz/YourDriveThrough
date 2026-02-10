class PageResult<T> {
  final List<T> items;
  final bool isLastPage;
  const PageResult({required this.items, required this.isLastPage});
}