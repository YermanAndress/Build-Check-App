class ApiConfig {
  // ┌─────────────────────────────────────────────────────────────────┐
  // │  IMPORTANTE: cambia baseUrl según dónde ejecutes la app        │
  // │                                                                 │
  // │  Flutter Web (Edge/Chrome)  → http://localhost:8080/api        │
  // │  Emulador Android (AVD)     → http://10.0.2.2:8080/api        │
  // │  Dispositivo físico         → http://192.168.101.6:8080/api   │
  // └─────────────────────────────────────────────────────────────────┘
  static const String baseUrl =
      'http://localhost:8080/api'; // ← WEB (Edge/Chrome)

  // static const String baseUrl =
  //     'http://10.0.2.2:8080/api'; // ← Emulador Android

  // static const String baseUrl =
  //     'http://192.168.101.5:8080/api'; // ← Dispositivo físico

  static const String movimientos = '$baseUrl/movimientos-service/movimientos';
  static const String materiales = '$baseUrl/materiales-service/materiales';
  static const String facturas = '$baseUrl/facturas-service/facturas';
  static const String alertas = '$baseUrl/materiales-service/alertas';
  static const String usuarios = '$baseUrl/usuarios-service';
}
