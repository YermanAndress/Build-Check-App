import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../widgets/form_utils.dart';
import '../../../models/factura_model.dart';
import '../../../models/material_model.dart';
import '../../../services/factura_service.dart';
import '../../../services/material_service.dart';
import '../../../enum/unidad_medida.dart';

class FacturaSheet extends StatefulWidget {
  const FacturaSheet({super.key});

  @override
  State<FacturaSheet> createState() => _FacturaSheetState();
}

class _FacturaSheetState extends State<FacturaSheet> {
  String _modo = 'foto';
  final _formKey = GlobalKey<FormState>();
  final MaterialService _materialService = MaterialService();

  // Controladores
  final TextEditingController _numeroCtrl = TextEditingController();
  final TextEditingController _proveedorCtrl = TextEditingController();
  final TextEditingController _valorCtrl = TextEditingController(text: '0');
  final TextEditingController _observacionesCtrl = TextEditingController();
  final TextEditingController _proyectoCtrl = TextEditingController(text: '1');

  final List<FacturaMaterialItem> _itemsSeleccionados = [];
  final DateTime _fecha = DateTime.now();
  Uint8List? _fotoBytes;
  bool _enviando = false;
  UnidadMedida _unidadSeleccionada = UnidadMedida.UNIDAD;

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
    _proyectoCtrl.dispose();
    super.dispose();
  }

  // --- LÓGICA DE AGREGAR ---
  void _agregarMaterial(int id, double cant, double precio, String nombre) {
    setState(() {
      _itemsSeleccionados.add(
        FacturaMaterialItem(
          materialId: id,
          nombre: nombre,
          cantidad: cant,
          precioUnitario: precio,
        ),
      );
      _valorCtrl.text = _totalCalculado.toStringAsFixed(0);
    });
    _mostrarSnack('Agregado: $nombre');
  }

  // --- DIÁLOGOS DE SELECCIÓN ---
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
                          "Stock: ${filtrados[i].stockActual ?? 0} ${filtrados[i].unidadMedida}",
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _pedirCantidades(
                            filtrados[i].id,
                            filtrados[i].nombre,
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

  void _pedirCantidades(int id, String nombre) {
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
                  initialValue: _unidadSeleccionada,
                  decoration: const InputDecoration(
                    labelText: "Unidad de Medida",
                  ),
                  items: UnidadMedida.values
                      .map(
                        (u) =>
                            DropdownMenuItem(value: u, child: Text(u.nombre)),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => _unidadSeleccionada = val!),
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
              onPressed: () async {
                if (nCtrl.text.isEmpty) return;

                final nuevo = await _materialService.crearMaterial(
                  nCtrl.text,
                  _unidadSeleccionada.name,
                  double.tryParse(pCtrl.text) ?? 0,
                  double.tryParse(cCtrl.text) ?? 0,
                );

                if (nuevo != null) {
                  _agregarMaterial(
                    nuevo.id,
                    double.tryParse(cCtrl.text) ?? 0,
                    double.tryParse(pCtrl.text) ?? 0,
                    nCtrl.text,
                  );
                  if (mounted) Navigator.pop(context);
                } else {
                  _mostrarSnack('Error al crear material base', isError: true);
                }
              },
              child: const Text("Crear y Añadir"),
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
          proyectoId: int.tryParse(_proyectoCtrl.text) ?? 1,
        );
      } else {
        final f = Factura(
          numeroFactura: _numeroCtrl.text,
          fecha: _fecha,
          proveedor: _proveedorCtrl.text,
          observaciones: _observacionesCtrl.text,
          valorTotal: double.tryParse(_valorCtrl.text),
          proyectoId: int.tryParse(_proyectoCtrl.text) ?? 1,
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
                onSelect: _seleccionarFoto,
                onRemove: () => setState(() => _fotoBytes = null),
                archivo: null,
              ),
              const SizedBox(height: 32),
              BotonEnviar(
                enviando: _enviando,
                label: 'REGISTRAR FACTURA',
                onTap: _enviar,
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

  Future<void> _seleccionarFoto() async {
    final p = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (p != null) {
      final b = await p.readAsBytes();
      setState(() => _fotoBytes = b);
    }
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
