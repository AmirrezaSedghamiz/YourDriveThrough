import 'dart:io';

import 'package:application/GlobalWidgets/InternetManager/ConnectionStates.dart';
import 'package:application/GlobalWidgets/InternetManager/HttpClient.dart';
import 'package:application/GlobalWidgets/InternetManager/InternetHandler.dart';
import 'package:application/Handlers/TokenHandler.dart';
import 'package:application/SourceDesign/Models/RestauarantInfo.dart';
import 'package:application/SourceDesign/Models/UserInfo.dart';
import 'package:dio/dio.dart';

class CustomerRepo {
  Future<Response> _getRestaurantListRequest(
    Map<String, dynamic> kwargs,
  ) async {
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
    if (response.statusCode == 200) {
      List<RestaurantInfo> restaurants = [];
      for (var i in response.data['results']) {
        restaurants.add(RestaurantInfo.fromMap(i));
      }
      return restaurants;
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

  Future<dynamic> _getRestaurantListKwargBuilder(
    Map<String, dynamic> kwargs,
  ) async {
    return handleErrors(
      kwargs,
      _getRestaurantListRequest,
      _getRestaurantListHandler,
    );
  }

  Future<dynamic> getRestaurantList({
    required int pageSize,
    required int pageKey,
    required num longitude,
    required num latitude,
  }) {
    return _getRestaurantListKwargBuilder({
      'pageSize': pageSize,
      'pageIndex': pageKey,
      'longitude': longitude.abs(),
      'latitude': latitude.abs(),
    });
  }
  //////////////////////////////////////////////

  Future<Response> _getRestaurantMenuRequest(
    Map<String, dynamic> kwargs,
  ) async {
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    return await HttpClient.instance.post(
      '"restaurants/menu/"',
      options: options,
      data: {'id': kwargs["restaurantId"]},
    );
  }

  Future<dynamic> _getRestaurantMenuHandler(Response response) async {
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

  Future<dynamic> _getRestaurantMenuKwargBuilder(
    Map<String, dynamic> kwargs,
  ) async {
    return handleErrors(
      kwargs,
      _getRestaurantMenuRequest,
      _getRestaurantMenuHandler,
    );
  }

  Future<dynamic> getRestaurantMenu({required int restaurantId}) {
    return _getRestaurantMenuKwargBuilder({'id': restaurantId});
  }

  /////////////////////////////
  Future<Response> _editProfileRequest(Map<String, dynamic> kwargs) async {
    String? fileName = kwargs['image']?.path.split('/').last;
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    var data;
    if (kwargs['image'] == null) {
      data = {'phone': kwargs['username']};
    } else {
      data = FormData.fromMap({
        "image": kwargs['image'] != null
            ? await MultipartFile.fromFile(
                kwargs['image'].path,
                filename: fileName,
              )
            : null,
        "phone": kwargs['username'],
      });
    }
    return await HttpClient.instance.post(
      'me/customer/profile/update/',
      options: options,
      data: data,
    );
  }

  Future<dynamic> _editProfileHandler(Response response) async {
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

  Future<dynamic> _editProfileKwargBuilder(Map<String, dynamic> kwargs) async {
    return handleErrors(kwargs, _editProfileRequest, _editProfileHandler);
  }

  Future<dynamic> editProfile({
    required String username,
    required File? image,
  }) {
    return _editProfileKwargBuilder({'image': image, 'username': username});
  }

  /////////////////////////////////
  Future<Response> _getProfileRequest(Map<String, dynamic> kwargs) async {
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    return await HttpClient.instance.get(
      'me/customer/profile/',
      options: options,
    );
  }

  Future<dynamic> _getProfileHandler(Response response) async {
    if (response.statusCode == 200) {
      return UserInfo.fromMap(response.data);
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

  Future<dynamic> _getProfileKwargBuilder(Map<String, dynamic> kwargs) async {
    return handleErrors(kwargs, _getProfileRequest, _getProfileHandler);
  }

  Future<dynamic> getProfile() {
    return _getProfileKwargBuilder({});
  }
  ///////////////////////////////////////////////////////////////////

  Future<Response> _getRestaurantListBySearchRequest(
    Map<String, dynamic> kwargs,
  ) async {
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    return await HttpClient.instance.post(
      'restaurants/search/',
      options: options,
      data: {
        'page_size': kwargs["pageSize"],
        'page': kwargs["pageIndex"],
        'query': kwargs["search"],
      },
    );
  }

  Future<dynamic> _getRestaurantListBySearchHandler(Response response) async {
    if (response.statusCode == 200) {
      List<RestaurantInfo> restaurants = [];
      for (var i in response.data['results']) {
        restaurants.add(RestaurantInfo.fromMap(i));
      }
      return restaurants;
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

  Future<dynamic> _getRestaurantListBySearchKwargBuilder(
    Map<String, dynamic> kwargs,
  ) async {
    return handleErrors(
      kwargs,
      _getRestaurantListBySearchRequest,
      _getRestaurantListBySearchHandler,
    );
  }

  Future<dynamic> getRestaurantListBySearch({
    required int pageSize,
    required int pageKey,
    required String query,
  }) {
    return _getRestaurantListBySearchKwargBuilder({
      'pageSize': pageSize,
      'pageIndex': pageKey,
      'search': query,
    });
  }
  ////////////////////////////////////////////
  
  Future<Response> _getRestaurantListWithTwoCooRRequest(
    Map<String, dynamic> kwargs,
  ) async {
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    return await HttpClient.instance.post(
      'restaurant/get_closest2/',
      options: options,
      data: {
        'page_size': kwargs["pageSize"],
        'page': kwargs["pageIndex"],
        'lon1': kwargs["longitude1"],
        'lat1': kwargs["latitude1"],
        'lon2': kwargs["longitude2"],
        'lat2': kwargs["latitude2"],
      },
    );
  }

  Future<dynamic> _getRestaurantListWithTwoCooRHandler(Response response) async {
    if (response.statusCode == 200) {
      List<RestaurantInfo> restaurants = [];
      for (var i in response.data['results']) {
        restaurants.add(RestaurantInfo.fromMap(i));
      }
      return restaurants;
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

  Future<dynamic> _getRestaurantListWithTwoCooRKwargBuilder(
    Map<String, dynamic> kwargs,
  ) async {
    return handleErrors(
      kwargs,
      _getRestaurantListWithTwoCooRRequest,
      _getRestaurantListWithTwoCooRHandler,
    );
  }

  Future<dynamic> getRestaurantListWithTwoCooR({
    required int pageSize,
    required int pageKey,
    required num longitude1,
    required num latitude1,
    required num longitude2,
    required num latitude2,
  }) {
    return _getRestaurantListWithTwoCooRKwargBuilder({
      'pageSize': pageSize,
      'pageIndex': pageKey,
      'longitude1': longitude1.abs(),
      'latitude1': latitude1.abs(),
      'longitude2': longitude2.abs(),
      'latitude2': latitude2.abs(),
    });
  }
}
