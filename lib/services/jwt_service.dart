import 'dart:convert';

class JwtService {
  static Map<String, dynamic>? decodeToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final payload = parts[1];

      final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      final paddingLength = (4 - (normalized.length % 4)) % 4;
      final padded = normalized + ('=' * paddingLength);

      final decoded = utf8.decode(base64.decode(padded));
      return jsonDecode(decoded);
    } catch (e) {
      return null;
    }
  }

  static int? getProyectoId(String token) {
    final payload = decodeToken(token);
    if (payload == null) return null;

    final proyectoId = payload['proyectoId'];
    if (proyectoId is int) return proyectoId;
    if (proyectoId is String) return int.tryParse(proyectoId);
    return null;
  }

  static String? getRolProyecto(String token) {
    final payload = decodeToken(token);
    return payload?['rolProyecto'];
  }

  static int? getUsuarioId(String token) {
    final payload = decodeToken(token);
    if (payload == null) return null;

    final usuarioId = payload['usuarioId'];
    if (usuarioId is int) return usuarioId;
    if (usuarioId is String) return int.tryParse(usuarioId);
    return null;
  }

  static String? getEmail(String token) {
    final payload = decodeToken(token);
    return payload?['sub'];
  }
}
