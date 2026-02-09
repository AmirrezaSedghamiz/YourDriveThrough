enum OrderStatus {
  pending, accepted, canceled, done, recieved, failed
}

extension OrderStatusParsing on OrderStatus {
  static OrderStatus fromString(String value) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => OrderStatus.failed,
    );
  }
}