class ApiConfig {
  // ┌─────────────────────────────────────────────────────────────────┐
  // │  IMPORTANTE: cambia baseUrl según dónde ejecutes la app        │
  // │                                                                 │
  // │  Flutter Web (Edge/Chrome)  → http://localhost:8080/api        │
  // │  Emulador Android (AVD)     → http://10.0.2.2:8080/api        │
  // │  Dispositivo físico         → http://192.168.101.6:8080/api   │
  // └─────────────────────────────────────────────────────────────────┘
  // static const String baseUrl =
  //     'http://localhost:8080/api'; // ← WEB (Edge/Chrome)

  //static const String baseUrl =
  //     'http://192.168.1.4:8080/api'; // ← Emulador Android

  // static const String baseUrl =
  //     'http://192.168.80.13:8080/api'; // ← Dispositivo físico

  // static const String baseUrl =
  //     'https://paramount-sensitize-commuting.ngrok-free.dev/api'; // ← Dispositivo físico

  static const String baseUrl =
      'https://build-check-production.up.railway.app/api'; // ← Dispositivo físico

  static const String movimientos = '$baseUrl/movimientos-service/movimientos';
  static const String materiales = '$baseUrl/materiales-service/materiales';
  static const String facturas = '$baseUrl/facturas-service/facturas';
  static const String facturasOcr = '$baseUrl/facturas-service/ocr';
  static const String facturasWithImage =
      '$baseUrl/facturas-service/facturas/with-image';
  static String facturaImageUrl(int id) =>
      '$baseUrl/facturas-service/facturas/$id/image-url';
  static const String alertas = '$baseUrl/materiales-service/alertas';
  static const String usuarios = '$baseUrl/usuarios-service';
  static const String proyectos = '$baseUrl/proyecto-service/proyectos';

  // ── Endpoints filtrados por proyecto
  static String materialesPorProyecto(int id) =>
      '$baseUrl/materiales-service/proyecto/$id/materiales';
  static String movimientosPorProyecto(int id) =>
      '$baseUrl/movimientos-service/proyecto/$id/movimientos';
  static String facturasPorProyecto(int id) =>
      '$baseUrl/facturas-service/proyecto/$id/facturas';
  static String alertasPorProyecto(int id) =>
      '$baseUrl/materiales-service/proyecto/$id/alertas';
}
