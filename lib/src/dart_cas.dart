import 'package:path/path.dart' as p;
// import 'package:requests/requests.dart';

class CASException implements Exception {
  final String message;

  CASException(this.message);
}

class CASClientBase {
  final String serverUrl;

  CASClientBase(this.serverUrl);

  /// Generates CAS login URL
  String getLoginUrl(String serviceUrl) {
    String url = p.join(serverUrl, "login");

    Map<String, String> params = {"service": serviceUrl};
    String query = Uri(queryParameters: params).toString();

    return "$url$query";
  }

  /// Generates CAS logout URL
  String getLogoutUrl(String? redirectUrl) {
    String url = p.join(serverUrl, "logout");

    if (redirectUrl != null) {
      Map<String, String> params = {"url": redirectUrl};
      String query = Uri(queryParameters: params).toString();
      url = "$url$query";
    }

    return url;
  }
}
