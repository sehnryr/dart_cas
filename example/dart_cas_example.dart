import 'package:dart_cas/dart_cas.dart';

void main() {
  String serverUrl = "https://auth.isen-ouest.fr/cas";
  String serviceUrl =
      "https://web.isen-ouest.fr/webAurion//login/cas"; // pourquoi le double slash ??

  print(CASClientBase(serverUrl).getLoginUrl(serviceUrl));
  print(CASClientBase(serverUrl).getLogoutUrl(serviceUrl));
}
