enum OrderStatus {
  pending,
  accepted,
  canceled,
  done,
  recieved,
  failed,
}

extension OrderStatusParsing on OrderStatus {
  static OrderStatus from(dynamic value) {
    if (value is OrderStatus) return value;

    // Backend sends index (int)
    if (value is int) {
      if (value >= 0 && value < OrderStatus.values.length) {
        return OrderStatus.values[value];
      }
      return OrderStatus.failed;
    }

    // Backend sends string
    if (value is String) {
      return OrderStatus.values.firstWhere(
        (e) => e.name == value.toLowerCase(),
        orElse: () => OrderStatus.failed,
      );
    }

    return OrderStatus.failed;
  }
}
