import 'package:url_launcher/url_launcher.dart';

Future<bool> openUrlUniversal(String url, {bool newTab = false}) async {
  try {
    final uri = Uri.parse(url);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) {
      return await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
    return true;
  } catch (_) {
    return false;
  }
}
