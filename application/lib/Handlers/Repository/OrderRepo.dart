import 'dart:io';

import 'package:application/GlobalWidgets/InternetManager/ConnectionStates.dart';
import 'package:application/GlobalWidgets/InternetManager/HttpClient.dart';
import 'package:application/GlobalWidgets/InternetManager/InternetHandler.dart';
import 'package:application/Handlers/TokenHandler.dart';
import 'package:application/SourceDesign/Models/Order.dart';
import 'package:dio/dio.dart';

class OrderRepo {
  Future<Response> _getOrderListRequest(Map<String, dynamic> kwargs) async {
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    return await HttpClient.instance.post(
      'me/orders/',
      options: options,
      data: {
        "page": kwargs["page_key"],
        "page_size": kwargs["page_size"],
        "statuses": kwargs["statuses"],
      },
    );
  }

  Future<dynamic> _getOrderListHandler(Response response) async {
    if (response.statusCode == 200) {
      List<Order> orders = [];
      for (var i in response.data["results"]) {
        orders.add(Order.fromMap(i));
      }
      return {
        "orders": orders,
        "isLastPage": !(response.data["pagination"]["has_next"]),
      };
    } else if (response.statusCode == 400) {
      return ConnectionStates.BadRequest;
    } else if (response.statusCode == 401) {
      return ConnectionStates.Unauthorized;
    } else if (response.statusCode == 404) {
      return ConnectionStates.TokenFailure;
    } else {
      if (response.statusCode == 500) {
        return ConnectionStates.DataBase;
      } else if (response.statusCode == 502) {
        return ConnectionStates.BadGateWay;
      } else if (response.statusCode == 504) {
        return ConnectionStates.GateWayTimeOut;
      } else {
        return ConnectionStates.Unexpected;
      }
    }
  }

  Future<dynamic> _getOrderListKwargBuilder(Map<String, dynamic> kwargs) async {
    return handleErrors(kwargs, _getOrderListRequest, _getOrderListHandler);
  }

  Future<dynamic> getOrderList({
    required int pageKey,
    required int pageSize,
    required List<String>? statuses,
  }) {
    return _getOrderListKwargBuilder({
      "page_size": pageSize,
      "page_key": pageKey,
      "statuses": statuses,
    });
  }

  //////////////////////////////////////////////////////////////////
  Future<Response> _getAllCategoriesRequest(Map<String, dynamic> kwargs) async {
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    return await HttpClient.instance.post('categories/', options: options);
  }

  Future<dynamic> _getAllCategoriesHandler(Response response) async {
    if (response.statusCode == 200) {
      List<Order> orders = [];
      for (var i in response.data["results"]) {
        orders.add(Order.fromMap(i));
      }
      return {
        "orders": orders,
        "isLastPage": !(response.data["pagination"]["has_next"]),
      };
    } else if (response.statusCode == 400) {
      return ConnectionStates.BadRequest;
    } else if (response.statusCode == 401) {
      return ConnectionStates.Unauthorized;
    } else if (response.statusCode == 404) {
      return ConnectionStates.TokenFailure;
    } else {
      if (response.statusCode == 500) {
        return ConnectionStates.DataBase;
      } else if (response.statusCode == 502) {
        return ConnectionStates.BadGateWay;
      } else if (response.statusCode == 504) {
        return ConnectionStates.GateWayTimeOut;
      } else {
        return ConnectionStates.Unexpected;
      }
    }
  }

  Future<dynamic> _getAllCategoriesKwargBuilder(
    Map<String, dynamic> kwargs,
  ) async {
    return handleErrors(
      kwargs,
      _getAllCategoriesRequest,
      _getAllCategoriesHandler,
    );
  }

  Future<dynamic> getAllCategories({
    required int pageKey,
    required int pageSize,
    required List<String>? statuses,
  }) {
    return _getAllCategoriesKwargBuilder({});
  }

  //////////////////////////////////////////////////////////////////
  Future<Response> _updateStatusRequest(Map<String, dynamic> kwargs) async {
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    return await HttpClient.instance.post(
      'me/orders/update_status/',
      options: options,
      data: {'new_status': kwargs['new_status'], 'order_id': kwargs['id']},
    );
  }

  Future<dynamic> _updateStatusHandler(Response response) async {
    print(response.data);
    print(response.statusCode);
    if (response.statusCode == 200) {
      return ConnectionStates.Success;
    } else if (response.statusCode == 400) {
      return ConnectionStates.BadRequest;
    } else if (response.statusCode == 401) {
      return ConnectionStates.Unauthorized;
    } else if (response.statusCode == 404) {
      return ConnectionStates.TokenFailure;
    } else {
      if (response.statusCode == 500) {
        return ConnectionStates.DataBase;
      } else if (response.statusCode == 502) {
        return ConnectionStates.BadGateWay;
      } else if (response.statusCode == 504) {
        return ConnectionStates.GateWayTimeOut;
      } else {
        return ConnectionStates.Unexpected;
      }
    }
  }

  Future<dynamic> _updateStatusKwargBuilder(Map<String, dynamic> kwargs) async {
    return handleErrors(kwargs, _updateStatusRequest, _updateStatusHandler);
  }

  Future<dynamic> updateStatus({
    required String newStatus,
    required int orderId,
  }) {
    return _updateStatusKwargBuilder({'id': orderId, 'new_status': newStatus});
  }
  ///////////////////////////////////////////////

  Future<Response> _rateOrderRequest(Map<String, dynamic> kwargs) async {
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    return await HttpClient.instance.post(
      'me/ratings/',
      options: options,
      data: {'number': kwargs['rate'], 'order': kwargs['id']},
    );
  }

  Future<dynamic> _rateOrderHandler(Response response) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ConnectionStates.Success;
    } else if (response.statusCode == 400) {
      return ConnectionStates.BadRequest;
    } else if (response.statusCode == 401) {
      return ConnectionStates.Unauthorized;
    } else if (response.statusCode == 404) {
      return ConnectionStates.TokenFailure;
    } else {
      if (response.statusCode == 500) {
        return ConnectionStates.DataBase;
      } else if (response.statusCode == 502) {
        return ConnectionStates.BadGateWay;
      } else if (response.statusCode == 504) {
        return ConnectionStates.GateWayTimeOut;
      } else {
        return ConnectionStates.Unexpected;
      }
    }
  }

  Future<dynamic> _rateOrderKwargBuilder(Map<String, dynamic> kwargs) async {
    return handleErrors(kwargs, _rateOrderRequest, _rateOrderHandler);
  }

  Future<dynamic> rateOrder({required int orderId, required int rate}) {
    return _rateOrderKwargBuilder({'id': orderId, 'rate': rate});
  }

  //////////////////////////////////////////////////////
  Future<Response> _orderItemsRequest(Map<String, dynamic> kwargs) async {
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    return await HttpClient.instance.post(
      'me/orders/create/',
      options: options,
      data: {
        'restaurant': kwargs['restaurant'],
        'longitude': kwargs['longitude'],
        'latitude': kwargs['latitude'],
        'items': kwargs['items'],
      },
    );
  }

  Future<dynamic> _orderItemsHandler(Response response) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ConnectionStates.Success;
    } else if (response.statusCode == 400) {
      return ConnectionStates.BadRequest;
    } else if (response.statusCode == 401) {
      return ConnectionStates.Unauthorized;
    } else if (response.statusCode == 404) {
      return ConnectionStates.TokenFailure;
    } else {
      if (response.statusCode == 500) {
        return ConnectionStates.DataBase;
      } else if (response.statusCode == 502) {
        return ConnectionStates.BadGateWay;
      } else if (response.statusCode == 504) {
        return ConnectionStates.GateWayTimeOut;
      } else {
        return ConnectionStates.Unexpected;
      }
    }
  }

  Future<dynamic> _orderItemsKwargBuilder(Map<String, dynamic> kwargs) async {
    return handleErrors(kwargs, _orderItemsRequest, _orderItemsHandler);
  }

  Future<dynamic> orderItems({
    required int restaurantId,
    required num latitude,
    required num longitude,
    required List<Map<int, int>> items,
  }) {
    List<Map<String, dynamic>> item = [];
    for (var i in items) {
      item.add({
        "menu_item": i.keys.toList()[0],
        "quantity": i.values.toList()[0],
        'special': "",
      });
    }

    return _orderItemsKwargBuilder({
      'restaurant': restaurantId,
      'longitude': longitude,
      'latitude': latitude,
      'items': item,
    });
  }
  ////////////////////////////////////////////////////////

  Future<Response> _reOrderRequest(Map<String, dynamic> kwargs) async {
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    return await HttpClient.instance.post(
      'me/orders/reorder/',
      options: options,
      data: {
        'order_id': kwargs['id'],
        'longitude': kwargs['longitude'],
        'latitude': kwargs['latitude'],
      },
    );
  }

  Future<dynamic> _reOrderHandler(Response response) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Order.fromMap(response.data);
    } else if (response.statusCode == 400) {
      return ConnectionStates.BadRequest;
    } else if (response.statusCode == 401) {
      return ConnectionStates.Unauthorized;
    } else if (response.statusCode == 404) {
      return ConnectionStates.TokenFailure;
    } else {
      if (response.statusCode == 500) {
        return ConnectionStates.DataBase;
      } else if (response.statusCode == 502) {
        return ConnectionStates.BadGateWay;
      } else if (response.statusCode == 504) {
        return ConnectionStates.GateWayTimeOut;
      } else {
        return ConnectionStates.Unexpected;
      }
    }
  }

  Future<dynamic> _reOrderKwargBuilder(Map<String, dynamic> kwargs) async {
    return handleErrors(kwargs, _reOrderRequest, _reOrderHandler);
  }

  Future<dynamic> reOrder({
    required int orderId,
    required num latitude,
    required num longitude,
  }) {
    return _reOrderKwargBuilder({
      'id': orderId,
      'longitude': longitude,
      'latitude': latitude,
    });
  }
  //////////////////////////////////////////////////////

  Future<Response> _reportCustomerRequest(Map<String, dynamic> kwargs) async {
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    return await HttpClient.instance.post(
      'me/report/customer/',
      options: options,
      data: {'customer': kwargs['id'], 'description': kwargs['description']},
    );
  }

  Future<dynamic> _reportCustomerHandler(Response response) async {
    print(response.statusCode);
    print(response.data);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ConnectionStates.Success;
    } else if (response.statusCode == 400) {
      return ConnectionStates.BadRequest;
    } else if (response.statusCode == 401) {
      return ConnectionStates.Unauthorized;
    } else if (response.statusCode == 404) {
      return ConnectionStates.TokenFailure;
    } else {
      if (response.statusCode == 500) {
        return ConnectionStates.DataBase;
      } else if (response.statusCode == 502) {
        return ConnectionStates.BadGateWay;
      } else if (response.statusCode == 504) {
        return ConnectionStates.GateWayTimeOut;
      } else {
        return ConnectionStates.Unexpected;
      }
    }
  }

  Future<dynamic> _reportCustomerKwargBuilder(
    Map<String, dynamic> kwargs,
  ) async {
    return handleErrors(kwargs, _reportCustomerRequest, _reportCustomerHandler);
  }

  Future<dynamic> reportCustomer({
    required int customerId,
    required String? description,
  }) {
    return _reportCustomerKwargBuilder({
      'id': customerId,
      'description': description,
    });
  }
  ////////////////////

  Future<Response> _reportRestaurantRequest(Map<String, dynamic> kwargs) async {
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    return await HttpClient.instance.post(
      'me/report/restaurant/',
      options: options,
      data: {'restaurant': kwargs['id'], 'description': kwargs['description']},
    );
  }

  Future<dynamic> _reportRestaurantHandler(Response response) async {
    print(response.statusCode);
    print(response.data);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return ConnectionStates.Success;
    } else if (response.statusCode == 400) {
      return ConnectionStates.BadRequest;
    } else if (response.statusCode == 401) {
      return ConnectionStates.Unauthorized;
    } else if (response.statusCode == 404) {
      return ConnectionStates.TokenFailure;
    } else {
      if (response.statusCode == 500) {
        return ConnectionStates.DataBase;
      } else if (response.statusCode == 502) {
        return ConnectionStates.BadGateWay;
      } else if (response.statusCode == 504) {
        return ConnectionStates.GateWayTimeOut;
      } else {
        return ConnectionStates.Unexpected;
      }
    }
  }

  Future<dynamic> _reportRestaurantKwargBuilder(
    Map<String, dynamic> kwargs,
  ) async {
    return handleErrors(
      kwargs,
      _reportRestaurantRequest,
      _reportRestaurantHandler,
    );
  }

  Future<dynamic> reportRestaurant({
    required int restaurantId,
    required String? description,
  }) {
    return _reportRestaurantKwargBuilder({
      'id': restaurantId,
      'description': description,
    });
  }
}
