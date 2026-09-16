import 'cookie_helper_stub.dart'
    if (dart.library.html) 'cookie_helper_web.dart' as helper;

class CookieHelper {
  /// Save a cookie with name and value.
  /// Defaults to 7 days max-age (604800 seconds).
  static void setCookie(String name, String value, {int maxAgeSeconds = 604800}) {
    helper.setCookieImpl(name, value, maxAgeSeconds: maxAgeSeconds);
  }

  /// Get the string value of a cookie by name.
  static String? getCookie(String name) {
    return helper.getCookieImpl(name);
  }

  /// Remove a cookie by setting its max-age to 0.
  static void removeCookie(String name) {
    helper.removeCookieImpl(name);
  }
}
