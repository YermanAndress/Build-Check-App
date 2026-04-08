import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import '../widgets/form_utils.dart';
import '../../../core/api_config.dart';
import '../../../models/material_model.dart';

class MovimientoSheet extends StatefulWidget {
  final String tipo; // 'ENTRADA' o 'SALIDA'
  const MovimientoSheet({super.key, required this.tipo});

  @override
  State<MovimientoSheet> createState() => MovimientoSheetState();
}

class MovimientoSheetState extends State<MovimientoSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController();

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
    _cantidadCtrl.dispose();
    super.dispose();
  }

  // --- LÓGICA DE DATOS ---

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
    try {
      final res = await http.get(Uri.parse(ApiConfig.materiales));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        List rawLista = decoded is List
            ? decoded
            : (decoded['materiales'] ?? []);
        setState(() {
          _materiales = rawLista.map((e) => MaterialItem.fromJson(e)).toList();
          _loadingMateriales = false;
        });
      }
    } catch (e) {
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
      'usuarioId': 1,
      'proyectoId': 1,
      'materialId': _materialSeleccionado!.id,
    });

    try {
      final res = await http.post(
        Uri.parse(ApiConfig.movimientos),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            Text(
              isEntrada ? 'Registrar Entrada' : 'Registrar Salida',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            const FieldLabel('Material'),
            if (_loadingMateriales)
              const LinearProgressIndicator()
            else
              DropdownButtonFormField<MaterialItem>(
                decoration: inputDecoration(hint: 'Seleccione material'),
                items: _materiales
                    .map(
                      (m) => DropdownMenuItem(value: m, child: Text(m.nombre)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _materialSeleccionado = v),
                validator: (v) => v == null ? 'Requerido' : null,
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
    );
  }
}
