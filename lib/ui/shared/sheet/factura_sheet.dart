import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/form_utils.dart';
import '../../../models/factura_model.dart';
import '../../../services/factura_service.dart';

class FacturaSheet extends StatefulWidget {
  const FacturaSheet({super.key});

  @override
  State<FacturaSheet> createState() => _FacturaSheetState();
}

class _FacturaSheetState extends State<FacturaSheet> {
  String _modo = 'foto';
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _numeroCtrl = TextEditingController();
  final TextEditingController _proveedorCtrl = TextEditingController();
  final TextEditingController _valorCtrl = TextEditingController();
  final TextEditingController _proyectoCtrl = TextEditingController(text: '1');

  final DateTime _fecha = DateTime.now();
  XFile? _fotoSeleccionada;
  Uint8List? _fotoBytes;
  bool _enviando = false;

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _proveedorCtrl.dispose();
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

  Future<void> _enviar() async {
    if (_modo == 'foto' && _fotoBytes == null) {
      _mostrarSnack('Adjunta una imagen', isError: true);
      return;
    }

    setState(() => _enviando = true);

    final service = FacturaService();
    bool exito = false;

    try {
      if (_modo == 'foto') {
        exito = await service.registrarFacturaConFoto(
          bytes: _fotoBytes!,
          fecha: _fecha,
          proyectoId: int.tryParse(_proyectoCtrl.text) ?? 1,
        );
      } else {
        final factura = Factura(
          numeroFactura: _numeroCtrl.text,
          fecha: _fecha,
          proveedor: _proveedorCtrl.text,
          valorTotal: double.tryParse(_valorCtrl.text),
          proyectoId: int.tryParse(_proyectoCtrl.text) ?? 1,
        );
        exito = await service.registrarFacturaManual(factura);
      }

      if (exito && mounted) {
        Navigator.pop(context, true);
        _mostrarSnack('¡Factura guardada!');
      }
    } catch (e) {
      _mostrarSnack('Error al procesar');
    } finally {
      if (mounted) setState(() => _enviando = false);
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

  // --- DISEÑO ---

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              const Text(
                'Registrar Factura',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    ModoTab(
                      label: 'Escanear',
                      icon: Icons.camera_alt_outlined,
                      selected: _modo == 'foto',
                      onTap: () => setState(() => _modo = 'foto'),
                    ),
                    ModoTab(
                      label: 'Manual',
                      icon: Icons.edit_note_outlined,
                      selected: _modo == 'manual',
                      onTap: () => setState(() => _modo = 'manual'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_modo == 'foto') ...[
                const FieldLabel('Imagen de la factura'),
                FotoSelector(
                  bytes: _fotoBytes,
                  archivo: _fotoSeleccionada,
                  onSelect: _seleccionarFoto,
                  onRemove: _quitarFoto,
                ),
              ] else ...[
                const FieldLabel('Datos de factura'),
                OptionalField(
                  controller: _numeroCtrl,
                  hint: 'Número de Factura',
                ),
                const SizedBox(height: 12),
                OptionalField(controller: _proveedorCtrl, hint: 'Proveedor'),
                const SizedBox(height: 12),
                OptionalField(controller: _valorCtrl, hint: 'Valor Total'),
              ],

              const SizedBox(height: 32),

              BotonEnviar(
                enviando: _enviando,
                label: 'REGISTRAR FACTURA',
                color: Colors.blueGrey,
                onTap: _enviar,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
