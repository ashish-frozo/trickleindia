import 'package:flutter_appauth/flutter_appauth.dart';

void captureAuthCallback() {}
Future<String?> organisationSignIn(Map<String, dynamic> config) async {
  final domain = Uri.parse(config['domain']);
  if (domain.scheme != 'https') throw StateError('HTTPS_REQUIRED');
  try {
    final response = await const FlutterAppAuth().authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        config['clientId'],
        'com.frozo.pop:/oauthredirect',
        serviceConfiguration: AuthorizationServiceConfiguration(
          authorizationEndpoint: domain.resolve('/oauth2/authorize').toString(),
          tokenEndpoint: domain.resolve('/oauth2/token').toString(),
        ),
        scopes: ['openid', 'profile', 'email'],
      ),
    );
    return response.accessToken;
  } on FlutterAppAuthUserCancelledException {
    return null;
  }
}
