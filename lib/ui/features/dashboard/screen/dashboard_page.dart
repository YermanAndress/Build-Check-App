import 'dart:convert';

import 'package:build_check_app/ui/features/login/screen/login_page.dart';
import 'package:flutter/material.dart';

import 'package:build_check_app/ui/shared/sheet/factura_sheet.dart';
import 'package:build_check_app/ui/shared/sheet/movimiento_sheet.dart';
import 'package:build_check_app/ui/shared/sheet/stock_bajo_sheet.dart';

import 'package:build_check_app/ui/features/dashboard/widget/dashboard_items.dart';
import 'package:build_check_app/ui/shared/widgets/stat_card.dart';

import 'package:build_check_app/services/movimiento_service.dart';
import 'package:build_check_app/services/material_service.dart';

import 'package:build_check_app/models/material_model.dart';
import 'package:build_check_app/models/movimiento_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Contadores y lista del día
  int _entradasHoy = 0;
  int _salidasHoy = 0;
  int _totalMateriales = 0;
  bool _cargandoStats = true;
  List<MovimientoResumen> _movimientosHoy = [];
  String? _errorMovimientos;

  // Alertas de stock bajo
  List<AlertaMaterial> alertas = [];
  bool cargandoAlertas = true;

  @override
  void initState() {
    super.initState();
    _cargarStatsHoy();
    _materialService.obtenerAlertas();
  }

  final MovimientoService _movimientoService = MovimientoService();
  final MaterialService _materialService = MaterialService();

  Future<void> _cargarStatsHoy() async {
    setState(() {
      _cargandoStats = true;
      cargandoAlertas = true;
      _errorMovimientos = null;
    });

    try {
      final stats = await _movimientoService.obtenerStatsHoy();
      final listaAlertas = await _materialService.obtenerAlertas();

      setState(() {
        _movimientosHoy = stats['movimientos'];
        _totalMateriales = stats['totalMateriales'];
        _entradasHoy = stats['entradasHoy'];
        _salidasHoy = stats['salidasHoy'];

        alertas = listaAlertas;

        _cargandoStats = false;
        cargandoAlertas = false;
      });
    } catch (e) {
      setState(() {
        _errorMovimientos = e.toString();
        _cargandoStats = false;
        cargandoAlertas = false;
      });
    }
  }

  void _abrirStockBajo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          StockBajoSheet(alertas: alertas, cargando: cargandoAlertas),
    );
  }

  void _abrirRegistrarEntrada() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MovimientoSheet(tipo: 'ENTRADA'),
    ).then((_) => _cargarStatsHoy());
  }

  void _abrirRegistrarSalida() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MovimientoSheet(tipo: 'SALIDA'),
    ).then((_) {
      _cargarStatsHoy();
      _materialService.obtenerAlertas(); // refrescar stock bajo tras una salida
    });
  }

  void _abrirEscanearFactura() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FacturaSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Build Check',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF555555),
            ),
            onPressed: () {},
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Color(0xFF555555),
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove("token");
                await prefs.remove("usuario");
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const Loginpage()),
                );
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  enabled: false,
                  child: FutureBuilder(
                    future: SharedPreferences.getInstance(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final prefs = snapshot.data!;
                      final usuarioJson = prefs.getString("usuario");
                      if (usuarioJson == null) return const SizedBox();
                      final usuario = jsonDecode(usuarioJson);
                      final nombre = usuario["nombre"] ?? "Usuario";
                      return Text(
                        "Hola, $nombre",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 10),
                      Text("Cerrar sesion"),
                    ],
                  ),
                ),
              ];
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Stats grid ──
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Materiales',
                    value: _cargandoStats ? '—' : '$_totalMateriales',
                    sublabel: 'Registrados',
                    icon: Icons.inventory_2_outlined,
                    iconColor: const Color(0xFF888888),
                    backgroundColor: Colors.white,
                    valueColor: const Color(0xFF1A1A1A),
                    isLoading: _cargandoStats,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Stock bajo',
                    value: cargandoAlertas ? '—' : '${alertas.length}',
                    sublabel: 'Alertas activas',
                    icon: Icons.warning_amber_rounded,
                    iconColor: const Color(0xFFE57373),
                    backgroundColor: const Color(0xFFFFF0F0),
                    valueColor: const Color(0xFF1A1A1A),
                    isLoading: cargandoAlertas,
                    onTap: _abrirStockBajo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Salidas hoy',
                    value: _cargandoStats ? '—' : '$_salidasHoy',
                    sublabel: 'Movimientos',
                    icon: Icons.trending_down,
                    iconColor: const Color(0xFFE57373),
                    backgroundColor: const Color(0xFFFFF0F0),
                    valueColor: const Color(0xFF1A1A1A),
                    isLoading: _cargandoStats,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    label: 'Entradas hoy',
                    value: _cargandoStats ? '—' : '$_entradasHoy',
                    sublabel: 'Movimientos',
                    icon: Icons.subdirectory_arrow_left,
                    iconColor: const Color(0xFF4CAF50),
                    backgroundColor: const Color(0xFFEDF7EE),
                    valueColor: const Color(0xFF1A1A1A),
                    isLoading: _cargandoStats,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // ── Acciones rápidas ──
            const Text(
              'Acciones rápidas',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: QuickActionButton(
                      label: 'Registrar\nEntrada',
                      icon: Icons.arrow_downward_rounded,
                      iconBgColor: const Color.fromARGB(255, 191, 230, 196),
                      iconColor: const Color(0xFF4CAF50),
                      onTap: _abrirRegistrarEntrada,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: QuickActionButton(
                      label: 'Registrar\nSalida',
                      icon: Icons.arrow_upward_rounded,
                      iconBgColor: const Color(0xFFF8BBD0),
                      iconColor: const Color(0xFFE91E63),
                      onTap: _abrirRegistrarSalida,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: QuickActionButton(
                      label: 'Escanear\nFactura',
                      icon: Icons.camera_alt_outlined,
                      iconBgColor: const Color(0xFFE0E0E0),
                      iconColor: const Color(0xFF757575),
                      onTap: _abrirEscanearFactura,
                    ),
                  ),
                ],
              ),
            ),

            // ── Movimientos recientes ──
            const SizedBox(height: 22),
            const Text(
              'Movimientos recientes',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 10),

            if (_cargandoStats)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: CircularProgressIndicator(
                    color: Color(0xFF4CAF50),
                    strokeWidth: 2.5,
                  ),
                ),
              )
            else if (_errorMovimientos != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 32,
                      color: Color(0xFFBBBBBB),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMovimientos!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF777777),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: _cargarStatsHoy,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Reintentar'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              )
            else if (_movimientosHoy.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.inbox_rounded,
                        size: 32,
                        color: Color(0xFFBBBBBB),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Sin movimientos hoy',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _movimientosHoy.length,
                itemBuilder: (context, index) {
                  final m = _movimientosHoy[index];
                  return MovementItem(
                    name: m.materialNombre.isNotEmpty
                        ? m.materialNombre
                        : 'Movimiento',
                    detail: m.descripcionFormateada,
                    type: m.tipoMovimiento.toLowerCase() == 'entrada'
                        ? MovementType.entrada
                        : MovementType.salida,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
