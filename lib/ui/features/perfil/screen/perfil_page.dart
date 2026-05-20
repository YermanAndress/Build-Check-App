import 'package:build_check_app/core/usuario_actual.dart';
import 'package:flutter/material.dart';
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
    _telegramVinculado =
        UsuarioActual.telegramChatId != null &&
        UsuarioActual.telegramChatId!.isNotEmpty;
  }

  Future<void> _abrirBot() async {
    final url = Uri.parse("https://t.me/buildcheck_bot");
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Informacion personal",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 16),
                _InfoRow(
                  icon: Icons.person_outline,
                  label: "Nombre",
                  value: UsuarioActual.nombre ?? "-",
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.email_outlined,
                  label: "Correo",
                  value: UsuarioActual.correo ?? "-",
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  label: "Telefono",
                  value: UsuarioActual.telefono ?? "-",
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.badge_outlined,
                  label: "Rol",
                  value: _formatearRol(UsuarioActual.rol),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Notificaciones por Telegram",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Vincula tu cuenta para recibir reportes y "
                  "eescanear facturas directamente desde Telegram.",
                  style: TextStyle(color: Color(0xFF757575), fontSize: 13),
                ),
                const SizedBox(height: 16),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _telegramVinculado
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _telegramVinculado
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_outlined,
                        color: _telegramVinculado
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFF44336),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _telegramVinculado
                            ? "Cuenta vinculada"
                            : "Cuenta no vinculada",
                        style: TextStyle(
                          color: _telegramVinculado
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFE65100),
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (!_telegramVinculado) ...[
                  const Text(
                    "Pasos para vincular:",
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  const _Paso(
                    numero: "1",
                    texto: 'Toca el boton "Abrir bot en Telegram"',
                  ),
                  const _Paso(numero: "2", texto: 'Escribe /start en el chat"'),
                  const _Paso(
                    numero: "3",
                    texto:
                        'Ingresa tu correo y contraseña cuando el bot te los pida',
                  ),
                  const _Paso(
                    numero: "4",
                    texto: 'Listo - regresa aqui y recarga para ver el estado',
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.send_outlined, size: 18),
                    label: Text(
                      _telegramVinculado
                          ? "Abrir bot en Telegram"
                          : "Vincular con Telegram",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008CCC),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _abrirBot,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatearRol(String? rol) {
    if (rol == null) return "-";
    return rol
        .replaceAll("ROLE_", "")
        .replaceAll("_", " ")
        .toLowerCase()
        .split(" ")
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(" ");
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF757575)),
        const SizedBox(width: 18),
        Text(
          "$label: ",
          style: const TextStyle(color: Color(0xFF757575), fontSize: 13),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
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
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(fontSize: 13, color: Color(0xFF424242)),
            ),
          ),
        ],
      ),
    );
  }
}
