import 'package:path/path.dart' as p;
import 'package:tuple/tuple.dart';
import 'package:xpath_selector/xpath_selector.dart';
import 'package:requests/requests.dart';

import 'exceptions.dart';

abstract class CASClientBase {
  CASClientBase({
    required this.serviceUrl,
    required this.serverUrl,
    this.extraLoginParameters = const {},
    this.renew = false,
    this.usernameAttribute = '',
    this.verifySslCertificate = true,
  });

  // The service url
  final String serviceUrl;

  // The server url
  final String serverUrl;

  // Extra login parameters
  final Map<String, String> extraLoginParameters;

  // `true` if renewing session token
  final bool renew;

  // Custom username attribute for CAS_2_SAML_1_0
  final String usernameAttribute;

  // `true` if SSL certificate is to be verified
  final bool verifySslCertificate;

  // Default login redirect parameter name
  String loginRedirectParameterName = 'service';

  // Default logout redirect parameter name
  String logoutRedirectParameterName = 'service';

  /// Verifies the [ticket]
  ///
  /// * [ticket]: the ticket that will be verified
  ///
  /// Returns a [Tuple3] as ([String] username, [Object] attributes, [Object] proxyGrantingTicket)
  Future<Tuple3<String?, Object?, Object?>> verifyTicket(String ticket);

  /// Generates CAS login URL
  ///
  /// Returns a [String]
  String getLoginUrl() {
    String url = p.join(serverUrl, 'login');

    Map<String, String> parameters = {
      loginRedirectParameterName: serviceUrl,
    };
    String query = Uri(queryParameters: parameters).toString();

    return '$url$query';
  }

  /// Generates CAS logout URL
  ///
  /// * [redirectUrl]: Optional url where the request will be redirected to
  ///
  /// Returns a [String]
  String getLogoutUrl([String? redirectUrl]) {
    String url = p.join(serverUrl, 'logout');

    if (redirectUrl != null) {
      Map<String, String> parameters = {
        logoutRedirectParameterName: redirectUrl,
      };
      String query = Uri(queryParameters: parameters).toString();
      url = '$url$query';
    }

    return url;
  }

  /// Generates proxy URL given the [proxyGrantingTicket]
  ///
  /// * [proxyGrantingTicket]: The proxy granting ticket
  ///
  /// Returns a [String]
  String getProxyUrl(String proxyGrantingTicket) {
    String url = p.join(serverUrl, 'proxy');

    Map<String, String> parameters = {
      'pgt': proxyGrantingTicket,
      'targetService': serviceUrl,
    };
    String query = Uri(queryParameters: parameters).toString();

    return '$url$query';
  }

  /// Fetch the proxy ticket given by the [proxyGrantingTicket]
  ///
  /// * [proxyGrantingTicket]: The proxy granting ticket
  ///
  /// Returns a [String]
  ///
  /// Throws a [CASException] in case of a non 200 http code or a bad XML body.
  Future<String> getProxyTicket(String proxyGrantingTicket) async {
    var response = await Requests.get(
      getProxyUrl(proxyGrantingTicket),
      verify: verifySslCertificate,
    );

    if (response.statusCode == 200) {
      String content = response.content();
      var tickets = XPath.xml(content).query('//*[local-name()="proxyTicket"]').nodes;

      if (tickets.length == 1) {
        return tickets[0].text ?? '';
      }

      var errors = XPath.xml(content).query('//*[local-name()="authenticationFailure"]').nodes;

      if (errors.length == 1) {
        throw CASException('${errors[0].attributes["code"]}, ${errors[0].text ?? ""}');
      }
    }

    throw CASException('Bad http code ${response.statusCode}');
  }
}

/// CAS Client Version 1
class CASClientV1 extends CASClientBase {
  @override
  String logoutRedirectParamName = 'url';

  CASClientV1(
    serviceUrl,
    serverUrl,
  ) : super(serviceUrl: serviceUrl, serverUrl: serverUrl);

  /// Verifies CAS 1.0 authentication ticket.
  ///
  /// * [ticket]: the ticket that will be verified
  ///
  /// Returns username on success and null on failure.
  ///
  /// Throws a [CASException] in case of a non 200 http code
  @override
  Future<Tuple3<String?, Object?, Object?>> verifyTicket(String ticket) async {
    String url = p.join(serverUrl, 'validate');

    Map<String, String> parameters = {
      'ticket': ticket,
      'service': serviceUrl,
    };
    String query = Uri(queryParameters: parameters).toString();
    url = '$url$query';

    var response = await Requests.get(url, verify: verifySslCertificate);

    if (response.statusCode == 200) {
      List<String> spiltContent = response.content().split('\n');

      if (spiltContent.length >= 2 && spiltContent[0].trim() == 'yes') {
        return Tuple3(spiltContent[1].trim(), null, null);
      } else {
        return Tuple3(null, null, null);
      }
    }

    throw CASException('Bad http code ${response.statusCode}');
  }
}
