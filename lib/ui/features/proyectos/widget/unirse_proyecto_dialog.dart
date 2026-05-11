import 'package:flutter/material.dart';
import 'package:build_check_app/services/proyecto_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnirseProyectoDialog extends StatefulWidget {
  const UnirseProyectoDialog({super.key});

  @override
  State<UnirseProyectoDialog> createState() => _UnirseProyectoDialogState();
}

class _UnirseProyectoDialogState extends State<UnirseProyectoDialog> {
  final ProyectoService _service = ProyectoService();
  final TextEditingController _tokenCtrl = TextEditingController();
  bool _cargando = false;
  String? _error;

  Future<void> _unirse() async {
    if (_tokenCtrl.text.isEmpty) {
      setState(() => _error = "Ingresa un token válido");
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      final resultado = await _service.unirseAProyecto(_tokenCtrl.text);
      
      // Guardar nuevo token y proyecto ID
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("token", resultado['token']);
      await prefs.setInt("proyectoActual", resultado['proyecto_id']);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Te has unido al proyecto con éxito")),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  @override
  void dispose() {
    _tokenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Unirse a Proyecto",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              "Ingresa el token de invitación que te compartieron",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _tokenCtrl,
              decoration: InputDecoration(
                hintText: "Pega el token aquí",
                prefixIcon: const Icon(Icons.key_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                errorText: _error,
                enabled: !_cargando,
              ),
              maxLines: 3,
              minLines: 2,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _cargando ? null : () => Navigator.pop(context),
                    child: const Text("Cancelar"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _unirse,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                    ),
                    child: _cargando
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : const Text("Unirse"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
