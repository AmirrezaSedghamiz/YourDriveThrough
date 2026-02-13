import 'package:application/GlobalWidgets/InternetManager/ConnectionStates.dart';
import 'package:application/GlobalWidgets/InternetManager/HttpClient.dart';
import 'package:application/GlobalWidgets/InternetManager/InternetHandler.dart';
import 'package:application/Handlers/TokenHandler.dart';
import 'package:dio/dio.dart';

class CustomerRepo {
  Future<Response> _getRestaurantListRequest(Map<String, dynamic> kwargs) async {
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    return await HttpClient.instance.post(
      'restaurant/get_closest/',
      options: options,
      data: {
        'page_size': kwargs["pageSize"],
        'page': kwargs["pageIndex"],
        'longitude': kwargs["longitude"],
        'latitude': kwargs["latitude"],
      },
    );
  }

  Future<dynamic> _getRestaurantListHandler(Response response) async {
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

  Future<dynamic> _getRestaurantListKwargBuilder(Map<String, dynamic> kwargs) async {
    return handleErrors(kwargs, _getRestaurantListRequest, _getRestaurantListHandler);
  }

  Future<dynamic> getRestaurantList({
    required int pageSize,
    required int pageKey,
    required num longitude,
    required num latitude,
  }) {
    return _getRestaurantListKwargBuilder({
      'pageSize' : pageSize,
      'pageIndex' : pageKey,
      'longitude' : longitude.abs(),
      'latitude' : latitude.abs(),
    });
  }
}
