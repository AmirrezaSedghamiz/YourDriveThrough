import 'package:dio/dio.dart';

class HttpClient {
  static Dio reverseGeoCoding = Dio(BaseOptions(baseUrl: "https://api.neshan.org/v5/"));
  static Dio searchGeo = Dio(BaseOptions(baseUrl: "https://api.neshan.org/v1/"));
  static Dio geoCoding = Dio(BaseOptions(baseUrl: "https://api.neshan.org/v6/"));

  static final globalHeader = Options(
      followRedirects: false,
      validateStatus: (status) {
        return status! < 600;
      },
      headers: {'Api-Key': 'service.e0ef93427f3f47c1908fbf4ea4255d7f'});
      //Free 
}