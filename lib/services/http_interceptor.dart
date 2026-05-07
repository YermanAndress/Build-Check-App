import 'package:build_check_app/services/refresh_service.dart';
import 'package:build_check_app/services/secure_storage.dart';
import 'package:http/http.dart' as http;

class HttpInterceptor {
  static Future<http.Response> send(
    Future<http.Response> Function() request,
  ) async {
    http.Response res = await request();
    if (res.statusCode == 401) {
      bool refreshed = await RefreshService.refreshToken();
      if (!refreshed) {
        await SecureStorage.clear();
        return res;
      }
      res = await request();
      print("REFRESH RESPONSE: ${res.statusCode}");
    }
    return res;
  }
}
