// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

Future<bool> openUrlUniversal(String url, {bool newTab = false}) async {
  try {
    if (newTab) {
      html.window.open(url, '_blank');
    } else {
      // 🌟 সেম ট্যাবে স্মুথ রিডাইরেক্ট (কোনো নতুন ট্যাব খুলবে না!)
      html.window.location.href = url;
    }
    return true;
  } catch (_) {
    return false;
  }
}
