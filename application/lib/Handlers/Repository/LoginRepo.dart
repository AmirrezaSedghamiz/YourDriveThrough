import 'package:application/GlobalWidgets/InternetManager/ConnectionStates.dart';
import 'package:application/GlobalWidgets/InternetManager/HttpClient.dart';
import 'package:application/GlobalWidgets/InternetManager/InternetHandler.dart';
import 'package:application/Handlers/TokenHandler.dart';
import 'package:dio/dio.dart';

class LoginRepo {
  Future<Response> _loginUserRequest(Map<String, dynamic> kwargs) async {
    return await HttpClient.instance.post(
      'login/',
      options: HttpClient.globalHeader,
      data: {"phone": kwargs['phone'], "password": kwargs['password']},
    );
  }

  Future<dynamic> _loginUserHandler(Response response) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      await TokenStore.saveTokens(
        response.data["access_token"],
        response.data["refresh_token"],
      );
      print(response.data);
      return {
        "role": response.data["role"],
        "complete": response.data["profile_complete"] ?? true,
      };
    } else {
      if (response.statusCode == 400) {
        return ConnectionStates.BadRequest;
      } else if (response.statusCode == 401) {
        return ConnectionStates.Unauthorized;
      } else if (response.statusCode == 500) {
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

  Future<dynamic> _loginUserKwargBuilder(Map<String, dynamic> kwargs) async {
    return handleErrors(kwargs, _loginUserRequest, _loginUserHandler);
  }

  Future<dynamic> loginUser({
    required String phoneNumber,
    required String password,
  }) async {
    return _loginUserKwargBuilder({
      'phone': phoneNumber.trim(),
      "password": password,
    });
  }

  //////////////////////////////////////////////
  Future<Response> _signUpRequest(Map<String, dynamic> kwargs) async {
    return await HttpClient.instance.post(
      'signup/',
      options: HttpClient.globalHeader,
      data: {
        "phone": kwargs['phone'],
        "password": kwargs['password'],
        "role": kwargs['role'],
      },
    );
  }

  Future<dynamic> _signUpHandler(Response response) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      await TokenStore.saveTokens(
        response.data["access_token"],
        response.data["refresh_token"],
      );
      return ConnectionStates.Success;
    } else {
      if (response.statusCode == 400) {
        return ConnectionStates.BadRequest;
      } else if (response.statusCode == 401) {
        return ConnectionStates.Unauthorized;
      } else if (response.statusCode == 500) {
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

  Future<dynamic> _signUpKwargBuilder(Map<String, dynamic> kwargs) async {
    return handleErrors(kwargs, _signUpRequest, _signUpHandler);
  }

  Future<dynamic> signUp({
    required String phoneNumber,
    required String password,
    required String role,
  }) async {
    return _signUpKwargBuilder({
      'phone': phoneNumber.trim(),
      "password": password,
      "role": role,
    });
  }

  //////////////////////////////////////////////////////////
  Future<Response> _verifyTokenRequest(Map<String, dynamic> kwargs) async {
    print({"token": (await TokenStore.getAccessToken())?.replaceAll("Bearer ", "")});
    return await HttpClient.instanceWithoutVersion.post(
      'token/verify/',
      options: HttpClient.globalHeader,
      data: {
        "token":
            (await TokenStore.getAccessToken())?.replaceAll("Bearer ", ""),
      },
    );
  }

  Future<dynamic> _verifyTokenHandler(Response response) async {
    print(response.data);
    print(response.statusCode);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return true;
    } else {
      if (response.statusCode == 400) {
        return false;
      } else if (response.statusCode == 401) {
        return false;
      } else if (response.statusCode == 500) {
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

  Future<dynamic> _verifyTokenKwargBuilder(Map<String, dynamic> kwargs) async {
    return handleErrors(kwargs, _verifyTokenRequest, _verifyTokenHandler);
  }

  Future<dynamic> verifyToken() async {
    return _verifyTokenKwargBuilder({});
  }

  /////////////////////////
  Future<Response> _getRoleRequest(Map<String, dynamic> kwargs) async {
    Options options = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Authorization': await TokenStore.getAccessToken()},
    );
    return await HttpClient.instance.get(
      'me/auth/',
      options: options,
    );
  }

  Future<dynamic> _getRoleHandler(Response response) async {
    print(response.data);
    if (response.statusCode == 200) {
      return {
        "role": response.data["role"],
        "complete": response.data["profile_complete"] ?? true,
        "username": response.data['phone'],
      };
    } else {
      if (response.statusCode == 400) {
        return ConnectionStates.BadRequest;
      } else if (response.statusCode == 401) {
        return ConnectionStates.Unauthorized;
      } else if (response.statusCode == 500) {
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

  Future<dynamic> _getRoleKwargBuilder(Map<String, dynamic> kwargs) async {
    return handleErrors(kwargs, _getRoleRequest, _getRoleHandler);
  }

  Future<dynamic> getRole() async {
    return _getRoleKwargBuilder({});
  }
}
