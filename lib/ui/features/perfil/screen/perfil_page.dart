import 'dart:convert';

import 'package:build_check_app/core/api_config.dart';
import 'package:build_check_app/services/auth_header.dart';
import 'package:build_check_app/services/http_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:build_check_app/core/usuario_actual.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  bool _telegramVinculado = false;

  @override
  void initState() {
    super.initState();
    _refrescarEstado();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refrescarEstado();
  }

  void _refrescarEstado() {
    final vinculado =
        UsuarioActual.telegramChatId != null &&
        UsuarioActual.telegramChatId!.isNotEmpty;
    if (mounted && vinculado != _telegramVinculado) {
      setState(() => _telegramVinculado = vinculado);
    }
  }

  Future<void> _abrirBot() async {
    // ← reemplaza buildcheck_bot por el username de tu bot
    final url = Uri.parse("https://t.me/buildcheck_bot");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _verificarVinculacion() async {
    final response = await HttpInterceptor.send(() async {
      final headers = await AuthHeader.getHeaders();
      return http.get(
        Uri.parse(
          '${ApiConfig.baseUrl}/usuarios-service/usuarios/${UsuarioActual.id}',
        ),
        headers: headers,
      );
    });
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final usuarioData = data['usuario'] as Map<String, dynamic>?;
      final chatId = usuarioData?['telegramChatId'] as String?;
      if (chatId != null && chatId.isNotEmpty) {
        await UsuarioActual.setTelegramChatId(chatId);
        if (mounted) {
          setState(() => _telegramVinculado = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Telegram vinculado correctamente'),
              backgroundColor: Color(0xFF4CAF50),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Aun no se detecta la vinculacion. '
                'Asegurate de haber completado el proceso en el bot',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Datos personales ──────────────────────────────
          _Seccion(
            titulo: "Información personal",
            child: Column(
              children: [
                _InfoFila(
                  icon: Icons.person_outline,
                  label: "Nombre",
                  value: UsuarioActual.nombre ?? "-",
                ),
                const SizedBox(height: 12),
                _InfoFila(
                  icon: Icons.email_outlined,
                  label: "Correo",
                  value: UsuarioActual.correo ?? "-",
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Telegram ──────────────────────────────────────
          _Seccion(
            titulo: "Notificaciones por Telegram",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Vincula tu cuenta para recibir reportes semanales "
                  "y usar el escáner de facturas desde Telegram.",
                  style: TextStyle(
                    color: Color(0xFF757575),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),

                // Badge de estado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _telegramVinculado
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _telegramVinculado
                            ? Icons.check_circle_outline
                            : Icons.link_off,
                        color: _telegramVinculado
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF9800),
                        size: 17,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        _telegramVinculado
                            ? "Cuenta vinculada"
                            : "Cuenta no vinculada",
                        style: TextStyle(
                          color: _telegramVinculado
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE65100),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                // Pasos si no está vinculado
                if (!_telegramVinculado) ...[
                  const SizedBox(height: 16),
                  const Text(
                    "Cómo vincularte:",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _Paso(
                    numero: "1",
                    texto: "Toca el botón de abajo para abrir el bot",
                  ),
                  const _Paso(numero: "2", texto: "Escribe /start en el chat"),
                  const _Paso(
                    numero: "3",
                    texto:
                        "Ingresa tu correo y contraseña cuando el bot te los pida",
                  ),
                  const _Paso(
                    numero: "4",
                    texto: "Listo, ya recibirás los reportes automáticamente",
                  ),
                ],

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _telegramVinculado
                          ? "Abrir bot de Telegram"
                          : "Vincular con Telegram",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0088CC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _abrirBot,
                  ),
                ),
                if (!_telegramVinculado) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh_outlined, size: 18),
                      label: const Text("Ya vincule mi cuenta"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0088CC),
                        side: const BorderSide(color: Color(0xFF0088CC)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _verificarVinculacion,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────

class _Seccion extends StatelessWidget {
  final String titulo;
  final Widget child;
  const _Seccion({required this.titulo, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoFila extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoFila({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF9E9E9E)),
        const SizedBox(width: 10),
        Text(
          "$label: ",
          style: const TextStyle(color: Color(0xFF757575), fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: Color(0xFF1A1A1A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _Paso extends StatelessWidget {
  final String numero;
  final String texto;
  const _Paso({required this.numero, required this.texto});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 21,
            height: 21,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFF0088CC),
              shape: BoxShape.circle,
            ),
            child: Text(
              numero,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                texto,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF424242),
                  height: 1.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
