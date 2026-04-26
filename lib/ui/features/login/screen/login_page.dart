import 'package:flutter/material.dart';

import 'package:build_check_app/ui/features/login/screen/recuperar_password_page.dart';
import 'package:build_check_app/ui/features/login/screen/registrarse_page.dart';
import 'package:build_check_app/ui/features/login/widget/login_items.dart';
import 'package:build_check_app/services/login_service.dart';
import 'package:build_check_app/ui/main_screen.dart';

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
