import 'package:googleapis_auth/auth_io.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ServerKey {
  String _requiredEnv(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw StateError('Missing required .env value: $key');
    }
    return value;
  }

  Future<String> getServerKey() async {
    final scopes = [
      'https://www.googleapis.com/auth/userinfo.email',
      'https://www.googleapis.com/auth/firebase.database',
      'https://www.googleapis.com/auth/firebase.messaging',
    ];

    final projectId = _requiredEnv('FIREBASE_PROJECT_ID');
    final clientEmail = _requiredEnv('FIREBASE_SA_CLIENT_EMAIL');

    final client = await clientViaServiceAccount(
      ServiceAccountCredentials.fromJson({
        "type": _requiredEnv('FIREBASE_SA_TYPE'),
        "project_id": projectId,
        "private_key_id": _requiredEnv('FIREBASE_SA_PRIVATE_KEY_ID'),
        "private_key": _requiredEnv(
          'FIREBASE_SA_PRIVATE_KEY',
        ).replaceAll(r'\\n', '\n'),
        "client_email": clientEmail,
        "client_id": _requiredEnv('FIREBASE_SA_CLIENT_ID'),
        "auth_uri": _requiredEnv('FIREBASE_SA_AUTH_URI'),
        "token_uri": _requiredEnv('FIREBASE_SA_TOKEN_URI'),
        "auth_provider_x509_cert_url": _requiredEnv(
          'FIREBASE_SA_AUTH_PROVIDER_X509_CERT_URL',
        ),
        "client_x509_cert_url":
            dotenv.env['FIREBASE_SA_CLIENT_X509_CERT_URL'] ??
            'https://www.googleapis.com/robot/v1/metadata/x509/${Uri.encodeComponent(clientEmail)}',
        "universe_domain":
            dotenv.env['FIREBASE_SA_UNIVERSE_DOMAIN'] ?? 'googleapis.com',
      }),
      scopes,
    );

    final accessServerKey = client.credentials.accessToken.data;
    return accessServerKey;
  }
}
