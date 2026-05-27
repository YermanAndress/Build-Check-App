import 'dart:convert';
import 'dart:typed_data';
import 'package:build_check_app/core/proyecto_actual.dart';
import 'package:build_check_app/core/usuario_actual.dart';
import 'package:build_check_app/services/auth_header.dart';
import 'package:build_check_app/services/http_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:build_check_app/ui/shared/widgets/form_utils.dart';
import 'package:build_check_app/models/material_model.dart';
import 'package:build_check_app/core/api_config.dart';

class MovimientoSheet extends StatefulWidget {
  final String tipo;
  const MovimientoSheet({super.key, required this.tipo});

  @override
  State<MovimientoSheet> createState() => MovimientoSheetState();
}

class MovimientoSheetState extends State<MovimientoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController();
  final TextEditingController _busquedaMaterialCtrl = TextEditingController();
  List<MaterialItem> _materialFiltrados = [];

  List<MaterialItem> _materiales = [];
  MaterialItem? _materialSeleccionado;
  bool _loadingMateriales = true;
  bool _enviando = false;
  String? errorMateriales;

  XFile? _fotoSeleccionada;
  Uint8List? _fotoBytes;
  DateTime _fecha = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cargarMateriales();
  }

  @override
  void dispose() {
    _busquedaMaterialCtrl.dispose();
    _cantidadCtrl.dispose();
    super.dispose();
  }

  Future<void> _seleccionarFoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _fotoSeleccionada = picked;
        _fotoBytes = bytes;
      });
    }
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _fecha = picked);
  }

  Future<void> _cargarMateriales() async {
    final proyectoId = ProyectoActual.id;
    if (proyectoId == null) {
      if (!mounted) return;
      setState(() {
        errorMateriales = 'No hay proyecto seleccionado';
        _loadingMateriales = false;
      });
      return;
    }
    try {
      final res = await HttpInterceptor.send(() async {
        return http.get(
          Uri.parse(ApiConfig.materialesPorProyecto(ProyectoActual.id!)),
          headers: await AuthHeader.getHeaders(),
        );
      });
      if (!mounted) return;
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List rawLista = decoded is List
            ? decoded
            : (decoded['materiales'] ?? []);
        setState(() {
          _materiales = rawLista.map((e) => MaterialItem.fromJson(e)).toList();
          _materialFiltrados = [];
          _loadingMateriales = false;
        });
      } else {
        setState(() {
          errorMateriales = 'Error ${res.statusCode}';
          _loadingMateriales = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMateriales = 'Sin conexión';
        _loadingMateriales = false;
      });
    }
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate() || _materialSeleccionado == null) {
      return;
    }

    setState(() => _enviando = true);

    final body = jsonEncode({
      'tipoMovimiento': widget.tipo,
      'cantidad': double.parse(_cantidadCtrl.text.trim()),
      'fecha':
          "${_fecha.year}-${_fecha.month.toString().padLeft(2, '0')}-${_fecha.day.toString().padLeft(2, '0')}",
      'usuarioId': UsuarioActual.id ?? 0,
      'proyectoId': ProyectoActual.id ?? 0,
      'materialId': _materialSeleccionado!.id,
    });

    try {
      final res = await HttpInterceptor.send(() async {
        return http.post(
          Uri.parse(ApiConfig.movimientos),
          headers: await AuthHeader.getHeaders(),
          body: body,
        );
      });
      if (!mounted) return;
      if (res.statusCode == 200 || res.statusCode == 201) {
        Navigator.pop(context, true);
      } else {
        _mostrarSnack('Error del servidor: ${res.statusCode}', isError: true);
      }
    } catch (e) {
      if (mounted) _mostrarSnack('Error de red', isError: true);
    } finally {
      if (mounted) {
        setState(() => _enviando = false);
      }
    }
  }

  void _mostrarSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEntrada = widget.tipo == 'ENTRADA';
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              Text(
                isEntrada ? 'Registrar Entrada' : 'Registrar Salida',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              const FieldLabel('Material'),
              if (_loadingMateriales)
                const LinearProgressIndicator()
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _busquedaMaterialCtrl,
                      decoration: inputDecoration(
                        hint: 'Buscar material...',
                        suffix: const Icon(
                          Icons.arrow_drop_down,
                          size: 22,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _materialFiltrados = List.from(_materiales);
                        });
                      },
                      onChanged: (value) {
                        setState(() {
                          _materialFiltrados = value.isEmpty
                              ? List.from(_materiales)
                              : _materiales
                                    .where(
                                      (m) => m.nombre.toLowerCase().contains(
                                        value.toLowerCase(),
                                      ),
                                    )
                                    .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    if (_materialFiltrados.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight:
                                MediaQuery.of(context).size.height * 0.25,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const ClampingScrollPhysics(),
                            itemCount: _materialFiltrados.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final m = _materialFiltrados[index];
                              final seleccionado =
                                  _materialSeleccionado?.id == m.id;
                              return ListTile(
                                dense: true,
                                title: Text(
                                  m.nombre,
                                  style: TextStyle(
                                    fontWeight: seleccionado
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: seleccionado
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFF1A1A1A),
                                  ),
                                ),
                                trailing: seleccionado
                                    ? const Icon(
                                        Icons.check,
                                        color: Color(0xFF4CAF50),
                                        size: 18,
                                      )
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _materialSeleccionado = m;
                                    _busquedaMaterialCtrl.text = m.nombre;
                                    _materialFiltrados = [];
                                  });
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    if (_materialSeleccionado != null &&
                        _busquedaMaterialCtrl.text.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 16,
                              color: Color(0xFF4CAF50),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _materialSeleccionado!.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _materialSeleccionado = null;
                                  _busquedaMaterialCtrl.clear();
                                });
                              },
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Color(0xFF757575),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

              const SizedBox(height: 16),
              const FieldLabel('Cantidad'),
              TextFormField(
                controller: _cantidadCtrl,
                keyboardType: TextInputType.number,
                decoration: inputDecoration(
                  hint: '0.00',
                  suffix: Text(_materialSeleccionado?.unidadMedida ?? ''),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),

              const SizedBox(height: 16),
              const FieldLabel('Fecha de Movimiento'),
              DatePicker(fecha: _fecha, onTap: _seleccionarFecha),

              const SizedBox(height: 16),
              const FieldLabel('Evidencia (Opcional)'),
              FotoSelector(
                bytes: _fotoBytes,
                archivo: _fotoSeleccionada,
                onSelect: _seleccionarFoto,
                onRemove: () => setState(() {
                  _fotoSeleccionada = null;
                  _fotoBytes = null;
                }),
              ),

              const SizedBox(height: 24),
              BotonEnviar(
                enviando: _enviando,
                label: isEntrada ? 'CONFIRMAR ENTRADA' : 'CONFIRMAR SALIDA',
                color: isEntrada ? Colors.green : Colors.pink,
                onTap: _enviar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
