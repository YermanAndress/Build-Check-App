import 'dart:typed_data';
import 'package:build_check_app/core/proyecto_actual.dart';
import 'package:build_check_app/core/usuario_actual.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:build_check_app/models/factura_model.dart';
import 'package:build_check_app/models/material_model.dart';
import 'package:build_check_app/services/factura_service.dart';
import 'package:build_check_app/services/material_service.dart';
import 'package:build_check_app/ui/shared/widgets/form_utils.dart';
import 'package:build_check_app/enum/unidad_medida.dart';
import 'package:build_check_app/ui/shared/sheet/factura_ocr_review_sheet.dart'
    as build_check_app_ocr_review;

class FacturaSheet extends StatefulWidget {
  const FacturaSheet({super.key});

  @override
  State<FacturaSheet> createState() => _FacturaSheetState();
}

class _FacturaSheetState extends State<FacturaSheet> {
  String _modo = 'foto';
  final _formKey = GlobalKey<FormState>();
  final MaterialService _materialService = MaterialService();

  final TextEditingController _numeroCtrl = TextEditingController();
  final TextEditingController _proveedorCtrl = TextEditingController();
  final TextEditingController _valorCtrl = TextEditingController(text: '0');
  final TextEditingController _observacionesCtrl = TextEditingController();

  final List<FacturaMaterialItem> _itemsSeleccionados = [];
  final DateTime _fecha = DateTime.now();
  Uint8List? _fotoBytes;
  bool _enviando = false;
  bool _cargandoImagen = false;
  String? _fotoOrigen;

  double get _totalCalculado => _itemsSeleccionados.fold(
    0.0,
    (sum, item) => sum + (item.cantidad * item.precioUnitario),
  );

  @override
  void dispose() {
    _numeroCtrl.dispose();
    _proveedorCtrl.dispose();
    _valorCtrl.dispose();
    _observacionesCtrl.dispose();
    super.dispose();
  }

  void _agregarMaterial(
    int? id,
    double cant,
    double precio,
    String nombre,
    UnidadMedida unidad,
    int? usuarioId,
    DateTime fechaCreacion,
  ) {
    if (usuarioId == null) {
      _mostrarSnack('Usuario no autenticado', isError: true);
      return;
    }
    setState(() {
      _itemsSeleccionados.add(
        FacturaMaterialItem(
          materialId: id,
          nombre: nombre,
          cantidad: cant,
          precioUnitario: precio,
          unidadMedida: unidad,
          usuarioId: usuarioId,
          fechaCreacion: fechaCreacion,
        ),
      );
      _valorCtrl.text = _totalCalculado.toStringAsFixed(0);
    });
    _mostrarSnack('Agregado: $nombre');
  }

  @override
  void initState() {
    super.initState();
  }

  void _mostrarOpcionesMaterial() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.search, color: Colors.blue),
            title: const Text("Seleccionar material existente"),
            onTap: () {
              Navigator.pop(context);
              _dialogoSeleccionarExistente();
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_box_outlined, color: Colors.green),
            title: const Text("Crear nuevo material"),
            onTap: () {
              Navigator.pop(context);
              _dialogoCrearNuevo();
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _dialogoSeleccionarExistente() async {
    final mapa = await _materialService.obtenerMapaMateriales();
    final materiales = mapa.values.toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        List<MaterialItem> filtrados = materiales;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text("Buscar Material"),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: "Nombre del material...",
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) {
                      setDialogState(() {
                        filtrados = materiales
                            .where(
                              (m) => m.nombre.toLowerCase().contains(
                                val.toLowerCase(),
                              ),
                            )
                            .toList();
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtrados.length,
                      itemBuilder: (context, i) => ListTile(
                        title: Text(filtrados[i].nombre),
                        subtitle: Text(
                          "Stock: ${filtrados[i].stockActual} ${filtrados[i].unidadMedida}",
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _pedirCantidades(
                            filtrados[i].id,
                            filtrados[i].nombre,
                            filtrados[i].unidadMedida,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _pedirCantidades(int id, String nombre, String unidadMedidaStr) {
    final cCtrl = TextEditingController();
    final pCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Cantidades: $nombre"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cCtrl,
              decoration: const InputDecoration(labelText: "Cantidad"),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: pCtrl,
              decoration: const InputDecoration(labelText: "Precio Unitario"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (cCtrl.text.isNotEmpty && pCtrl.text.isNotEmpty) {
                _agregarMaterial(
                  id,
                  double.parse(cCtrl.text),
                  double.parse(pCtrl.text),
                  nombre,
                  UnidadMedida.values.byName(unidadMedidaStr),
                  UsuarioActual.id,
                  DateTime.now(),
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Añadir"),
          ),
        ],
      ),
    );
  }

  void _dialogoCrearNuevo() {
    final nCtrl = TextEditingController();
    final cCtrl = TextEditingController();
    final pCtrl = TextEditingController();
    UnidadMedida tempUnidad = UnidadMedida.UNIDAD;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Crear Nuevo Material"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nCtrl,
                  decoration: const InputDecoration(labelText: "Nombre"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UnidadMedida>(
                  initialValue: tempUnidad,
                  items: UnidadMedida.values
                      .map(
                        (u) =>
                            DropdownMenuItem(value: u, child: Text(u.nombre)),
                      )
                      .toList(),
                  onChanged: (val) => setDialogState(() {
                    tempUnidad = val!;
                  }),
                ),
                TextField(
                  controller: cCtrl,
                  decoration: const InputDecoration(labelText: "Cantidad"),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: pCtrl,
                  decoration: const InputDecoration(
                    labelText: "Precio Unitario",
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (nCtrl.text.isEmpty) return;
                _agregarMaterial(
                  null,
                  double.tryParse(cCtrl.text) ?? 0,
                  double.tryParse(pCtrl.text) ?? 0,
                  nCtrl.text,
                  tempUnidad,
                  UsuarioActual.id,
                  DateTime.now(),
                );
                Navigator.pop(context);
              },
              child: const Text("Agregar a la factura"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enviar() async {
    final form = _formKey.currentState;
    if (form == null && _modo == 'manual') return;
    if (form != null && !form.validate()) return;

    if (_modo == 'foto' && _fotoBytes == null) {
      _mostrarSnack('Sube una foto', isError: true);
      return;
    }
    if (_modo == 'manual' && _itemsSeleccionados.isEmpty) {
      _mostrarSnack('Agrega materiales a la lista', isError: true);
      return;
    }

    setState(() => _enviando = true);
    try {
      final service = FacturaService();
      bool exito = false;
      if (_modo == 'foto') {
        exito = await service.registrarFacturaConFoto(
          bytes: _fotoBytes!,
          fecha: _fecha,
          proyectoId: ProyectoActual.id ?? 0,
        );
      } else {
        final f = Factura(
          numeroFactura: _numeroCtrl.text,
          fecha: _fecha,
          proveedor: _proveedorCtrl.text,
          observaciones: _observacionesCtrl.text,
          valorTotal: double.tryParse(_valorCtrl.text),
          fechaCreacion: DateTime.now(),
          proyectoId: ProyectoActual.id ?? 0,
          usuarioId: UsuarioActual.id ?? 0,
          items: _itemsSeleccionados,
        );
        exito = await service.registrarFacturaManual(f);
      }
      if (exito && mounted) Navigator.pop(context, true);
    } catch (e) {
      _mostrarSnack('Error en el servidor');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SheetHandle(),
            const Text(
              'Registrar Factura',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildModoSelector(),
            const SizedBox(height: 24),
            if (_modo == 'foto') ...[
              FotoSelector(
                bytes: _fotoBytes,
                onSelect: _seleccionarFotoGaleria,
                onCamera: _tomarFotoCamara,
                onRemove: () => setState(() {
                  _fotoBytes = null;
                  _fotoOrigen = null;
                }),
                archivo: null,
                isLoading: _cargandoImagen,
                sourceLabel: _fotoOrigen,
              ),
              const SizedBox(height: 32),
              BotonEnviar(
                enviando: _enviando,
                label: 'REGISTRAR FACTURA',
                onTap: _enviar,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () {
                    // Botón de prueba para simular datos devueltos por IA
                    final facturaExtraida = Factura(
                      proyectoId: 1,
                      usuarioId: UsuarioActual.id ?? 0,
                      proveedor: 'Ferretería El Constructor (Leído por IA)',
                      numeroFactura: 'FAC-88392',
                      fecha: DateTime.now().subtract(const Duration(days: 1)),
                      valorTotal: 1545000.0,
                      fechaCreacion: DateTime.now(),
                      observaciones: 'Extraído vía OCR',
                    );

                    Navigator.pop(context); // Cierra el sheet actual
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          build_check_app_ocr_review.FacturaOcrReviewSheet(
                            facturaExtraida: facturaExtraida,
                          ),
                    );
                  },
                  icon: const Icon(Icons.science, color: Colors.orange),
                  label: const Text(
                    "Simular Respuesta de IA (Test)",
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ),
            ] else ...[
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    OptionalField(
                      controller: _numeroCtrl,
                      hint: 'Número de Factura',
                      enabled: true,
                    ),
                    const SizedBox(height: 12),
                    OptionalField(
                      controller: _proveedorCtrl,
                      hint: 'Proveedor',
                      enabled: true,
                    ),
                    const SizedBox(height: 12),
                    OptionalField(
                      controller: _observacionesCtrl,
                      hint: 'Observaciones',
                      enabled: true,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Materiales Seleccionados",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Divider(),
                    ..._itemsSeleccionados.map(
                      (item) => ListTile(
                        title: Text(item.nombre),
                        subtitle: Text(
                          "${item.cantidad} x \$${item.precioUnitario}",
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() {
                            _itemsSeleccionados.remove(item);
                            _valorCtrl.text = _totalCalculado.toStringAsFixed(
                              0,
                            );
                          }),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _mostrarOpcionesMaterial,
                      icon: const Icon(Icons.add),
                      label: const Text("Agregar Material"),
                    ),
                    const SizedBox(height: 12),
                    OptionalField(
                      controller: _valorCtrl,
                      hint: 'Total',
                      enabled: false,
                    ),
                    const SizedBox(height: 32),
                    BotonEnviar(
                      enviando: _enviando,
                      label: 'REGISTRAR FACTURA',
                      onTap: _enviar,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _mostrarSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  // --- Seleccionar foto desde GALERÍA ---
  Future<void> _seleccionarFotoGaleria() async {
    final p = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (p != null) {
      setState(() => _cargandoImagen = true);
      final b = await p.readAsBytes();
      // Simular procesamiento (cuando haya backend se reemplaza)
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _fotoBytes = b;
          _fotoOrigen = 'Galería';
          _cargandoImagen = false;
        });
      }
    }
  }

  // --- Tomar foto desde CÁMARA con previsualización ---
  Future<void> _tomarFotoCamara() async {
    final p = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (p != null) {
      final b = await p.readAsBytes();
      if (mounted) {
        _mostrarPrevisualizacion(b);
      }
    }
  }

  // --- Diálogo de previsualización con reintentar ---
  void _mostrarPrevisualizacion(Uint8List imageBytes) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
              const Row(
                children: [
                  Icon(Icons.preview_rounded, color: Color(0xFF4CAF50)),
                  SizedBox(width: 8),
                  Text(
                    'Previsualización',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Aviso
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.amber.shade700, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Verifica que la imagen sea legible y no esté borrosa.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF666666)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Imagen
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  imageBytes,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
              // Botones
              Row(
                children: [
                  // Reintentar
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _tomarFotoCamara(); // Abrir cámara de nuevo
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Reintentar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Usar esta foto
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _cargandoImagen = true);
                        // Simular procesamiento
                        Future.delayed(const Duration(milliseconds: 800), () {
                          if (mounted) {
                            setState(() {
                              _fotoBytes = imageBytes;
                              _fotoOrigen = 'Cámara';
                              _cargandoImagen = false;
                            });
                          }
                        });
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Usar foto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModoSelector() {
    return Container(
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
    );
  }
}
