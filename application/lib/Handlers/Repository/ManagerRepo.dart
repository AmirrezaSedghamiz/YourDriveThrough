import 'dart:convert';
import 'dart:io';

import 'package:application/GlobalWidgets/InternetManager/ConnectionStates.dart';
import 'package:application/GlobalWidgets/InternetManager/HttpClient.dart';
import 'package:application/GlobalWidgets/InternetManager/InternetHandler.dart';
import 'package:application/Handlers/TokenHandler.dart';
import 'package:application/SourceDesign/Models/Category.dart';
import 'package:application/SourceDesign/Models/RestauarantInfo.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

Future<void> saveDebugJson(dynamic data, String filename) async {
  try {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$filename.json');
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    await file.writeAsString(jsonString);
    print('=== FULL JSON SAVED TO: ${file.path} ===');
  } catch (e) {
    print('Error saving debug JSON: $e');
  }
}

class ManagerRepo {
  Future<Response> _fillRestaurantProfileRequest(
    Map<String, dynamic> kwargs,
  ) async {
    String? fileName = kwargs['image']?.path.split('/').last;
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    FormData data = FormData.fromMap({
      "image": kwargs['image'] != null
          ? await MultipartFile.fromFile(
              kwargs['image'].path,
              filename: fileName,
            )
          : null,
      "longitude": kwargs['longitude'],
      "latitude": kwargs['latitude'],
      "address": kwargs['address'],
      "name": kwargs['name'],
    });
    return await HttpClient.instance.post(
      'restaurant/complete_profile/',
      options: options,
      data: data,
    );
  }

  Future<dynamic> _fillRestaurantProfileHandler(Response response) async {
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

  Future<dynamic> _fillRestaurantProfileKwargBuilder(
    Map<String, dynamic> kwargs,
  ) async {
    return handleErrors(
      kwargs,
      _fillRestaurantProfileRequest,
      _fillRestaurantProfileHandler,
    );
  }

  Future<dynamic> fillRestaurantProfile({
    required String username,
    required num longitude,
    required num latitude,
    required File? image,
    required String address,
  }) {
    return _fillRestaurantProfileKwargBuilder({
      'name': username,
      'address': address,
      'longitude': longitude,
      'latitude': latitude,
      'image': image,
    });
  }
  ///////////////////////////////////////

  Future<Response> _getMenuRequest(Map<String, dynamic> kwargs) async {
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    return await HttpClient.instance.post(
      'restaurants/menu/',
      options: options,
      data: {'restaurant_id': kwargs['restaurantId']},
    );
  }

  Future<dynamic> _getMenuHandler(Response response) async {
    // await _saveDebugJson(response.data, 'menu');
    if (response.statusCode == 200) {
      return categoriesFromResponse(response.data);
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

  Future<dynamic> _getMenuKwargBuilder(Map<String, dynamic> kwargs) async {
    return handleErrors(kwargs, _getMenuRequest, _getMenuHandler);
  }

  Future<dynamic> getMenu({required int restaurantId}) {
    return _getMenuKwargBuilder({'restaurantId': restaurantId});
  }
  ///////////////////////////////////////

  Future<Response> _getRestaurantProfileRequest(
    Map<String, dynamic> kwargs,
  ) async {
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    return await HttpClient.instance.get('me/', options: options);
  }

  Future<dynamic> _getRestaurantProfileHandler(Response response) async {
    if (response.statusCode == 200) {
      return RestaurantInfo.fromMap(response.data['restaurant']);
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

  Future<dynamic> _getRestaurantProfileKwargBuilder(
    Map<String, dynamic> kwargs,
  ) async {
    return handleErrors(
      kwargs,
      _getRestaurantProfileRequest,
      _getRestaurantProfileHandler,
    );
  }

  Future<dynamic> getRestaurantProfile() {
    return _getRestaurantProfileKwargBuilder({});
  }

  ///////////////////////////////////////////////

  Future<Response> _updateIsOpenRequest(Map<String, dynamic> kwargs) async {
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    return await HttpClient.instance.patch(
      'me/restaurant/',
      options: options,
      data: {'is_open': kwargs["isOpen"]},
    );
  }

  Future<dynamic> _updateIsOpenHandler(Response response) async {
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

  Future<dynamic> _updateIsOpenKwargBuilder(Map<String, dynamic> kwargs) async {
    return handleErrors(kwargs, _updateIsOpenRequest, _updateIsOpenHandler);
  }

  Future<dynamic> updateIsOpen({required bool isOpen}) {
    return _updateIsOpenKwargBuilder({'isOpen': isOpen});
  }

  /////////////////////////////////
  Future<Response> _updateMenuRequest(Map<String, dynamic> kwargs) async {
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    return await HttpClient.instance.post(
      'me/menu/sync/',
      options: options,
      data: kwargs['payload'],
    );
  }

  Future<dynamic> _updateMenuHandler(Response response) async {
    print(response.data);
    print(response.statusCode);
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

  Future<dynamic> _updateMenuKwargBuilder(Map<String, dynamic> kwargs) async {
    return handleErrors(kwargs, _updateMenuRequest, _updateMenuHandler);
  }

  Future<dynamic> updateMenu({required dynamic payload}) {
    return _updateMenuKwargBuilder({'payload': payload});
  }
}
