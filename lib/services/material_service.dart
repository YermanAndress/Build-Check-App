import 'dart:convert';
import 'dart:typed_data';
import 'package:build_check_app/main.dart';
import 'package:build_check_app/services/auth_header.dart';
import 'package:build_check_app/services/http_handler.dart';
import 'package:build_check_app/services/http_interceptor.dart';
import 'package:build_check_app/services/secure_storage.dart';
import 'package:http/http.dart' as http;

import 'package:build_check_app/core/api_config.dart';
import 'package:build_check_app/models/material_model.dart';

class MaterialService {
  static Map<int, MaterialItem>? _cacheMapaMateriales;
  static DateTime? _ultimaCarga;

  // Obtener alertas de stock bajo
  Future<List<AlertaMaterial>> obtenerAlertas() async {
    final res = await HttpInterceptor.send(() async {
      return http.get(
        Uri.parse(ApiConfig.alertas),
        headers: await AuthHeader.getHeaders(),
      );
    });
    if (res.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return [];
    }
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List raw = decoded is List
          ? decoded
          : (decoded['alertas'] ?? [decoded]);
      return raw.map((e) => AlertaMaterial.fromJson(e)).toList();
    }
    throw Exception('Error al cargar alertas: ${res.statusCode}');
  }

  Future<Map<int, MaterialItem>> obtenerMapaMateriales({
    bool forzarRefresco = false,
  }) async {
    if (!forzarRefresco &&
        _cacheMapaMateriales != null &&
        _ultimaCarga != null) {
      final diferencia = DateTime.now().difference(_ultimaCarga!);
      if (diferencia.inMinutes < 5) return _cacheMapaMateriales!;
    }
    final res = await HttpInterceptor.send(() async {
      return http.get(
        Uri.parse(ApiConfig.materiales),
        headers: await AuthHeader.getHeaders(),
      );
    });
    if (res.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return {};
    }
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
    }
    return nuevoMapa;
  }

  // Registrar un nuevo movimiento
  Future<bool> registrarMovimiento(Map<String, dynamic> data) async {
    final res = await HttpInterceptor.send(() async {
      return http.post(
        Uri.parse(ApiConfig.movimientos),
        headers: await AuthHeader.getHeaders(),
        body: jsonEncode(data),
      );
    });

    if (res.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return false;
    }
    return res.statusCode == 200 || res.statusCode == 201;
  }

  // Registro de factura con imagen (Multipart)
  Future<bool> registrarFacturaMultipart(
    Map<String, String> fields,
    Uint8List? imageBytes,
  ) async {
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
      return false;
    }
  }

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
}
