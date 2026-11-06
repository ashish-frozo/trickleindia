import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

Uri? callback;
void captureAuthCallback() {
  callback = Uri.parse(web.window.location.href);
}

String randomToken() =>
    base64UrlEncode(List<int>.generate(32, (_) => Random.secure().nextInt(256)))
        .replaceAll('=', '');
Future<String?> organisationSignIn(Map<String, dynamic> config) async {
  final domain = Uri.parse(config['domain']),
      redirect = Uri.parse(config['redirectUri']);
  if (domain.scheme != 'https' ||
      redirect.scheme != 'https' ||
      redirect.origin != Uri.parse(web.window.location.href).origin) {
    throw StateError('INVALID_AUTH_CONFIG');
  }
  final params = callback?.queryParameters ?? <String, String>{};
  if (params.containsKey('error')) {
    callback = null;
    web.window.sessionStorage.removeItem('pop.oauth');
    throw StateError('SIGN_IN_CANCELLED');
  }
  if (params.containsKey('code')) {
    final saved = web.window.sessionStorage.getItem('pop.oauth');
    web.window.sessionStorage.removeItem('pop.oauth');
    callback = null;
    web.window.history.replaceState(null, '', redirect.toString());
    if (saved == null) throw StateError('INVALID_OAUTH_STATE');
    final pending = jsonDecode(saved) as Map;
    if (params['state'] != pending['state'] ||
        DateTime.now().millisecondsSinceEpoch - (pending['created'] as int) >
            600000 ||
        pending['redirect'] != redirect.toString() ||
        pending['clientId'] != config['clientId']) {
      throw StateError('INVALID_OAUTH_STATE');
    }
    final response = await http
        .post(
          domain.resolve('/oauth2/token'),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {
            'grant_type': 'authorization_code',
            'client_id': config['clientId'],
            'code': params['code']!,
            'redirect_uri': redirect.toString(),
            'code_verifier': pending['verifier'],
          },
        )
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) throw StateError('SIGN_IN_FAILED');
    return jsonDecode(response.body)['access_token'] as String;
  }
  final state = randomToken(), verifier = randomToken();
  final challenge = base64UrlEncode(sha256.convert(utf8.encode(verifier)).bytes)
      .replaceAll('=', '');
  web.window.sessionStorage.setItem(
    'pop.oauth',
    jsonEncode({
      'state': state,
      'verifier': verifier,
      'redirect': redirect.toString(),
      'clientId': config['clientId'],
      'created': DateTime.now().millisecondsSinceEpoch,
    }),
  );
  web.window.location.assign(
    domain
        .resolve('/oauth2/authorize')
        .replace(
          queryParameters: {
            'response_type': 'code',
            'client_id': config['clientId'],
            'redirect_uri': redirect.toString(),
            'scope': 'openid profile email',
            'state': state,
            'code_challenge': challenge,
            'code_challenge_method': 'S256',
          },
        )
        .toString(),
  );
  return null;
}
