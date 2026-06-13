import 'dart:io';

Future<bool> trainingHasInternetAccess() async {
  HttpClient? client;
  try {
    client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 3);
    final req = await client.getUrl(
      Uri.parse('https://connectivitycheck.gstatic.com/generate_204'),
    );
    final resp = await req.close().timeout(const Duration(seconds: 5));
    final ok = resp.statusCode == 204 || resp.statusCode == 200;
    return ok;
  } catch (_) {
    return false;
  } finally {
    client?.close(force: true);
  }
}
