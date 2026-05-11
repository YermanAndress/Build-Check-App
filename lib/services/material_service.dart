import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:build_check_app/main.dart';
import 'package:build_check_app/core/api_config.dart';
import 'package:build_check_app/core/proyecto_actual.dart';
import 'package:build_check_app/services/auth_header.dart';
import 'package:build_check_app/services/http_handler.dart';
<<<<<<< HEAD
import 'package:build_check_app/services/http_interceptor.dart';
import 'package:build_check_app/services/secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:build_check_app/core/api_config.dart';
=======
>>>>>>> d73e01d (BC-49 feature: Añadir flujo de usuarios)
import 'package:build_check_app/models/material_model.dart';

class MaterialService {
  static Map<int, MaterialItem>? _cacheMapaMateriales;
  static DateTime? _ultimaCarga;
  static int? _proyectoCacheado;

  static void invalidarCache() {
    _cacheMapaMateriales = null;
    _ultimaCarga = null;
    _proyectoCacheado = null;
  }

  Future<List<AlertaMaterial>> obtenerAlertas() async {
<<<<<<< HEAD
    final res = await HttpInterceptor.send(() async {
      return http.get(
        Uri.parse(ApiConfig.alertas),
        headers: await AuthHeader.getHeaders(),
      );
    });
=======
    final proyectoId = ProyectoActual.id;
    final url = proyectoId != null
        ? ApiConfig.alertasPorProyecto(proyectoId)
        : ApiConfig.alertas;

    final headers = await AuthHeader.getHeaders();
    final res = await http.get(Uri.parse(url), headers: headers);
>>>>>>> d73e01d (BC-49 feature: Añadir flujo de usuarios)
    if (res.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return [];
    }
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
<<<<<<< HEAD
      final List raw = decoded is List
          ? decoded
          : (decoded['alertas'] ?? [decoded]);
=======
      List raw = (decoded is List) ? decoded : (decoded['alertas'] ?? []);
>>>>>>> d73e01d (BC-49 feature: Añadir flujo de usuarios)
      return raw.map((e) => AlertaMaterial.fromJson(e)).toList();
    }
    throw Exception('Error al cargar alertas: ${res.statusCode}');
  }

  Future<Map<int, MaterialItem>> obtenerMapaMateriales({
    bool forzarRefresco = false,
  }) async {
    final proyectoId = ProyectoActual.id;

    if (_proyectoCacheado != proyectoId) invalidarCache();

    if (!forzarRefresco &&
        _cacheMapaMateriales != null &&
        _ultimaCarga != null) {
      if (DateTime.now().difference(_ultimaCarga!).inMinutes < 5) {
        return _cacheMapaMateriales!;
      }
    }
<<<<<<< HEAD
    final res = await HttpInterceptor.send(() async {
      return http.get(
        Uri.parse(ApiConfig.materiales),
        headers: await AuthHeader.getHeaders(),
      );
    });
=======

    final url = proyectoId != null
        ? ApiConfig.materialesPorProyecto(proyectoId)
        : ApiConfig.materiales;

    final headers = await AuthHeader.getHeaders();
    final res = await http.get(Uri.parse(url), headers: headers);

>>>>>>> d73e01d (BC-49 feature: Añadir flujo de usuarios)
    if (res.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return {};
    }
    final Map<int, MaterialItem> nuevoMapa = {};

    final Map<int, MaterialItem> nuevoMapa = {};
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      List raw = decoded is List ? decoded : (decoded['materiales'] ?? []);
      for (var item in raw) {
        final m = MaterialItem.fromJson(item);
        nuevoMapa[m.id] = m;
      }
      _cacheMapaMateriales = nuevoMapa;
      _ultimaCarga = DateTime.now();
      _proyectoCacheado = proyectoId;
    }
    return nuevoMapa;
  }

  Future<MaterialItem?> crearMaterial(
    String nombre,
    String unidad,
    double precio,
    double stock,
  ) async {
    final proyectoId = ProyectoActual.id;
    final url = proyectoId != null
        ? ApiConfig.materialesPorProyecto(proyectoId)
        : ApiConfig.materiales;

    final headers = await AuthHeader.getHeaders();
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode({
        'nombre': nombre,
        'unidadMedida': unidad,
        'precioUnitario': precio,
        'stockActual': stock,
      }),
    );
    if (response.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return null;
    }
    if (response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return MaterialItem.fromJson(data['material']);
    }
    return null;
  }

  Future<bool> registrarMovimiento(Map<String, dynamic> data) async {
<<<<<<< HEAD
    final res = await HttpInterceptor.send(() async {
      return http.post(
        Uri.parse(ApiConfig.movimientos),
        headers: await AuthHeader.getHeaders(),
        body: jsonEncode(data),
      );
    });

=======
    final headers = await AuthHeader.getHeaders();
    final res = await http.post(
      Uri.parse(ApiConfig.movimientos),
      headers: headers,
      body: jsonEncode(data),
    );
>>>>>>> d73e01d (BC-49 feature: Añadir flujo de usuarios)
    if (res.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return false;
    }
    return res.statusCode == 200 || res.statusCode == 201;
  }

  Future<bool> registrarFacturaMultipart(
    Map<String, String> fields,
    Uint8List? imageBytes,
  ) async {
<<<<<<< HEAD
    try {
      final token = await SecureStorage.read("accessToken");
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.facturas),
      );
      request.headers["Authorization"] = "Bearer $token";
      request.fields.addAll(fields);

      if (imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file', // Este nombre debe coincidir con el nodo "Binary Property" en n8n
            imageBytes,
            filename: 'factura_${DateTime.now().millisecondsSinceEpoch}.jpg',
          ),
        );
      }

      final streamedRes = await request.send();
      final res = await http.Response.fromStream(streamedRes);
      if (res.statusCode == 401) {
        await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
        return false;
      }
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
=======
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.facturas));
    request.fields.addAll(fields);
    request.headers["Authorization"] = "Bearer $token";
    if (imageBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          imageBytes,
          filename: 'factura_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
      );
    }
    final streamedRes = await request.send();
    if (streamedRes.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
>>>>>>> d73e01d (BC-49 feature: Añadir flujo de usuarios)
      return false;
    }
  }
<<<<<<< HEAD

  Future<MaterialItem?> crearMaterial(
    String nombre,
    String unidad,
    double precio,
    double stock,
  ) async {
    final response = await HttpInterceptor.send(() async {
      return http.post(
        Uri.parse(ApiConfig.materiales),
        headers: await AuthHeader.getHeaders(),
        body: jsonEncode({
          'nombre': nombre,
          'unidadMedida': unidad,
          'precioUnitario': precio,
          'stockActual': stock,
        }),
      );
    });

    if (response.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return null;
    }

    if (response.statusCode == 201) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return MaterialItem.fromJson(data['material']);
    }
    return null;
  }

  static void invalidateCache() {
    _cacheMapaMateriales = null;
    _ultimaCarga = null;
  }
=======
>>>>>>> d73e01d (BC-49 feature: Añadir flujo de usuarios)
}
