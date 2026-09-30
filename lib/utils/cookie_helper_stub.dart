// Persistent storage implementation for non-web platforms (Android, iOS, Desktop)
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

final Map<String, String> _inMemoryCookies = {};
SharedPreferences? _prefs;

Future<void> initImpl() async {
  try {
    _prefs = await SharedPreferences.getInstance();
    final keys = _prefs?.getKeys() ?? {};
    for (final key in keys) {
      final val = _prefs?.getString(key);
      if (val != null) {
        _inMemoryCookies[key] = val;
      }
    }
  } catch (e) {
    debugPrint('Cookie storage initialization error: $e');
  }
}

void setCookieImpl(String name, String value, {int maxAgeSeconds = 604800}) {
  _inMemoryCookies[name] = value;
  if (_prefs != null) {
    _prefs!.setString(name, value);
  } else {
    // If setCookie is called before initImpl finishes, persist asynchronously
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      prefs.setString(name, value);
    }).catchError((_) {});
  }
}

String? getCookieImpl(String name) {
  // If in-memory cache has value, return it
  if (_inMemoryCookies.containsKey(name)) {
    return _inMemoryCookies[name];
  }
  // Fallback read from SharedPreferences instance if available
  if (_prefs != null && _prefs!.containsKey(name)) {
    final val = _prefs!.getString(name);
    if (val != null) {
      _inMemoryCookies[name] = val;
      return val;
    }
  }
  return null;
}

void removeCookieImpl(String name) {
  _inMemoryCookies.remove(name);
  if (_prefs != null) {
    _prefs!.remove(name);
  } else {
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
      prefs.remove(name);
    }).catchError((_) {});
  }
}
