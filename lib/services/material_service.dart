import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:build_check_app/main.dart';
import 'package:build_check_app/core/api_config.dart';
import 'package:build_check_app/core/proyecto_actual.dart';
import 'package:build_check_app/services/auth_header.dart';
import 'package:build_check_app/services/http_handler.dart';
import 'package:build_check_app/services/http_interceptor.dart';
import 'package:build_check_app/services/secure_storage.dart';
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
    final proyectoId = ProyectoActual.id;
    final url = proyectoId != null
        ? ApiConfig.alertasPorProyecto(proyectoId)
        : ApiConfig.alertas;

    final res = await HttpInterceptor.send(() async {
      return http.get(Uri.parse(url), headers: await AuthHeader.getHeaders());
    });

    if (res.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return [];
    }
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List raw = decoded is List ? decoded : (decoded['alertas'] ?? []);
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

    final url = proyectoId != null
        ? ApiConfig.materialesPorProyecto(proyectoId)
        : ApiConfig.materiales;

    final res = await HttpInterceptor.send(() async {
      return http.get(Uri.parse(url), headers: await AuthHeader.getHeaders());
    });

    if (res.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return {};
    }

    final Map<int, MaterialItem> nuevoMapa = {};
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final List raw = decoded is List
          ? decoded
          : (decoded['materiales'] ?? []);
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

    final response = await HttpInterceptor.send(() async {
      return http.post(
        Uri.parse(url),
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
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return MaterialItem.fromJson(data['material']);
    }
    return null;
  }

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
      final proyectoId = ProyectoActual.id;
      if (proyectoId != null) {
        request.headers["X-Proyecto-Id"] = proyectoId.toString();
      }
      request.fields.addAll(fields);

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
}
