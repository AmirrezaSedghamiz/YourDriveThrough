import 'dart:io';

import 'package:application/GlobalWidgets/InternetManager/ConnectionStates.dart';
import 'package:application/GlobalWidgets/InternetManager/HttpClient.dart';
import 'package:application/GlobalWidgets/InternetManager/InternetHandler.dart';
import 'package:application/Handlers/TokenHandler.dart';
import 'package:dio/dio.dart';

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
}
