import 'dart:convert';
<<<<<<< HEAD
import 'package:build_check_app/main.dart';
import 'package:build_check_app/services/auth_header.dart';
import 'package:build_check_app/services/http_handler.dart';
import 'package:build_check_app/services/http_interceptor.dart';
import 'package:flutter/material.dart';
=======
>>>>>>> d73e01d (BC-49 feature: Añadir flujo de usuarios)
import 'package:http/http.dart' as http;

import 'package:build_check_app/main.dart';
import 'package:build_check_app/core/api_config.dart';
import 'package:build_check_app/core/proyecto_actual.dart';
import 'package:build_check_app/services/auth_header.dart';
import 'package:build_check_app/services/http_handler.dart';
import 'package:build_check_app/models/material_model.dart';
import 'package:build_check_app/models/movimiento_model.dart';

class MovimientoService {
<<<<<<< HEAD
  /// [soloHoy] = true  → filtra solo movimientos del día actual (comportamiento original)
  /// [soloHoy] = false → devuelve todo el historial
  Future<Map<String, dynamic>> obtenerStatsHoy({bool soloHoy = true}) async {
    try {
      final resMov = await HttpInterceptor.send(() async {
        return http.get(
          Uri.parse(ApiConfig.movimientos),
          headers: await AuthHeader.getHeaders(),
        );
      });
      final resMat = await HttpInterceptor.send(() async {
        return http.get(
          Uri.parse(ApiConfig.materiales),
          headers: await AuthHeader.getHeaders(),
        );
      });

      if (resMov.statusCode == 401 || resMat.statusCode == 401) {
        await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
        return {};
      }

      if (resMov.statusCode != 200) throw 'Error: ${resMov.statusCode}';

      List normalizar(dynamic data, String key) {
        if (data is List) return data;
        if (data is Map && data.containsKey(key)) return data[key] as List;
        return [data];
      }

      // Procesar materiales
      final Map<int, MaterialItem> matMap = {};
      if (resMat.statusCode == 200) {
        final decoded = jsonDecode(resMat.body);
        final rawMat = normalizar(decoded, 'materiales');
        for (var e in rawMat) {
          final m = MaterialItem.fromJson(e);
          matMap[m.id] = m;
        }
      }

      // Procesar movimientos
      final decodedMov = jsonDecode(resMov.body);
      final rawMov = normalizar(decodedMov, 'movimientos');
      final hoy = DateTime.now();

      final lista =
          rawMov
              .map((e) {
                final m = MovimientoResumen.fromJson(e);
                final mat = matMap[m.materialId];
                return mat != null
                    ? m.conMaterial(mat.nombre, mat.unidadMedida)
                    : m;
              })
              .where((m) {
                if (!soloHoy) return true; // Sin filtro → todo el historial
                return m.fecha.year == hoy.year &&
                    m.fecha.month == hoy.month &&
                    m.fecha.day == hoy.day;
              })
              .toList()
            ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

      return {
        'movimientos': lista,
        'totalMateriales': matMap.length,
        'entradasHoy': lista.where((m) => m.tipoMovimiento == 'ENTRADA').length,
        'salidasHoy': lista.where((m) => m.tipoMovimiento == 'SALIDA').length,
      };
    } catch (e) {
      debugPrint('DEBUG: Error en MovimientoService: $e');
      rethrow;
    }
  }

  /// Actualizar un movimiento existente — PUT /movimientos/{id}
  Future<bool> actualizarMovimiento(int id, Map<String, dynamic> data) async {
    try {
      final res = await HttpInterceptor.send(() async {
        return http.put(
          Uri.parse('${ApiConfig.movimientos}/$id'),
          headers: await AuthHeader.getHeaders(),
          body: jsonEncode(data),
        );
      });
=======
  static Map<int, MovimientoResumen>? _cacheMapaMovimientos;
  static DateTime? _ultimaCarga;
  static int? _proyectoCacheado;

  static void invalidarCache() {
    _cacheMapaMovimientos = null;
    _ultimaCarga = null;
    _proyectoCacheado = null;
  }

  Future<Map<int, MovimientoResumen>> obtenerMapaMovimientos({
    bool forzarRefresco = false,
  }) async {
    final proyectoId = ProyectoActual.id;
>>>>>>> d73e01d (BC-49 feature: Añadir flujo de usuarios)

    if (_proyectoCacheado != proyectoId) invalidarCache();

    if (!forzarRefresco &&
        _cacheMapaMovimientos != null &&
        _ultimaCarga != null) {
      if (DateTime.now().difference(_ultimaCarga!).inMinutes < 5) {
        return _cacheMapaMovimientos!;
      }
    }

    final url = proyectoId != null
        ? ApiConfig.movimientosPorProyecto(proyectoId)
        : ApiConfig.movimientos;

    final headers = await AuthHeader.getHeaders();
    final res = await http.get(Uri.parse(url), headers: headers);

    if (res.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return {};
    }

    if (res.statusCode != 200) {
      throw Exception('Error al cargar movimientos: ${res.statusCode}');
    }

    final decoded = jsonDecode(res.body);
    final rawMov = decoded is List
        ? decoded
        : (decoded['movimientos'] ?? [decoded]);

    final nuevoMapa = <int, MovimientoResumen>{};
    for (var e in rawMov) {
      final m = MovimientoResumen.fromJson(e);
      nuevoMapa[m.id] = m;
    }

    _cacheMapaMovimientos = nuevoMapa;
    _ultimaCarga = DateTime.now();
    _proyectoCacheado = proyectoId;

    return nuevoMapa;
  }

  Future<Map<String, dynamic>> obtenerStatsHoy({bool soloHoy = true}) async {
    final proyectoId = ProyectoActual.id;
    final urlMov = proyectoId != null
        ? ApiConfig.movimientosPorProyecto(proyectoId)
        : ApiConfig.movimientos;
    final urlMat = proyectoId != null
        ? ApiConfig.materialesPorProyecto(proyectoId)
        : ApiConfig.materiales;

    final headers = await AuthHeader.getHeaders();
    final responses = await Future.wait([
      http.get(Uri.parse(urlMov), headers: headers),
      http.get(Uri.parse(urlMat), headers: headers),
    ]);

    final resMov = responses[0];
    final resMat = responses[1];

    if (resMov.statusCode == 401 || resMat.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return {};
    }

    if (resMov.statusCode != 200) throw 'Error: ${resMov.statusCode}';

    List normalizar(dynamic data, String key) {
      if (data is List) return data;
      if (data is Map && data.containsKey(key)) return data[key] as List;
      return [data];
    }

    final Map<int, MaterialItem> matMap = {};
    if (resMat.statusCode == 200) {
      final decoded = jsonDecode(resMat.body);
      final rawMat = normalizar(decoded, 'materiales');
      for (var e in rawMat) {
        final m = MaterialItem.fromJson(e);
        matMap[m.id] = m;
      }
    }

    final decodedMov = jsonDecode(resMov.body);
    final rawMov = normalizar(decodedMov, 'movimientos');
    final hoy = DateTime.now();

    final lista =
        rawMov
            .map((e) {
              final m = MovimientoResumen.fromJson(e);
              final mat = matMap[m.materialId];
              return mat != null
                  ? m.conMaterial(mat.nombre, mat.unidadMedida)
                  : m;
            })
            .where((m) {
              if (!soloHoy) return true;
              return m.fecha.year == hoy.year &&
                  m.fecha.month == hoy.month &&
                  m.fecha.day == hoy.day;
            })
            .toList()
          ..sort((a, b) => b.fechaCreacion.compareTo(a.fechaCreacion));

    return {
      'movimientos': lista,
      'totalMateriales': matMap.length,
      'entradasHoy': lista.where((m) => m.tipoMovimiento == 'ENTRADA').length,
      'salidasHoy': lista.where((m) => m.tipoMovimiento == 'SALIDA').length,
    };
  }

  Future<bool> actualizarMovimiento(int id, Map<String, dynamic> data) async {
    final headers = await AuthHeader.getHeaders();
    final res = await http.put(
      Uri.parse('${ApiConfig.movimientos}/$id'),
      headers: headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 401) {
      await HttpHandler.handleUnauthorized(navigatorKey.currentContext!);
      return false;
    }
    return res.statusCode == 200;
  }
}
