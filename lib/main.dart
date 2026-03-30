import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  static const String baseUrl = 'http://localhost:8080/api'; // ← WEB (Edge/Chrome)
  // static const String baseUrl = 'http://10.0.2.2:8080/api';      // ← Emulador Android
  // static const String baseUrl = 'http://192.168.101.6:8080/api'; // ← Dispositivo físico
  static const String movimientos = '$baseUrl/movimientos-service/movimientos';
  static const String materiales  = '$baseUrl/materiales-service/materiales';
}

// ─────────────────────────────────────────────────────────────────────────────
// MODELOS
// ─────────────────────────────────────────────────────────────────────────────

enum MovementType { entrada, salida }

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
      home: const BuildCheckHome(),
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

  void _abrirRegistrarEntrada() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,        // permite que suba con el teclado
      backgroundColor: Colors.transparent,
      builder: (_) => const _RegistrarEntradaSheet(),
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
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF555555)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF555555)),
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
                    label: 'Por recibir hoy',
                    value: '8',
                    sublabel: 'Materiales',
                    icon: Icons.inventory_2_outlined,
                    iconColor: const Color(0xFF888888),
                    backgroundColor: Colors.white,
                    valueColor: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Stock bajo',
                    value: '3',
                    sublabel: 'Alertas activas',
                    icon: Icons.warning_amber_rounded,
                    iconColor: const Color(0xFFE57373),
                    backgroundColor: const Color(0xFFFFF0F0),
                    valueColor: const Color(0xFF1A1A1A),
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
                    value: '12',
                    sublabel: 'Movimientos',
                    icon: Icons.trending_down,
                    iconColor: const Color(0xFFE57373),
                    backgroundColor: const Color(0xFFFFF0F0),
                    valueColor: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Entradas hoy',
                    value: '5',
                    sublabel: 'Movimientos',
                    icon: Icons.subdirectory_arrow_left,
                    iconColor: const Color(0xFF4CAF50),
                    backgroundColor: const Color(0xFFEDF7EE),
                    valueColor: const Color(0xFF1A1A1A),
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
                    onTap: _abrirRegistrarEntrada,   // ← abre el sheet
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    label: 'Registrar\nSalida',
                    icon: Icons.arrow_upward_rounded,
                    iconBgColor: const Color(0xFFF8BBD0),
                    iconColor: const Color(0xFFE91E63),
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickActionButton(
                    label: 'Escanear\nFactura',
                    icon: Icons.camera_alt_outlined,
                    iconBgColor: const Color(0xFFE0E0E0),
                    iconColor: const Color(0xFF757575),
                    onTap: () {},
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

            _MovementItem(
              name: 'Cemento 50kg',
              detail: '200 sacos | Hace 2h',
              type: MovementType.entrada,
            ),
            _MovementItem(
              name: 'Varilla corrugada',
              detail: '50 Piezas | Hace 5h',
              type: MovementType.salida,
            ),
            _MovementItem(
              name: 'Cemento 50kg',
              detail: '15m3 | Ayer',
              type: MovementType.entrada,
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
          onTap: (i) => setState(() => _selectedIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF4CAF50),
          unselectedItemColor: const Color(0xFF9E9E9E),
          selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
            BottomNavigationBarItem(icon: Icon(Icons.folder_outlined), activeIcon: Icon(Icons.folder), label: 'Proyectos'),
            BottomNavigationBarItem(icon: Icon(Icons.inventory_outlined), activeIcon: Icon(Icons.inventory), label: 'Inventario'),
            BottomNavigationBarItem(icon: Icon(Icons.swap_vert), label: 'Movimientos'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'Reporte'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET — REGISTRAR ENTRADA
// ─────────────────────────────────────────────────────────────────────────────

class _RegistrarEntradaSheet extends StatefulWidget {
  const _RegistrarEntradaSheet();

  @override
  State<_RegistrarEntradaSheet> createState() => _RegistrarEntradaSheetState();
}

class _RegistrarEntradaSheetState extends State<_RegistrarEntradaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController();

  // Materiales
  List<MaterialItem> _materiales = [];
  MaterialItem? _materialSeleccionado;
  bool _loadingMateriales = true;
  String? _errorMateriales;

  // Envío
  bool _enviando = false;

  // Fecha (por defecto hoy)
  DateTime _fecha = DateTime.now();

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

  // ── Carga el listado de materiales para el dropdown ──
  Future<void> _cargarMateriales() async {
    try {
      final res = await http.get(Uri.parse(ApiConfig.materiales));

      debugPrint('Materiales status: ${res.statusCode}');
      debugPrint('Materiales body: ${res.body}');

      debugPrint('Materiales raw body: \${res.body}');

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List<MaterialItem> lista = [];

        if (decoded is List) {
          // Caso A: la API devuelve [{...}, {...}]
          lista = decoded.map<MaterialItem>((e) => MaterialItem.fromJson(e as Map<String, dynamic>)).toList();
        } else if (decoded is Map) {
          // Caso B: {"materiales": [...]} → tu API actual
          if (decoded.containsKey('materiales')) {
            final List arr = decoded['materiales'];
            lista = arr.map<MaterialItem>((e) => MaterialItem.fromJson(e as Map<String, dynamic>)).toList();
          // Caso C: {"material": {...}} → objeto único
          } else if (decoded.containsKey('material')) {
            lista = [MaterialItem.fromJson(decoded['material'] as Map<String, dynamic>)];
          }
        }

        setState(() {
          _materiales = lista;
          _loadingMateriales = false;
        });
      } else {
        debugPrint('Error cargando materiales: ${res.statusCode}');
        setState(() {
          _errorMateriales = 'Error HTTP \${res.statusCode}: \${res.body}';
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

  // ── Abre el date picker ──
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

  // ── Envía el movimiento al CRUD ──
  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_materialSeleccionado == null) {
      _mostrarSnack('Selecciona un material', isError: true);
      return;
    }

    setState(() => _enviando = true);

    final body = jsonEncode({
      'tipoMovimiento': 'ENTRADA',
      'cantidad': double.parse(_cantidadCtrl.text.trim()),
      'fecha': _fecha.toIso8601String(),
      'usuarioId': 8,                          // TODO: reemplazar con usuario autenticado
      'evidenciaFotografica': null,            // TODO: adjuntar foto si se implementa
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
          Navigator.pop(context);             // cierra el sheet
          _mostrarSnack('Entrada registrada correctamente ✓');
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
        backgroundColor: isError ? const Color(0xFFE57373) : const Color(0xFF4CAF50),
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
                    color: const Color.fromARGB(255, 191, 230, 196),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_downward_rounded,
                      color: Color(0xFF4CAF50), size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Registrar Entrada',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Dropdown de material ──
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
                // Muestra el error + botón reintentar
                Container(
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
                          Text('Error al cargar materiales',
                              style: TextStyle(
                                  color: Color(0xFFE57373),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _errorMateriales!,
                        style: const TextStyle(color: Color(0xFF777777), fontSize: 11),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _loadingMateriales = true;
                            _errorMateriales = null;
                          });
                          _cargarMateriales();
                        },
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
                )
              else
                DropdownButtonFormField<MaterialItem>(
                  value: _materialSeleccionado,
                  hint: const Text('Selecciona un material',
                      style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14)),
                  decoration: _inputDecoration(),
                  items: _materiales
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.nombre),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _materialSeleccionado = v),
                  validator: (v) => v == null ? 'Selecciona un material' : null,
                ),

            const SizedBox(height: 14),

            // ── Cantidad ──
            const _FieldLabel('Cantidad'),
            const SizedBox(height: 6),
            TextFormField(
              controller: _cantidadCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDecoration(
                suffix: _materialSeleccionado != null
                    ? Text(_materialSeleccionado!.unidadMedida,
                        style: const TextStyle(color: Color(0xFF777777), fontSize: 13))
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

            // ── Fecha ──
            const _FieldLabel('Fecha'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _seleccionarFecha,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFCCCCCC)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 18, color: Color(0xFF777777)),
                    const SizedBox(width: 10),
                    Text(
                      '${_fecha.day.toString().padLeft(2, '0')}/'
                      '${_fecha.month.toString().padLeft(2, '0')}/'
                      '${_fecha.year}',
                      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Botón enviar ──
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _enviando ? null : _enviar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFBDBDBD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _enviando
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'Registrar entrada',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helper: label de campo ───────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF444444),
      ),
    );
  }
}

// ─── Helper: decoración de inputs ────────────────────────────────────────────

InputDecoration _inputDecoration({Widget? suffix}) => InputDecoration(
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
// WIDGETS EXISTENTES (sin cambios)
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
  });

  final String label;
  final String value;
  final String sublabel;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
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
            isEntrada ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: isEntrada ? const Color(0xFF4CAF50) : const Color(0xFFE57373),
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
                  style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isEntrada ? const Color(0xFFEDF7EE) : const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isEntrada ? 'ENTRADA' : 'SALIDA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isEntrada ? const Color(0xFF4CAF50) : const Color(0xFFE57373),
              ),
            ),
          ),
        ],
      ),
    );
  }
}