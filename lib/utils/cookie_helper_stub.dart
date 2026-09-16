// Stub implementation for non-web platforms (in-memory cookie storage)
final Map<String, String> _inMemoryCookies = {};

void setCookieImpl(String name, String value, {int maxAgeSeconds = 604800}) {
  _inMemoryCookies[name] = value;
}

String? getCookieImpl(String name) {
  return _inMemoryCookies[name];
}

void removeCookieImpl(String name) {
  _inMemoryCookies.remove(name);
}
