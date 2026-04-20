import 'dart:convert';

import 'package:build_check_app/core/api_config.dart';
import 'package:build_check_app/services/rsa_service.dart';
import 'package:build_check_app/ui/features/login/screen/recuperar_password_page.dart';
import 'package:build_check_app/ui/features/login/screen/registrarse_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widget/login_items.dart';
import '../../../../services/login_service.dart';
import '../../../main_screen.dart';

class Loginpage extends StatefulWidget {
  const Loginpage({super.key});

  @override
  State<Loginpage> createState() => _LoginpageState();
}

class _LoginpageState extends State<Loginpage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  void iniciarSesion() async {
    setState(() => loading = true);

    final auth = LoginService();

    try {
      await auth.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
      );
    }

    setState(() => loading = false);
  }

  void probarRSA() async {
    try {
      final rsa = RsaService();

      // 1. Obtener llave pública directamente
      final url = Uri.parse('${ApiConfig.usuarios}/public-key');
      final res = await http.get(url);
      print('✅ Llave pública recibida: ${res.statusCode}');

      final publicKey = jsonDecode(res.body)['publicKey'] as String;
      print('🔑 Primeros 50 chars: ${publicKey.substring(0, 50)}');

      // 2. Cargar y encriptar
      rsa.loadPublicKey(publicKey);

      final encriptado = rsa.encrypt('hola@gmail.com');
      print('🔒 Encriptado (primeros 50): ${encriptado.substring(0, 50)}...');
      print('📏 Longitud: ${encriptado.length}');
      print('✅ RSA funciona correctamente en Flutter');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ RSA OK - Revisa la consola'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('❌ Error RSA: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF141B40),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const LoginLogo(),
                const SizedBox(height: 20),
                const LoginTitle(),
                const SizedBox(height: 40),

                LoginInput(
                  label: "Correo electrónico",
                  controller: emailController,
                ),
                const SizedBox(height: 20),

                LoginInput(
                  label: "Contraseña",
                  controller: passwordController,
                  obscure: true,
                ),
                const SizedBox(height: 30),

                LoginButton(
                  text: "Iniciar Sesión",
                  loading: loading,
                  onPressed: iniciarSesion,
                ),
                const SizedBox(height: 10),

                // ── Botón temporal de prueba RSA ──────────────────────
                TextButton(
                  onPressed: probarRSA,
                  child: const Text(
                    'Probar RSA',
                    style: TextStyle(color: Colors.yellow),
                  ),
                ),
                // ── Eliminar el botón de arriba en producción ─────────

                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "¿Olvidaste tu contraseña?",
                      style: TextStyle(color: Colors.white70),
                    ),
                    LoginLink(
                      text: ' Recuperar',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RecuperarpasswordPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "¿No tienes una cuenta?",
                      style: TextStyle(color: Colors.white70),
                    ),
                    LoginLink(
                      text: ' Regístrarte',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegistrarsePage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}