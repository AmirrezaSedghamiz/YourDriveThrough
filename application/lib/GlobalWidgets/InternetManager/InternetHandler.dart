import 'dart:io';

import 'package:application/GlobalWidgets/InternetManager/ConnectionStates.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<dynamic> handleErrors(
    Map<String, dynamic> kwargArgs,
    Future<Response> Function(Map<String, dynamic> kwargs) request,
    Future<dynamic> Function(Response) responseHandler) async {
  try {
    final response = await request(kwargArgs);
    final returnedValue = await responseHandler(response);
    if (returnedValue is ConnectionStates) {
      if (returnedValue == ConnectionStates.BadRequest) {
        // show400BottomSheet(context, response.data["message"]);
        // AnimationNavigation.navigatePush(Error400(message: response.data["message"],), context);
      } else if (returnedValue == ConnectionStates.DataBase) {
        // AnimationNavigation.navigatePush(const Error500(), context);
      } else if (returnedValue == ConnectionStates.BadGateWay) {
        // AnimationNavigation.navigatePopAllReplace(const Error502(), context);
      } else if (returnedValue == ConnectionStates.Unauthorized) {
        // AnimationNavigation.navigatePopAllReplace(const LoginPage1(), context);
      }
    }
    return returnedValue;
  } on DioException catch (e) {
    if (e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ConnectionStates.TimeOutError;
    } else if (e.type == DioExceptionType.unknown &&
        e.error is SocketException) {
      // AnimationNavigation.navigateReplace(const NoWifi(), context);
      return ConnectionStates.NoInternet;
    } else {
      print(e);
      return ConnectionStates.Unexpected;
    }
  } catch (e) {
    print(e);
    return ConnectionStates.Unexpected;
  }
}
