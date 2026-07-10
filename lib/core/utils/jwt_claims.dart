import 'dart:convert';

/// Decodes the claims from a JWT token. Returns null if the token is invalid or the claims cannot be decoded.
Map<String, dynamic>? decodeJwtClaims(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    return jsonDecode(payload) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}