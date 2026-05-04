import 'package:flutter/material.dart';

import 'package:build_check_app/models/movimiento_model.dart';
import 'package:build_check_app/services/movimiento_service.dart';
import 'package:build_check_app/ui/features/movimientos/widget/movimiento_card.dart';

class MovimientosPage extends StatefulWidget {
  const MovimientosPage({super.key});

  @override
  State<MovimientosPage> createState() => _MovimientosPageState();
}

class _MovimientosPageState extends State<MovimientosPage>
    with RouteAware, WidgetsBindingObserver {
  List<MovimientoResumen> _movimientos = [];
  List<MovimientoResumen> _filtrados = [];
  bool _cargando = true;
  String? _error;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargar();
    _searchCtrl.addListener(_filtrar);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final stats =
          await MovimientoService().obtenerStatsHoy(soloHoy: false);
      final lista =
          (stats['movimientos'] as List<MovimientoResumen>?) ?? [];
      if (mounted) {
        setState(() {
          _movimientos = lista;
          _filtrados = lista;
          _cargando = false;
        });
        _filtrar(); // Aplicar búsqueda activa si había texto
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _cargando = false;
        });
      }
    }
  }

  void _filtrar() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      _filtrados = query.isEmpty
          ? _movimientos
          : _movimientos.where((m) {
              final nombre = m.materialNombre.isNotEmpty
                  ? m.materialNombre
                  : 'Material #${m.materialId ?? ''}';
              return nombre.toLowerCase().contains(query);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Historial de Movimientos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargar,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF4CAF50),
        onRefresh: _cargar,
        child: Column(
          children: [
            // Barra de búsqueda
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Buscar por material...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchCtrl.clear();
                            _filtrar();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Contenido
            Expanded(
              child: _cargando
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4CAF50),
                        strokeWidth: 2.5,
                      ),
                    )
                  : _error != null
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cloud_off_rounded,
                                  size: 40, color: Color(0xFFBBBBBB)),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Color(0xFF777777), fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: _cargar,
                                icon: const Icon(Icons.refresh_rounded,
                                    size: 16),
                                label: const Text('Reintentar'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF4CAF50),
                                ),
                              ),
                            ],
                          ),
                        )
                      : _filtrados.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.inbox_rounded,
                                      size: 40, color: Color(0xFFBBBBBB)),
                                  const SizedBox(height: 8),
                                  Text(
                                    _searchCtrl.text.isEmpty
                                        ? 'No hay movimientos registrados'
                                        : 'No se encontraron resultados',
                                    style: const TextStyle(
                                        color: Color(0xFF999999),
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: _filtrados.length,
                              itemBuilder: (context, index) => MovimientoCard(
                                movimiento: _filtrados[index],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}