import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:build_check_app/core/proyecto_actual.dart';
import 'package:build_check_app/models/factura_model.dart';
import 'package:build_check_app/models/movimiento_model.dart';
import 'package:build_check_app/models/proyecto_model.dart';
import 'package:build_check_app/models/material_model.dart';
import 'package:build_check_app/services/factura_service.dart';
import 'package:build_check_app/services/movimiento_service.dart';
import 'package:build_check_app/services/proyecto_service.dart';

class GastosDashboardPage extends StatefulWidget {
  const GastosDashboardPage({super.key});

  @override
  State<GastosDashboardPage> createState() => _GastosDashboardPageState();
}

class _GastosDashboardPageState extends State<GastosDashboardPage> {
  // Servicios
  final FacturaService _facturaService = FacturaService();
  final MovimientoService _movimientoService = MovimientoService();
  final ProyectoService _proyectoService = ProyectoService();

  // Filtros
  int? _proyectoIdSeleccionado;
  DateTimeRange? _rangoFechas;
  
  // Datos
  List<Proyecto> _proyectos = [];
  List<Factura> _facturas = [];
  List<MovimientoResumen> _movimientos = [];
  
  // Estados
  bool _cargandoProyectos = true;
  bool _cargandoDatos = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _proyectoIdSeleccionado = ProyectoActual.id;
    // Rango por defecto: últimos 30 días
    final hoy = DateTime.now();
    _rangoFechas = DateTimeRange(
      start: hoy.subtract(const Duration(days: 30)),
      end: hoy,
    );
    _cargarProyectos();
  }

  Future<void> _cargarProyectos() async {
    setState(() {
      _cargandoProyectos = true;
      _error = null;
    });
    try {
      final proyectos = await _proyectoService.obtenerMisProyectos();
      setState(() {
        _proyectos = proyectos;
        _cargandoProyectos = false;
      });
      // Si el proyecto actual no está en la lista de proyectos, seleccionamos el primero disponible
      if (_proyectoIdSeleccionado == null && proyectos.isNotEmpty) {
        _proyectoIdSeleccionado = proyectos.first.id;
      }
      _cargarDatosDashboard();
    } catch (e) {
      setState(() {
        _error = "Error al cargar los proyectos: $e";
        _cargandoProyectos = false;
        _cargandoDatos = false;
      });
    }
  }

  Future<void> _cargarDatosDashboard() async {
    if (_proyectoIdSeleccionado == null) return;
    setState(() {
      _cargandoDatos = true;
      _error = null;
    });
    try {
      // 1. Cargar facturas filtradas por el proyecto localmente seleccionado
      final facturas = await _facturaService.obtenerFacturas(
        proyectoId: _proyectoIdSeleccionado,
      );

      // 2. Cargar movimientos y materiales para el proyecto seleccionado
      final result = await _movimientoService.obtenerConsumosYMateriales(
        proyectoId: _proyectoIdSeleccionado,
      );

      setState(() {
        _facturas = facturas;
        _movimientos = (result['movimientos'] as List<MovimientoResumen>?) ?? [];
        _cargandoDatos = false;
      });
    } catch (e) {
      setState(() {
        _error = "Error al cargar datos financieros: $e";
        _cargandoDatos = false;
      });
    }
  }

  // --- MÉTODOS DE CÁLCULO ---

  // Obtener facturas en el rango seleccionado
  List<Factura> get _facturasFiltradas {
    if (_rangoFechas == null) return _facturas;
    return _facturas.where((f) {
      final fechaSinHora = DateTime(f.fecha.year, f.fecha.month, f.fecha.day);
      final inicio = DateTime(_rangoFechas!.start.year, _rangoFechas!.start.month, _rangoFechas!.start.day);
      final fin = DateTime(_rangoFechas!.end.year, _rangoFechas!.end.month, _rangoFechas!.end.day);
      return fechaSinHora.isAfter(inicio.subtract(const Duration(seconds: 1))) &&
             fechaSinHora.isBefore(fin.add(const Duration(days: 1)));
    }).toList();
  }

  // Obtener movimientos de salida (Consumos) en el rango seleccionado
  List<MovimientoResumen> get _consumosFiltrados {
    return _movimientos.where((m) {
      if (m.tipoMovimiento != 'SALIDA') return false;
      if (_rangoFechas == null) return true;
      final fechaSinHora = DateTime(m.fecha.year, m.fecha.month, m.fecha.day);
      final inicio = DateTime(_rangoFechas!.start.year, _rangoFechas!.start.month, _rangoFechas!.start.day);
      final fin = DateTime(_rangoFechas!.end.year, _rangoFechas!.end.month, _rangoFechas!.end.day);
      return fechaSinHora.isAfter(inicio.subtract(const Duration(seconds: 1))) &&
             fechaSinHora.isBefore(fin.add(const Duration(days: 1)));
    }).toList();
  }

  // Total Gastado (Facturas)
  double get _totalGastado {
    return _facturasFiltradas.fold(0.0, (sum, f) => sum + (f.valorTotal ?? 0.0));
  }

  // Mapa de materiales para buscar precios rápidamente
  Map<int, MaterialItem> _materialesMap = {};

  double get _calcularTotalConsumido {
    double total = 0.0;
    for (var m in _consumosFiltrados) {
      final material = _materialesMap[m.materialId];
      final precio = material?.precioUnitario ?? 0.0;
      total += m.cantidad * precio;
    }
    return total;
  }

  // Variación Mensual de Gastos
  // Compara los gastos del mes actual con los del mes anterior dentro de las facturas totales
  double get _variacionMensual {
    final hoy = DateTime.now();
    final inicioMesActual = DateTime(hoy.year, hoy.month, 1);
    final inicioMesAnterior = DateTime(hoy.year, hoy.month - 1, 1);
    final finMesAnterior = inicioMesActual.subtract(const Duration(seconds: 1));

    double gastosMesActual = 0.0;
    double gastosMesAnterior = 0.0;

    for (var f in _facturas) {
      if (f.fecha.isAfter(inicioMesActual.subtract(const Duration(seconds: 1))) &&
          f.fecha.isBefore(hoy.add(const Duration(days: 1)))) {
        gastosMesActual += (f.valorTotal ?? 0.0);
      } else if (f.fecha.isAfter(inicioMesAnterior.subtract(const Duration(seconds: 1))) &&
                 f.fecha.isBefore(finMesAnterior.add(const Duration(seconds: 1)))) {
        gastosMesAnterior += (f.valorTotal ?? 0.0);
      }
    }

    if (gastosMesAnterior == 0.0) {
      return gastosMesActual > 0.0 ? 100.0 : 0.0;
    }

    return ((gastosMesActual - gastosMesAnterior) / gastosMesAnterior) * 100.0;
  }

  // --- AGRUPAR DATOS PARA LOS GRÁFICOS ---

  // Agrupar gastos por día/semana/mes para el gráfico de líneas
  List<ChartPoint> get _puntosGastoGrafico {
    final facturas = _facturasFiltradas;
    if (facturas.isEmpty) return [];

    final map = <String, double>{};
    final inicio = _rangoFechas?.start ?? DateTime.now().subtract(const Duration(days: 30));
    final fin = _rangoFechas?.end ?? DateTime.now();
    final diasDiferencia = fin.difference(inicio).inDays;

    if (diasDiferencia <= 35) {
      // Agrupar por Día
      for (var d = inicio; d.isBefore(fin.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
        final key = DateFormat('yyyy-MM-dd').format(d);
        map[key] = 0.0;
      }
      for (var f in facturas) {
        final key = DateFormat('yyyy-MM-dd').format(f.fecha);
        if (map.containsKey(key)) {
          map[key] = map[key]! + (f.valorTotal ?? 0.0);
        }
      }
      final sortedKeys = map.keys.toList()..sort();
      return sortedKeys.map((k) {
        final date = DateTime.parse(k);
        return ChartPoint(DateFormat('dd MMM', 'es').format(date), map[k]!);
      }).toList();
    } else {
      // Agrupar por Mes
      for (var f in facturas) {
        final key = DateFormat('yyyy-MM').format(f.fecha);
        map[key] = (map[key] ?? 0.0) + (f.valorTotal ?? 0.0);
      }
      final sortedKeys = map.keys.toList()..sort();
      return sortedKeys.map((k) {
        final parts = k.split('-');
        final date = DateTime(int.parse(parts[0]), int.parse(parts[1]));
        return ChartPoint(DateFormat('MMM yy', 'es').format(date), map[k]!);
      }).toList();
    }
  }

  // Agrupar consumo de materiales por valor (Top consumidos) para el gráfico de barras
  List<MaterialConsumo> get _topMaterialesConsumidos {
    final consumos = _consumosFiltrados;
    final mapValores = <String, double>{};
    final mapCantidades = <String, String>{};

    for (var m in consumos) {
      final material = _materialesMap[m.materialId];
      final precio = material?.precioUnitario ?? 0.0;
      final costoTotal = m.cantidad * precio;

      final nombre = m.materialNombre.isNotEmpty ? m.materialNombre : "Material #${m.materialId}";
      mapValores[nombre] = (mapValores[nombre] ?? 0.0) + costoTotal;
      
      final unidad = m.unidadMedida.isNotEmpty ? m.unidadMedida : "ud";
      final cantActual = double.tryParse(mapCantidades[nombre]?.split(' ')[0] ?? '0') ?? 0.0;
      mapCantidades[nombre] = "${cantActual + m.cantidad} $unidad";
    }

    final lista = mapValores.entries.map((entry) {
      return MaterialConsumo(
        nombre: entry.key,
        valorTotal: entry.value,
        cantidadFormateada: mapCantidades[entry.key] ?? '',
      );
    }).toList();

    // Ordenar de mayor a menor consumo por valor
    lista.sort((a, b) => b.valorTotal.compareTo(a.valorTotal));
    return lista.take(5).toList(); // Top 5
  }

  // --- DIÁLOGOS Y PICKERS ---

  Future<void> _seleccionarRangoFechas() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _rangoFechas,
      confirmText: 'Aceptar',
      cancelText: 'Cancelar',
      helpText: 'Seleccionar rango de fechas',
      saveText: 'Aceptar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4CAF50),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (range != null) {
      setState(() {
        _rangoFechas = range;
      });
    }
  }

  String _formatearMoneda(double amount) {
    return NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final Color primaryGreen = const Color(0xFF4CAF50);
    final Color backgroundGray = const Color(0xFFF5F5F5);

    // Cargar mapa de materiales local al recibir los datos
    if (!_cargandoDatos && _movimientos.isNotEmpty && _materialesMap.isEmpty) {
      // Re-popular mapa local
      _movimientoService.obtenerConsumosYMateriales(proyectoId: _proyectoIdSeleccionado).then((res) {
        if (mounted && res.containsKey('materiales')) {
          setState(() {
            _materialesMap = (res['materiales'] as Map<int, MaterialItem>?) ?? {};
          });
        }
      });
    }

    final totalGastado = _totalGastado;
    final totalConsumido = _calcularTotalConsumido;
    final variacion = _variacionMensual;

    return Scaffold(
      backgroundColor: backgroundGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Dashboard Financiero',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _cargandoProyectos
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
          : _error != null
              ? _buildErrorState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- FILTROS DE SELECCIÓN ---
                      _buildFiltersSection(primaryGreen),
                      const SizedBox(height: 16),

                      if (_cargandoDatos)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(color: Color(0xFF4CAF50)),
                          ),
                        )
                      else ...[
                        // --- TARJETAS DE INDICADORES ---
                        _buildIndicatorsGrid(totalGastado, totalConsumido, variacion),
                        const SizedBox(height: 20),

                        // --- GRÁFICO 1: TENDENCIA DE GASTOS ---
                        _buildTrendExpensesChart(primaryGreen),
                        const SizedBox(height: 20),

                        // --- GRÁFICO 2: CONSUMO DE MATERIALES ---
                        _buildConsumptionChart(primaryGreen),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
    );
  }

  // --- SECCIONES DE LA INTERFAZ ---

  Widget _buildFiltersSection(Color primaryGreen) {

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Selector de Proyecto
          Row(
            children: [
              Icon(Icons.business_rounded, color: primaryGreen, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _proyectoIdSeleccionado,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _proyectos.map((p) {
                      return DropdownMenuItem<int>(
                        value: p.id,
                        child: Text(p.nombre),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _proyectoIdSeleccionado = val;
                          _materialesMap = {}; // Reset local materials
                        });
                        _cargarDatosDashboard();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20, thickness: 1),
          // Selector de Fecha
          InkWell(
            onTap: _seleccionarRangoFechas,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: primaryGreen, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _rangoFechas == null
                          ? "Todos los registros"
                          : "${DateFormat('dd MMM, yyyy', 'es').format(_rangoFechas!.start)}  —  ${DateFormat('dd MMM, yyyy', 'es').format(_rangoFechas!.end)}",
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const Icon(Icons.edit_calendar_rounded, color: Colors.grey, size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorsGrid(double totalGastado, double totalConsumido, double variacion) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: "Total Gastado",
                value: _formatearMoneda(totalGastado),
                sub: "Inversión en compras",
                icon: Icons.account_balance_wallet_rounded,
                color: const Color(0xFFE8F5E9),
                iconColor: const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: "Total Consumido",
                value: _formatearMoneda(totalConsumido),
                sub: "Materiales aplicados",
                icon: Icons.construction_rounded,
                color: const Color(0xFFFFF3E0),
                iconColor: const Color(0xFFFF9800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMetricCard(
          title: "Variación Mensual de Gastos",
          value: "${variacion >= 0 ? '+' : ''}${variacion.toStringAsFixed(1)}%",
          sub: variacion >= 0 
              ? "Incremento de compras vs mes anterior"
              : "Ahorro/Reducción en compras vs mes anterior",
          icon: variacion >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
          color: variacion >= 0 ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
          iconColor: variacion >= 0 ? Colors.redAccent : const Color(0xFF4CAF50),
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
    required Color iconColor,
    bool isFullWidth = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sub,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendExpensesChart(Color primaryGreen) {
    final points = _puntosGastoGrafico;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tendencia de Gastos (Facturas)",
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Visualización del flujo de inversión monetaria",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          if (points.isEmpty)
            _buildEmptyChartState("No hay facturas registradas en este período")
          else
            SizedBox(
              height: 180,
              child: CustomPaint(
                size: Size.infinite,
                painter: LineChartPainter(
                  points: points,
                  lineColor: primaryGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConsumptionChart(Color primaryGreen) {
    final topMateriales = _topMaterialesConsumidos;
    final double maxValor = topMateriales.isNotEmpty 
        ? topMateriales.map((m) => m.valorTotal).reduce((a, b) => a > b ? a : b)
        : 1.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Consumo de Materiales por Valor",
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Top 5 materiales con mayor costo acumulado en obra",
            style: TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          if (topMateriales.isEmpty)
            _buildEmptyChartState("No se han registrado consumos de material (salidas) en este período")
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topMateriales.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final mat = topMateriales[index];
                final porcentaje = maxValor > 0 ? (mat.valorTotal / maxValor) : 0.0;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            mat.nombre,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatearMoneda(mat.valorTotal),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total Salidas:",
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        Text(
                          mat.cantidadFormateada,
                          style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 8,
                        width: double.infinity,
                        color: Colors.grey[150],
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: porcentaje,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFFFF9800).withValues(alpha: 0.8),
                                  const Color(0xFFFF5722),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyChartState(String message) {
    return SizedBox(
      height: 140,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 36, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 50, color: Colors.grey),
            const SizedBox(height: 14),
            Text(
              _error ?? "Ha ocurrido un error inesperado",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _cargarProyectos,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Reintentar"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- CLASES AUXILIARES ---

class ChartPoint {
  final String label;
  final double value;
  ChartPoint(this.label, this.value);
}

class MaterialConsumo {
  final String nombre;
  final double valorTotal;
  final String cantidadFormateada;

  MaterialConsumo({
    required this.nombre,
    required this.valorTotal,
    required this.cantidadFormateada,
  });
}

// --- CUSTOM PAINTERS PARA GRÁFICOS PREMIUM NATIVOS ---

class LineChartPainter extends CustomPainter {
  final List<ChartPoint> points;
  final Color lineColor;

  LineChartPainter({required this.points, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintFill = Paint()
      ..style = PaintingStyle.fill;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Calcular valores máx / mín de gastos
    double maxValue = points.map((p) => p.value).reduce((a, b) => a > b ? a : b);
    if (maxValue == 0.0) maxValue = 1.0;

    final double width = size.width;
    final double height = size.height;
    
    // Márgenes
    const double paddingLeft = 40.0;
    const double paddingRight = 10.0;
    const double paddingTop = 15.0;
    const double paddingBottom = 25.0;

    final double chartWidth = width - paddingLeft - paddingRight;
    final double chartHeight = height - paddingTop - paddingBottom;

    final int steps = points.length;
    final double dx = steps > 1 ? chartWidth / (steps - 1) : chartWidth;

    final List<Offset> offsets = [];
    for (int i = 0; i < steps; i++) {
      final double x = paddingLeft + (i * dx);
      final double ratio = points[i].value / maxValue;
      final double y = paddingTop + chartHeight - (ratio * chartHeight);
      offsets.add(Offset(x, y));
    }

    // --- DIBUJAR LÍNEAS DE CUADRÍCULA DE FONDO ---
    final gridPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    
    const int verticalGridLines = 4;
    for (int i = 0; i <= verticalGridLines; i++) {
      final double y = paddingTop + (chartHeight * i / verticalGridLines);
      canvas.drawLine(Offset(paddingLeft, y), Offset(width - paddingRight, y), gridPaint);

      // Etiquetas Y
      final double labelValue = maxValue * (verticalGridLines - i) / verticalGridLines;
      String labelStr;
      if (labelValue >= 1000000) {
        labelStr = "${(labelValue / 1000000).toStringAsFixed(1)}M";
      } else if (labelValue >= 1000) {
        labelStr = "${(labelValue / 1000).toStringAsFixed(0)}k";
      } else {
        labelStr = labelValue.toStringAsFixed(0);
      }

      textPainter.text = TextSpan(
        text: "\$$labelStr",
        style: TextStyle(color: Colors.grey[500], fontSize: 9, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(5, y - 6));
    }

    // --- DIBUJAR LA CURVA O LÍNEAS DEL GRÁFICO ---
    final path = Path();
    path.moveTo(offsets[0].dx, offsets[0].dy);
    
    for (int i = 0; i < offsets.length - 1; i++) {
      final p1 = offsets[i];
      final p2 = offsets[i + 1];
      final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2.0, p1.dy);
      final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2.0, p2.dy);
      path.cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, p2.dx, p2.dy);
    }

    // --- DIBUJAR GRADIENTE BAJO LA LÍNEA ---
    final fillPath = Path.from(path);
    fillPath.lineTo(offsets.last.dx, paddingTop + chartHeight);
    fillPath.lineTo(offsets.first.dx, paddingTop + chartHeight);
    fillPath.close();

    paintFill.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        lineColor.withValues(alpha: 0.35),
        lineColor.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTRB(paddingLeft, paddingTop, width - paddingRight, paddingTop + chartHeight));
    
    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);

    // --- DIBUJAR PUNTOS EXTREMOS Y ETIQUETAS X ---
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final int labelInterval = (steps / 5).ceil().clamp(1, steps);

    for (int i = 0; i < steps; i++) {
      final offset = offsets[i];

      // Dibujar punto solo en extremos o puntos intermedios seleccionados
      if (i == 0 || i == steps - 1 || i % labelInterval == 0) {
        canvas.drawCircle(offset, 4.5, dotPaint);
        canvas.drawCircle(offset, 4.5, dotBorderPaint);

        // Etiquetas Eje X
        textPainter.text = TextSpan(
          text: points[i].label,
          style: TextStyle(color: Colors.grey[600], fontSize: 9, fontWeight: FontWeight.w600),
        );
        textPainter.layout();
        canvas.save();
        canvas.translate(offset.dx, paddingTop + chartHeight + 6);
        textPainter.paint(canvas, Offset(-textPainter.width / 2, 0));
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.lineColor != lineColor;
  }
}
