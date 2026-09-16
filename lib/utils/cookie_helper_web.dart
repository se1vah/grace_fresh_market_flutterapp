// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void setCookieImpl(String name, String value, {int maxAgeSeconds = 604800}) {
  final isSecure = html.window.location.protocol == 'https:';
  final secureFlag = isSecure ? '; Secure' : '';
  final encodedValue = Uri.encodeComponent(value);
  html.document.cookie =
      '$name=$encodedValue; path=/; max-age=$maxAgeSeconds; SameSite=Lax$secureFlag';
}

String? getCookieImpl(String name) {
  final cookieString = html.document.cookie;
  if (cookieString == null || cookieString.isEmpty) return null;
  final cookies = cookieString.split(';');
  for (var cookie in cookies) {
    final parts = cookie.trim().split('=');
    if (parts.length >= 2 && parts[0] == name) {
      final rawVal = parts.sublist(1).join('=');
      try {
        return Uri.decodeComponent(rawVal);
      } catch (_) {
        return rawVal;
      }
    }
  }
  return null;
}

void removeCookieImpl(String name) {
  html.document.cookie = '$name=; path=/; max-age=0; SameSite=Lax';
}
