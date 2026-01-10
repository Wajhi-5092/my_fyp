import 'dart:io';

Future<bool> hasInternet() async {
  try {
    print('Checking internet connectivity...');
    final result = await InternetAddress.lookup('google.com');
    return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
  } catch (_) {
    return false;

  }
}
