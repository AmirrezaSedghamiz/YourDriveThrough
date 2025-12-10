import 'dart:io';

import 'package:application/GlobalWidgets/AnimationNavigation.dart';
import 'package:application/GlobalWidgets/Colors.dart';
import 'package:application/GlobalWidgets/ConnectionStates.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

Future<dynamic> handleErrors(
    Map<String, dynamic> kwargArgs,
    Future<Response> Function(Map<String, dynamic> kwargs) request,
    Future<dynamic> Function(Response) responseHandler,
    BuildContext context) async {
  try {
    final response = await request(kwargArgs);
    final returnedValue = await responseHandler(response);
    if (returnedValue is ConnectionStates) {
      if (returnedValue == ConnectionStates.BadRequest) {
        show400BottomSheet(context, response.data["message"]);
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

void show400BottomSheet(BuildContext context, String message) {
  showModalBottomSheet(
    isDismissible: true,
    enableDrag: true,
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Container(
          margin: const EdgeInsets.only(bottom: 32),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  "assets/newIcons/warning.svg",
                  width: 36,
                  height: 36,
                  color: primaryColor,
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(5)),
                    child: Center(
                      child: Text(
                        "فهمیدم",
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium!
                            .copyWith(color: whiteColor),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ));
    },
  );
}
