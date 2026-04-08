import 'dart:convert';
import 'dart:typed_data';
import 'package:build_check_app/loginPage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'bottom_nav_shell.dart';

void main() {
  runApp(const BuildCheckApp());
}

// ─────────────────────────────────────────────────────────────────────────────
// CONSTANTES
// ─────────────────────────────────────────────────────────────────────────────

class ApiConfig {
  // ┌─────────────────────────────────────────────────────────────────┐
  // │  IMPORTANTE: cambia baseUrl según dónde ejecutes la app        │
  // │                                                                 │
  // │  Flutter Web (Edge/Chrome)  → http://localhost:8080/api        │
  // │  Emulador Android (AVD)     → http://10.0.2.2:8080/api        │
  // │  Dispositivo físico         → http://192.168.101.6:8080/api   │
  // └─────────────────────────────────────────────────────────────────┘
  // static const String baseUrl     = 'http://localhost:8080/api'; // ← WEB (Edge/Chrome)
  // static const String baseUrl  = 'http://10.0.2.2:8080/api';      // ← Emulador Android
  static const String baseUrl =
      'http://192.168.101.5:8080/api'; // ← Dispositivo físico
  static const String movimientos = '$baseUrl/movimientos-service/movimientos';
  static const String materiales = '$baseUrl/materiales-service/materiales';
  static const String facturas = '$baseUrl/facturas-service/facturas';
  static const String alertas = '$baseUrl/materiales-service/alertas';
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS
// ─────────────────────────────────────────────────────────────────────────────

enum MovementType { entrada, salida }

class _MovimientoResumen {
  final String tipoMovimiento;
  final DateTime fecha;
  final double cantidad;
  final int? materialId;
  final String materialNombre;
  final String unidadMedida;

  final DateTime fechaCreacion;

  const _MovimientoResumen({
    required this.tipoMovimiento,
    required this.fecha,
    required this.cantidad,
    required this.fechaCreacion,
    this.materialId,
    this.materialNombre = '',
    this.unidadMedida = '',
  });

  factory _MovimientoResumen.fromJson(Map<String, dynamic> json) {
    // El backend devuelve materialId como campo directo (opción B: cruzamos con /materiales)
    return _MovimientoResumen(
      tipoMovimiento: json['tipoMovimiento'] ?? '',
      fecha: DateTime.tryParse(json['fecha'] ?? '') ?? DateTime(2000),
      // fechaCreacion tiene hora exacta → sirve para ordenar correctamente
      fechaCreacion:
          DateTime.tryParse(json['fechaCreacion'] ?? '') ?? DateTime(2000),
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0,
      materialId: json['materialId'] as int?,
    );
  }

  /// Copia enriquecida con nombre y unidad del material
  _MovimientoResumen conMaterial(String nombre, String unidad) =>
      _MovimientoResumen(
        tipoMovimiento: tipoMovimiento,
        fecha: fecha,
        fechaCreacion: fechaCreacion,
        cantidad: cantidad,
        materialId: materialId,
        materialNombre: nombre,
        unidadMedida: unidad,
      );

  /// Ej: "10 m | Hace 2h"
  String get detalle {
    final cantStr = cantidad % 1 == 0
        ? cantidad.toInt().toString()
        : cantidad.toString();
    final diff = DateTime.now().difference(fecha);
    String tiempo;
    if (diff.inMinutes < 60)
      tiempo = 'Hace ${diff.inMinutes}min';
    else if (diff.inHours < 24)
      tiempo = 'Hace ${diff.inHours}h';
    else if (diff.inDays == 1)
      tiempo = 'Ayer';
    else
      tiempo = 'Hace ${diff.inDays}d';
    final unidad = unidadMedida.isNotEmpty ? ' $unidadMedida' : '';
    return '$cantStr$unidad | $tiempo';
  }
}

// Modelo para alertas de stock bajo
class AlertaMaterial {
  final int id;
  final String nombre;
  final String mensaje;
  final int stockActual;
  final int stockReferencia;
  final String unidadMedida;

  const AlertaMaterial({
    required this.id,
    required this.nombre,
    required this.mensaje,
    required this.stockActual,
    required this.stockReferencia,
    required this.unidadMedida,
  });

  factory AlertaMaterial.fromJson(Map<String, dynamic> json) => AlertaMaterial(
    id: json['id'],
    nombre: json['nombre'] ?? '',
    mensaje: json['mensaje'] ?? '',
    stockActual: (json['stockActual'] as num).toInt(),
    stockReferencia: (json['stockReferencia'] as num).toInt(),
    unidadMedida: json['unidadMedida'] ?? '',
  );

  /// Porcentaje de stock actual sobre referencia
  double get porcentaje => stockReferencia > 0
      ? (stockActual / stockReferencia * 100).clamp(0, 100)
      : 0;
}

class MaterialItem {
  final int id;
  final String nombre;
  final String unidadMedida;

  const MaterialItem({
    required this.id,
    required this.nombre,
    required this.unidadMedida,
  });

  factory MaterialItem.fromJson(Map<String, dynamic> json) => MaterialItem(
    id: json['id'],
    nombre: json['nombre'],
    unidadMedida: json['unidadMedida'] ?? '',
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// APP
// ─────────────────────────────────────────────────────────────────────────────

class BuildCheckApp extends StatelessWidget {
  const BuildCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Build Check',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4CAF50)),
      ),
      home: const Loginpage(),
    );
  }
}

class BuildCheckHome extends StatefulWidget {
  const BuildCheckHome({super.key});

  @override
  State<BuildCheckHome> createState() => _BuildCheckHomeState();
}

class _BuildCheckHomeState extends State<BuildCheckHome> {
  int _selectedIndex = 0;

  // Contadores y lista del día
  int _entradasHoy = 0;
  int _salidasHoy = 0;
  int _totalMateriales = 0;
  bool _cargandoStats = true;
  List<_MovimientoResumen> _movimientosHoy = [];
  String? _errorMovimientos;

  // Alertas de stock bajo
  List<AlertaMaterial> _alertas = [];
  bool _cargandoAlertas = true;

  @override
  void initState() {
    super.initState();
    _cargarStatsHoy();
    _cargarAlertas();
  }

  Future<void> _cargarStatsHoy() async {
    setState(() {
      _cargandoStats = true;
      _errorMovimientos = null;
    });
    try {
      // Fetch paralelo: movimientos + materiales para cruzar por materialId
      final responses = await Future.wait([
        http.get(Uri.parse(ApiConfig.movimientos)),
        http.get(Uri.parse(ApiConfig.materiales)),
      ]);

      final resMov = responses[0];
      final resMat = responses[1];

      if (resMov.statusCode == 200) {
        final decoded = jsonDecode(resMov.body);
        List rawLista = decoded is List
            ? decoded
            : (decoded is Map && decoded.containsKey('movimientos')
                  ? decoded['movimientos']
                  : []);

        // Construir mapa id → MaterialItem para enriquecer cada movimiento
        final Map<int, MaterialItem> matMap = {};
        int totalMat = 0;
        if (resMat.statusCode == 200) {
          final decMat = jsonDecode(resMat.body);
          List rawMat = decMat is List
              ? decMat
              : (decMat is Map && decMat.containsKey('materiales')
                    ? decMat['materiales']
                    : []);
          totalMat = rawMat.length;
          for (final e in rawMat) {
            final m = MaterialItem.fromJson(e as Map<String, dynamic>);
            matMap[m.id] = m;
          }
        }

        final hoy = DateTime.now();
        final hoyLista =
            rawLista
                .map(
                  (e) => _MovimientoResumen.fromJson(e as Map<String, dynamic>),
                )
                .where(
                  (m) =>
                      m.fecha.year == hoy.year &&
                      m.fecha.month == hoy.month &&
                      m.fecha.day == hoy.day,
                )
                .map((m) {
                  final mat = m.materialId != null
                      ? matMap[m.materialId]
                      : null;
                  return mat != null
                      ? m.conMaterial(mat.nombre, mat.unidadMedida)
                      : m;
                })
                .toList()
              ..sort(
                (a, b) => b.fechaCreacion.compareTo(a.fechaCreacion),
              ); // más reciente primero

        setState(() {
          _entradasHoy = hoyLista
              .where((m) => m.tipoMovimiento.toUpperCase() == 'ENTRADA')
              .length;
          _salidasHoy = hoyLista
              .where((m) => m.tipoMovimiento.toUpperCase() == 'SALIDA')
              .length;
          _totalMateriales = totalMat;
          _movimientosHoy = hoyLista;
          _cargandoStats = false;
        });
      } else {
        setState(() {
          _errorMovimientos = 'Error ${resMov.statusCode}';
          _cargandoStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error cargando stats hoy: $e');
      setState(() {
        _errorMovimientos = e.toString();
        _cargandoStats = false;
      });
    }
  }

  Future<void> _cargarAlertas() async {
    setState(() => _cargandoAlertas = true);
    try {
      final res = await http.get(Uri.parse(ApiConfig.alertas));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List raw = decoded is List
            ? decoded
            : (decoded is Map && decoded.containsKey('alertas')
                  ? decoded['alertas']
                  : [decoded]);
        setState(() {
          _alertas = raw
              .map((e) => AlertaMaterial.fromJson(e as Map<String, dynamic>))
              .toList();
          _cargandoAlertas = false;
        });
      } else {
        setState(() => _cargandoAlertas = false);
      }
    } catch (e) {
      debugPrint('Error cargando alertas: $e');
      setState(() => _cargandoAlertas = false);
    }
  }

  void _abrirStockBajo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _StockBajoSheet(alertas: _alertas, cargando: _cargandoAlertas),
    );
  }

  String _labelForIndex(int i) {
    const labels = [
      'Inicio',
      'Proyectos',
      'Inventario',
      'Movimientos',
      'Reporte',
    ];
    return '${labels[i]}\n(en construcción)';
  }

  void _abrirRegistrarEntrada() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _MovimientoSheet(tipo: 'ENTRADA'),
    ).then((_) => _cargarStatsHoy());
  }

  void _abrirRegistrarSalida() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _MovimientoSheet(tipo: 'SALIDA'),
    ).then((_) {
      _cargarStatsHoy();
      _cargarAlertas(); // refrescar stock bajo tras una salida
    });
  }

  void _abrirEscanearFactura() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FacturaSheet(),
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
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Color(0xFF555555),
            ),
            onPressed: () {},
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
                  child: _StatCard(
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
                  child: _StatCard(
                    label: 'Stock bajo',
                    value: _cargandoAlertas ? '—' : '${_alertas.length}',
                    sublabel: 'Alertas activas',
                    icon: Icons.warning_amber_rounded,
                    iconColor: const Color(0xFFE57373),
                    backgroundColor: const Color(0xFFFFF0F0),
                    valueColor: const Color(0xFF1A1A1A),
                    isLoading: _cargandoAlertas,
                    onTap: _abrirStockBajo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
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
                  child: _StatCard(
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
            Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    label: 'Registrar\nEntrada',
                    icon: Icons.arrow_downward_rounded,
                    iconBgColor: const Color.fromARGB(255, 191, 230, 196),
                    iconColor: const Color(0xFF4CAF50),
                    onTap: _abrirRegistrarEntrada,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    label: 'Registrar\nSalida',
                    icon: Icons.arrow_upward_rounded,
                    iconBgColor: const Color(0xFFF8BBD0),
                    iconColor: const Color(0xFFE91E63),
                    onTap: _abrirRegistrarSalida,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    label: 'Escanear\nFactura',
                    icon: Icons.camera_alt_outlined,
                    iconBgColor: const Color(0xFFE0E0E0),
                    iconColor: const Color(0xFF757575),
                    onTap: _abrirEscanearFactura,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // ── Movimientos recientes ──
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
                  return _MovementItem(
                    name: m.materialNombre.isNotEmpty
                        ? m.materialNombre
                        : 'Movimiento',
                    detail: m.detalle,
                    type: m.tipoMovimiento.toUpperCase() == 'ENTRADA'
                        ? MovementType.entrada
                        : MovementType.salida,
                  );
                },
              ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) {
            if (i == 0) {
              setState(() => _selectedIndex = 0);
            } else {
              // Navega al shell de la página correspondiente
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BottomNavShell(
                    currentIndex: i,
                    child: Center(
                      child: Text(
                        _labelForIndex(i),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF999999),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4CAF50),
          unselectedItemColor: const Color(0xFF9E9E9E),
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.folder_outlined),
              activeIcon: Icon(Icons.folder),
              label: 'Proyectos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_outlined),
              activeIcon: Icon(Icons.inventory),
              label: 'Inventario',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_vert),
              label: 'Movimientos',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Reporte',
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET — REGISTRAR MOVIMIENTO (ENTRADA / SALIDA)
// ─────────────────────────────────────────────────────────────────────────────

class _MovimientoSheet extends StatefulWidget {
  final String tipo;
  const _MovimientoSheet({required this.tipo});

  @override
  State<_MovimientoSheet> createState() => _MovimientoSheetState();
}

class _MovimientoSheetState extends State<_MovimientoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController();

  List<MaterialItem> _materiales = [];
  MaterialItem? _materialSeleccionado;
  bool _loadingMateriales = true;
  String? _errorMateriales;

  XFile? _fotoSeleccionada;
  Uint8List? _fotoBytes;

  bool _enviando = false;
  DateTime _fecha = DateTime.now();

  // proyectoId hardcodeado por ahora — TODO: dropdown de proyectos
  final int _proyectoId = 1;

  @override
  void initState() {
    super.initState();
    _cargarMateriales();
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarMateriales() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.materiales));
      debugPrint('Materiales status: ${res.statusCode}');
      debugPrint('Materiales body: ${res.body}');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List<MaterialItem> lista = [];

        if (decoded is List) {
          lista = decoded
              .map<MaterialItem>(
                (e) => MaterialItem.fromJson(e as Map<String, dynamic>),
              )
              .toList();
        } else if (decoded is Map) {
          if (decoded.containsKey('materiales')) {
            final List arr = decoded['materiales'];
            lista = arr
                .map<MaterialItem>(
                  (e) => MaterialItem.fromJson(e as Map<String, dynamic>),
                )
                .toList();
          } else if (decoded.containsKey('material')) {
            lista = [
              MaterialItem.fromJson(
                decoded['material'] as Map<String, dynamic>,
              ),
            ];
          }
        }

        setState(() {
          _materiales = lista;
          _loadingMateriales = false;
        });
      } else {
        setState(() {
          _errorMateriales = 'Error HTTP ${res.statusCode}';
          _loadingMateriales = false;
        });
      }
    } catch (e) {
      debugPrint('Excepcion cargando materiales: $e');
      setState(() {
        _errorMateriales = e.toString();
        _loadingMateriales = false;
      });
    }
  }

  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _fotoSeleccionada = picked;
        _fotoBytes = bytes;
      });
    }
  }

  void _quitarFoto() => setState(() {
    _fotoSeleccionada = null;
    _fotoBytes = null;
  });

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF4CAF50)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_materialSeleccionado == null) {
      _mostrarSnack('Selecciona un material', isError: true);
      return;
    }

    // Validar stock suficiente antes de registrar una salida
    if (widget.tipo == 'SALIDA') {
      final cantidadSolicitada = double.parse(_cantidadCtrl.text.trim());
      // Buscar el stock actual del material desde la API
      try {
        final res = await http.get(
          Uri.parse('${ApiConfig.materiales}/${_materialSeleccionado!.id}'),
        );
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          final matData = decoded is Map && decoded.containsKey('material')
              ? decoded['material']
              : decoded;
          final stockActual = (matData['stockActual'] as num?)?.toDouble() ?? 0;
          if (cantidadSolicitada > stockActual) {
            _mostrarSnack(
              'Stock insuficiente: Stock actual = ${stockActual % 1 == 0 ? stockActual.toInt() : stockActual} ${_materialSeleccionado!.unidadMedida}',
              isError: true,
            );
            return;
          }
        }
      } catch (e) {
        // Si falla la consulta de stock, dejar pasar y que el backend decida
        debugPrint('No se pudo verificar stock: $e');
      }
    }

    setState(() => _enviando = true);

    // Fecha como "YYYY-MM-DD" (sin hora) según el backend
    final fechaStr =
        '${_fecha.year}-${_fecha.month.toString().padLeft(2, '0')}-${_fecha.day.toString().padLeft(2, '0')}';

    final body = jsonEncode({
      'tipoMovimiento': widget.tipo,
      'cantidad': double.parse(_cantidadCtrl.text.trim()),
      'fecha': fechaStr,
      'usuarioId': 8, // TODO: usuario autenticado
      'evidenciaFotografica': _fotoSeleccionada?.name, // null si no hay foto
      'proyectoId': _proyectoId,
      'materialId': _materialSeleccionado!.id,
    });

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.movimientos),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          final label = widget.tipo == 'ENTRADA' ? 'Entrada' : 'Salida';
          _mostrarSnack('$label registrada correctamente ✓');
        }
      } else {
        _mostrarSnack('Error ${res.statusCode}: ${res.body}', isError: true);
      }
    } catch (e) {
      _mostrarSnack('Error de conexión: $e', isError: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrarSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFE57373)
            : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SheetHandle(),
            Builder(
              builder: (_) {
                final isEntrada = widget.tipo == 'ENTRADA';
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isEntrada
                            ? const Color.fromARGB(255, 191, 230, 196)
                            : const Color(0xFFF8BBD0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isEntrada
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded,
                        color: isEntrada
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFE91E63),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isEntrada ? 'Registrar Entrada' : 'Registrar Salida',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            const _FieldLabel('Material'),
            const SizedBox(height: 6),
            if (_loadingMateriales)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: CircularProgressIndicator(
                    color: Color(0xFF4CAF50),
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (_errorMateriales != null)
              _ErrorMateriales(
                error: _errorMateriales!,
                onRetry: () {
                  setState(() {
                    _loadingMateriales = true;
                    _errorMateriales = null;
                  });
                  _cargarMateriales();
                },
              )
            else
              DropdownButtonFormField<MaterialItem>(
                value: _materialSeleccionado,
                hint: const Text(
                  'Selecciona un material',
                  style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
                ),
                decoration: _inputDecoration(),
                items: _materiales
                    .map(
                      (m) => DropdownMenuItem(value: m, child: Text(m.nombre)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _materialSeleccionado = v),
                validator: (v) => v == null ? 'Selecciona un material' : null,
              ),

            const SizedBox(height: 14),
            const _FieldLabel('Cantidad'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _cantidadCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _inputDecoration(
                suffix: _materialSeleccionado != null
                    ? Text(
                        _materialSeleccionado!.unidadMedida,
                        style: const TextStyle(
                          color: Color(0xFF777777),
                          fontSize: 13,
                        ),
                      )
                    : null,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Ingresa la cantidad';
                if (double.tryParse(v.trim()) == null) return 'Número inválido';
                if (double.parse(v.trim()) <= 0) return 'Debe ser mayor a 0';
                return null;
              },
            ),

            const SizedBox(height: 14),
            const _FieldLabel('Fecha'),
            const SizedBox(height: 6),
            _DatePicker(fecha: _fecha, onTap: _seleccionarFecha),

            const SizedBox(height: 14),
            Row(
              children: [
                const _FieldLabel('Evidencia fotográfica'),
                const SizedBox(width: 6),
                _BadgeOpcional(),
              ],
            ),
            const SizedBox(height: 6),
            _FotoSelector(
              bytes: _fotoBytes,
              archivo: _fotoSeleccionada,
              onSelect: _seleccionarFoto,
              onRemove: _quitarFoto,
            ),

            const SizedBox(height: 24),
            _BotonEnviar(
              enviando: _enviando,
              label: widget.tipo == 'ENTRADA'
                  ? 'Registrar entrada'
                  : 'Registrar salida',
              onTap: _enviar,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET — ESCANEAR / REGISTRAR FACTURA
// ─────────────────────────────────────────────────────────────────────────────

class _FacturaSheet extends StatefulWidget {
  const _FacturaSheet();

  @override
  State<_FacturaSheet> createState() => _FacturaSheetState();
}

class _FacturaSheetState extends State<_FacturaSheet> {
  String _modo = 'foto';

  final _formKey = GlobalKey<FormState>();
  final _numeroCtrl = TextEditingController();
  final _proveedorCtrl = TextEditingController();
  final _observCtrl = TextEditingController();
  final _valorCtrl = TextEditingController();
  final _proyectoCtrl = TextEditingController(
    text: '1',
  ); // TODO: dropdown de proyectos

  DateTime _fecha = DateTime.now();

  XFile? _fotoSeleccionada;
  Uint8List? _fotoBytes;
  bool _enviando = false;

  // Items de factura — lista de {materialId, cantidad, precioUnitario}
  final List<Map<String, dynamic>> _items = [];

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _proveedorCtrl.dispose();
    _observCtrl.dispose();
    _valorCtrl.dispose();
    _proyectoCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _fotoSeleccionada = picked;
        _fotoBytes = bytes;
      });
    }
  }

  void _quitarFoto() => setState(() {
    _fotoSeleccionada = null;
    _fotoBytes = null;
  });

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF757575)),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _enviar() async {
    if (_modo == 'foto' && _fotoBytes == null) {
      _mostrarSnack('Adjunta una imagen de la factura', isError: true);
      return;
    }
    if (_modo == 'manual' && !_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);

    final fechaStr =
        '${_fecha.year}-${_fecha.month.toString().padLeft(2, '0')}-${_fecha.day.toString().padLeft(2, '0')}';

    final body = jsonEncode({
      'numeroFactura': _numeroCtrl.text.trim().isEmpty
          ? null
          : _numeroCtrl.text.trim(),
      'fecha': fechaStr,
      'proveedor': _proveedorCtrl.text.trim().isEmpty
          ? null
          : _proveedorCtrl.text.trim(),
      'observaciones': _observCtrl.text.trim().isEmpty
          ? null
          : _observCtrl.text.trim(),
      'valorTotal': _valorCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_valorCtrl.text.trim()),
      'proyectoId': int.tryParse(_proyectoCtrl.text.trim()) ?? 1,
      // TODO: subir _fotoBytes con multipart cuando el backend lo soporte
      'imagenFactura': _fotoSeleccionada?.name,
      // items: lista de materiales de la factura
      'items': _items,
    });

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.facturas),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          Navigator.pop(context);
          _mostrarSnack('Factura registrada correctamente ✓');
        }
      } else {
        _mostrarSnack('Error ${res.statusCode}: ${res.body}', isError: true);
      }
    } catch (e) {
      _mostrarSnack('Error de conexión: $e', isError: true);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _mostrarSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? const Color(0xFFE57373)
            : const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetHandle(),

              // ── Título ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0E0E0),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: Color(0xFF555555),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Registrar Factura',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Toggle modo ──
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _ModoTab(
                      label: 'Subir imagen',
                      icon: Icons.camera_alt_outlined,
                      selected: _modo == 'foto',
                      onTap: () => setState(() => _modo = 'foto'),
                    ),
                    _ModoTab(
                      label: 'Manual',
                      icon: Icons.edit_outlined,
                      selected: _modo == 'manual',
                      onTap: () => setState(() => _modo = 'manual'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── MODO FOTO ──
              if (_modo == 'foto') ...[
                const _FieldLabel('Imagen de la factura'),
                const SizedBox(height: 6),
                _FotoSelector(
                  bytes: _fotoBytes,
                  archivo: _fotoSeleccionada,
                  onSelect: _seleccionarFoto,
                  onRemove: _quitarFoto,
                  placeholder: 'Toca para subir la imagen de la factura',
                  height: 200,
                ),
                const SizedBox(height: 14),
                const _FieldLabel('Número de factura'),
                const SizedBox(height: 6),
                _OptionalField(
                  controller: _numeroCtrl,
                  hint: 'Ej: FAC-2026-001',
                ),
                const SizedBox(height: 14),
                const _FieldLabel('Observaciones'),
                const SizedBox(height: 6),
                _OptionalField(
                  controller: _observCtrl,
                  hint: 'Notas adicionales',
                  maxLines: 2,
                ),
              ],

              // ── MODO MANUAL ──
              if (_modo == 'manual') ...[
                const _FieldLabel('Número de factura'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _numeroCtrl,
                  decoration: _inputDecoration(hint: 'Ej: FAC-2026-001'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo requerido'
                      : null,
                ),

                const SizedBox(height: 14),
                const _FieldLabel('Proveedor'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _proveedorCtrl,
                  decoration: _inputDecoration(hint: 'Nombre del proveedor'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo requerido'
                      : null,
                ),

                const SizedBox(height: 14),
                const _FieldLabel('Valor total'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _valorCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: _inputDecoration(
                    hint: 'Ej: 50000000',
                    prefix: const Text(
                      r'$  ',
                      style: TextStyle(color: Color(0xFF777777)),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Campo requerido';
                    if (double.tryParse(v.trim()) == null)
                      return 'Número inválido';
                    return null;
                  },
                ),

                const SizedBox(height: 14),
                const _FieldLabel('Fecha'),
                const SizedBox(height: 6),
                _DatePicker(fecha: _fecha, onTap: _seleccionarFecha),

                const SizedBox(height: 14),
                const _FieldLabel('Proyecto ID'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _proyectoCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(hint: '1'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Campo requerido'
                      : null,
                ),

                const SizedBox(height: 14),
                const _FieldLabel('Observaciones'),
                const SizedBox(height: 6),
                _OptionalField(
                  controller: _observCtrl,
                  hint: 'Notas adicionales (opcional)',
                  maxLines: 2,
                ),

                const SizedBox(height: 14),
                Row(
                  children: [
                    const _FieldLabel('Imagen adjunta'),
                    const SizedBox(width: 6),
                    _BadgeOpcional(),
                  ],
                ),
                const SizedBox(height: 6),
                _FotoSelector(
                  bytes: _fotoBytes,
                  archivo: _fotoSeleccionada,
                  onSelect: _seleccionarFoto,
                  onRemove: _quitarFoto,
                ),
              ],

              const SizedBox(height: 24),
              _BotonEnviar(
                enviando: _enviando,
                label: 'Registrar factura',
                color: const Color(0xFF555555),
                onTap: _enviar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS REUTILIZABLES
// ─────────────────────────────────────────────────────────────────────────────

class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFDDDDDD),
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

class _BadgeOpcional extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFFEEEEEE),
      borderRadius: BorderRadius.circular(4),
    ),
    child: const Text(
      'Opcional',
      style: TextStyle(fontSize: 10, color: Color(0xFF888888)),
    ),
  );
}

class _ModoTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModoTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? const Color(0xFF333333)
                  : const Color(0xFF999999),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? const Color(0xFF333333)
                    : const Color(0xFF999999),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DatePicker extends StatelessWidget {
  final DateTime fecha;
  final VoidCallback onTap;
  const _DatePicker({required this.fecha, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCCCCCC)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_outlined,
            size: 18,
            color: Color(0xFF777777),
          ),
          const SizedBox(width: 10),
          Text(
            '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
            style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
          ),
        ],
      ),
    ),
  );
}

class _FotoSelector extends StatelessWidget {
  final Uint8List? bytes;
  final XFile? archivo;
  final VoidCallback onSelect;
  final VoidCallback onRemove;
  final String placeholder;
  final double height;

  const _FotoSelector({
    required this.bytes,
    required this.archivo,
    required this.onSelect,
    required this.onRemove,
    this.placeholder = 'Toca para agregar una foto',
    this.height = 120,
  });

  @override
  Widget build(BuildContext context) {
    if (bytes == null) {
      return GestureDetector(
        onTap: onSelect,
        child: Container(
          width: double.infinity,
          height: height,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFCCCCCC)),
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFFAFAFA),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_photo_alternate_outlined,
                size: 32,
                color: Color(0xFFBBBBBB),
              ),
              const SizedBox(height: 6),
              Text(
                placeholder,
                style: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
              ),
            ],
          ),
        ),
      );
    }
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            bytes!,
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 18),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              archivo!.name,
              style: const TextStyle(color: Colors.white, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}

class _OptionalField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _OptionalField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    decoration: _inputDecoration(hint: hint),
  );
}

class _BotonEnviar extends StatelessWidget {
  final bool enviando;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _BotonEnviar({
    required this.enviando,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF4CAF50),
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: enviando ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xFFBDBDBD),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: enviando
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
          : Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
    ),
  );
}

class _ErrorMateriales extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorMateriales({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0F0),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE57373)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.error_outline, color: Color(0xFFE57373), size: 16),
            SizedBox(width: 6),
            Text(
              'Error al cargar materiales',
              style: TextStyle(
                color: Color(0xFFE57373),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          error,
          style: const TextStyle(color: Color(0xFF777777), fontSize: 11),
        ),
        TextButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh, size: 14),
          label: const Text('Reintentar', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFE57373),
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 28),
          ),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF444444),
    ),
  );
}

InputDecoration _inputDecoration({
  Widget? suffix,
  Widget? prefix,
  String? hint,
}) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
  prefixIcon: prefix != null
      ? Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Align(widthFactor: 1, child: prefix),
        )
      : null,
  suffixIcon: suffix != null
      ? Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Align(widthFactor: 1, child: suffix),
        )
      : null,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFE57373)),
  ),
  focusedErrorBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(color: Color(0xFFE57373), width: 1.5),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS DE PANTALLA PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.sublabel,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.valueColor,
    this.isLoading = false,
    this.onTap,
  });

  final String label;
  final String value;
  final String sublabel;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color valueColor;
  final bool isLoading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCCCCCC), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF777777),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  Icon(icon, size: 20, color: iconColor),
                ],
              ),
              const SizedBox(height: 8),
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF4CAF50),
                  ),
                )
              else
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                    height: 1,
                  ),
                ),
              const SizedBox(height: 2),
              Text(
                sublabel,
                style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.label,
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: iconBgColor.withOpacity(0.5),
        highlightColor: iconBgColor.withOpacity(0.25),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFCCCCCC), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF444444),
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MovementItem extends StatelessWidget {
  const _MovementItem({
    required this.name,
    required this.detail,
    required this.type,
  });

  final String name;
  final String detail;
  final MovementType type;

  @override
  Widget build(BuildContext context) {
    final isEntrada = type == MovementType.entrada;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCCCCCC), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            isEntrada
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color: isEntrada
                ? const Color(0xFF4CAF50)
                : const Color(0xFFE57373),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isEntrada
                  ? const Color(0xFFEDF7EE)
                  : const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isEntrada ? 'ENTRADA' : 'SALIDA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isEntrada
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFE57373),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET — STOCK BAJO
// ─────────────────────────────────────────────────────────────────────────────

class _StockBajoSheet extends StatelessWidget {
  final List<AlertaMaterial> alertas;
  final bool cargando;

  const _StockBajoSheet({required this.alertas, required this.cargando});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Handle ──
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDDDDDD),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Título ──
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF888888),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Stock bajo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const SizedBox(width: 8),
              if (!cargando)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${alertas.length} materiales',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF777777),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Contenido ──
          if (cargando)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4CAF50),
                  strokeWidth: 2.5,
                ),
              ),
            )
          else if (alertas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 40,
                      color: Color(0xFF4CAF50),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Todo el stock está en orden',
                      style: TextStyle(fontSize: 13, color: Color(0xFF777777)),
                    ),
                  ],
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: alertas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final a = alertas[index];
                  return _AlertaItem(alerta: a);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _AlertaItem extends StatelessWidget {
  final AlertaMaterial alerta;
  const _AlertaItem({required this.alerta});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCCCCCC), width: 1),
      ),
      child: Row(
        children: [
          // Ícono de material
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(width: 12),
          // Nombre y stock
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alerta.nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Stock: ${alerta.stockActual} ${alerta.unidadMedida}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF999999),
                  ),
                ),
              ],
            ),
          ),
          // Badge con el mensaje
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              alerta.mensaje,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF777777),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
