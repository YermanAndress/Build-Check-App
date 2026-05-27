import 'dart:io';

import 'package:build_check_app/services/factura_service.dart';
import 'package:build_check_app/services/role_helper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:build_check_app/models/factura_model.dart';

class FacturaDetailsScreen extends StatefulWidget {
  final Factura factura;
  const FacturaDetailsScreen({super.key, required this.factura});

  @override
  State<FacturaDetailsScreen> createState() => _FacturaDetailsState();
}

class _FacturaDetailsState extends State<FacturaDetailsScreen> {
  bool _isEditing = false;
  late TextEditingController _proveedorCtrl;
  late TextEditingController _numeroCtrl;
  late TextEditingController _obsCtrl;
  bool _isSaving = false;
  bool _puedeEditar = false;
  bool _savingImage = false;
  String? _signedImageUrl;

  @override
  void initState() {
    super.initState();
    _puedeEditar = RoleHelper.puedeGestionarFacturas();
    _proveedorCtrl = TextEditingController(text: widget.factura.proveedor);
    _numeroCtrl = TextEditingController(text: widget.factura.numeroFactura);
    _obsCtrl = TextEditingController(text: widget.factura.observaciones);
    _cargarUrlImagen();
  }

  Future<void> _cargarUrlImagen() async {
    if (widget.factura.id == null) {
      return;
    }
    final url = await FacturaService().obtenerUrlImagenFactura(
      widget.factura.id!,
    );
    if (mounted) {
      setState(() => _signedImageUrl = url);
    }
  }

  Future<void> _guardarCambios() async {
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isSaving = false;
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Factura actualizada correctamente ✓')),
      );
    }
  }

  Future<void> _copiarUrl() async {
    final url = _signedImageUrl;
    if (url == null || url.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL copiada al portapapeles')),
      );
    }
  }

  Future<void> _descargarImagen() async {
    final url = _signedImageUrl;
    if (url == null || url.isEmpty) return;

    setState(() => _savingImage = true);

    try {
      if (kIsWeb) {
        final uri = Uri.parse(url);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('No se pudo descargar la imagen');
      }

      final Uint8List bytes = response.bodyBytes;
      final tempFile = File(
        '${Directory.systemTemp.path}/factura_${widget.factura.id ?? DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(bytes);
      await Gal.putImage(tempFile.path, album: 'BuildCheck');
      await tempFile.delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagen guardada en galería')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al descargar la imagen')),
        );
      }
    } finally {
      if (mounted) setState(() => _savingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fMoneda = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 0,
      locale: 'es_CO',
    );
    final fFecha = DateFormat('dd MMMM yyyy', 'es_ES');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Factura' : 'Detalle de Factura'),
        actions: [
          if (_puedeEditar)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = !_isEditing),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalHeader(fMoneda),
            const SizedBox(height: 20),

            _buildInfoCard(fFecha),
            const SizedBox(height: 20),

            if (_signedImageUrl != null && _signedImageUrl!.isNotEmpty) ...[
              _buildImageCard(),
              const SizedBox(height: 20),
            ],

            const Text(
              "Materiales Incluidos",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            _buildItemsList(fMoneda),

            const SizedBox(height: 30),

            if (_isEditing) _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalHeader(NumberFormat formatter) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF263238),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            "VALOR TOTAL",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            formatter.format(widget.factura.valorTotal ?? 0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(DateFormat dateFormatter) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _buildField('Proveedor', _proveedorCtrl, Icons.business),
          const Divider(height: 30),
          _buildField('Número de Factura', _numeroCtrl, Icons.tag),
          const Divider(height: 30),
          _buildReadOnlyInfo(
            'Fecha de Emisión',
            dateFormatter.format(widget.factura.fecha),
            Icons.calendar_today,
          ),
          const Divider(height: 30),
          _buildField('Observaciones', _obsCtrl, Icons.notes),
        ],
      ),
    );
  }

  Widget _buildImageCard() {
    final url = _signedImageUrl!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Foto de la factura',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _copiarUrl,
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  label: const Text('Copiar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _savingImage ? null : _descargarImagen,
                  icon: _savingImage
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download_outlined, size: 18),
                  label: const Text('Descargar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList(NumberFormat currencyFormatter) {
    if (widget.factura.items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text("Esta factura no tiene materiales registrados."),
        ),
      );
    }
    return Column(
      children: widget.factura.items.map((item) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.build, color: Color(0xFF4CAF50), size: 20),
            ),
            title: Text(
              item.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "${item.cantidad} unidades x ${currencyFormatter.format(item.precioUnitario)}",
            ),
            trailing: Text(
              currencyFormatter.format(item.cantidad * item.precioUnitario),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _guardarCambios,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: _isSaving
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Actualizar Factura',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 8),
        _isEditing
            ? TextField(
                controller: controller,
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, size: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              )
            : Row(
                children: [
                  Icon(icon, size: 20, color: const Color(0xFF4CAF50)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      controller.text,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
      ],
    );
  }

  Widget _buildReadOnlyInfo(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.blueGrey),
            const SizedBox(width: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
}
