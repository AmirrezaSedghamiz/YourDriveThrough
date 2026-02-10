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
    print(response.data["results"]);
    print(response.statusCode);
    if (response.statusCode == 200) {
      List<Order> orders = [];
      for (var i in response.data["results"]) {
        orders.add(Order.fromMap(i));
      }
      return {"orders" :orders, "isLastPage" : !(response.data["pagination"]["has_next"])};
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
}
