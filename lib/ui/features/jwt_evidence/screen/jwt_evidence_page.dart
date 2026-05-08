import 'package:flutter/material.dart';
import 'package:build_check_app/services/jwt_auth_service.dart';

/// Vista de evidencia JWT — Taller de Autenticación.
///
/// Muestra los datos almacenados localmente (shared_preferences y secure_storage),
/// el estado de la sesión, y permite login y cierre de sesión contra el backend
/// de BuildCheck.
class JwtEvidencePage extends StatefulWidget {
  const JwtEvidencePage({super.key});

  @override
  State<JwtEvidencePage> createState() => _JwtEvidencePageState();
}

class _JwtEvidencePageState extends State<JwtEvidencePage>
    with SingleTickerProviderStateMixin {
  final _authService = JwtAuthService();

  // Controllers
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();

  // State
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Datos almacenados
  String? _storedName;
  String? _storedEmail;
  String? _storedRol;
  String? _storedTheme;
  String? _storedLang;
  String? _tokenStatus;
  String? _tokenPreview;
  String? _refreshTokenStatus;
  bool _hasSession = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
    _loadStoredData();
  }

  @override
  void dispose() {
    _correoController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadStoredData() async {
    final userData = await JwtAuthService.getStoredUserData();
    final accessToken = await JwtAuthService.getAccessToken();
    final refreshToken = await JwtAuthService.getRefreshToken();
    final hasSession = await JwtAuthService.hasActiveSession();

    setState(() {
      _storedName = userData['name'];
      _storedEmail = userData['email'];
      _storedRol = userData['rol'];
      _storedTheme = userData['theme'];
      _storedLang = userData['lang'];
      _hasSession = hasSession;

      // Access token
      if (accessToken != null && accessToken.isNotEmpty) {
        _tokenStatus = 'Token presente ✅';
        _tokenPreview = accessToken.length > 20
            ? '${accessToken.substring(0, 10)}...${accessToken.substring(accessToken.length - 10)}'
            : accessToken;
      } else {
        _tokenStatus = 'Sin token ❌';
        _tokenPreview = null;
      }

      // Refresh token
      if (refreshToken != null && refreshToken.isNotEmpty) {
        _refreshTokenStatus = 'Presente ✅';
      } else {
        _refreshTokenStatus = 'Ausente ❌';
      }
    });
  }

  Future<void> _handleLogin() async {
    if (_correoController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Completa todos los campos');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _authService.login(
        correo: _correoController.text.trim(),
        password: _passwordController.text.trim(),
      );
      setState(() => _successMessage = '¡Login exitoso! Token JWT almacenado.');
      _correoController.clear();
      _passwordController.clear();
      await _loadStoredData();
    } catch (e) {
      setState(
        () => _errorMessage = e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    await JwtAuthService.logout();
    await _loadStoredData();

    setState(() {
      _isLoading = false;
      _successMessage = 'Sesión cerrada — tokens y datos eliminados';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1629),
      appBar: AppBar(
        title: const Text(
          'Evidencia JWT — Taller',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF141B40),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ─── Estado de Sesión ───
              _buildSessionStatusCard(),
              const SizedBox(height: 16),

              if (_hasSession) ...[
                // ─── Datos del usuario (SharedPreferences) ───
                _buildStoredDataCard(),
                const SizedBox(height: 16),

                // ─── Token JWT (SecureStorage) ───
                _buildTokenInfoCard(),
                const SizedBox(height: 16),

                // ─── Detalle de almacenamiento ───
                _buildStorageDetailsCard(),
                const SizedBox(height: 24),

                // ─── Botón cerrar sesión ───
                _buildLogoutButton(),
              ] else ...[
                // ─── Formulario de login ───
                _buildLoginFormCard(),
              ],

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Estado de sesión
  // ═══════════════════════════════════════════════════
  Widget _buildSessionStatusCard() {
    return _glassCard(
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _hasSession
                    ? [const Color(0xFF4CAF50), const Color(0xFF2E7D32)]
                    : [const Color(0xFFFF5252), const Color(0xFFD32F2F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              _hasSession ? Icons.verified_user : Icons.shield_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _hasSession ? 'Sesión Activa' : 'Sin Sesión',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _tokenStatus ?? 'Verificando...',
                  style: const TextStyle(
                    color: Color(0xAAFFFFFF),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Datos de usuario — SharedPreferences
  // ═══════════════════════════════════════════════════
  Widget _buildStoredDataCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            Icons.person_outline,
            'Datos de Usuario',
            const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 4),
          const Text(
            'Leídos desde SharedPreferences (no sensible)',
            style: TextStyle(
              color: Color(0x66FFFFFF),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
          _dataRow(Icons.badge_outlined, 'Nombre', _storedName),
          _dataRow(Icons.email_outlined, 'Correo', _storedEmail),
          _dataRow(Icons.admin_panel_settings_outlined, 'Rol', _storedRol),
          _dataRow(Icons.palette_outlined, 'Tema', _storedTheme),
          _dataRow(Icons.language, 'Idioma', _storedLang),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Token JWT — SecureStorage
  // ═══════════════════════════════════════════════════
  Widget _buildTokenInfoCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            Icons.vpn_key_outlined,
            'Tokens JWT',
            const Color(0xFFFF9800),
          ),
          const SizedBox(height: 4),
          const Text(
            'Leídos desde flutter_secure_storage (sensible)',
            style: TextStyle(
              color: Color(0x66FFFFFF),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),

          // Access Token
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x4D000000),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x4DFF9800)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'access_token (preview)',
                  style: TextStyle(
                    color: Color(0x80FFFFFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _tokenPreview ?? 'N/A',
                  style: const TextStyle(
                    color: Color(0xFFFF9800),
                    fontSize: 14,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Refresh Token status
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x4D000000),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x4D2196F3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.refresh, color: Color(0xFF2196F3), size: 20),
                const SizedBox(width: 10),
                const Text(
                  'refresh_token: ',
                  style: TextStyle(
                    color: Color(0x80FFFFFF),
                    fontSize: 13,
                  ),
                ),
                Text(
                  _refreshTokenStatus ?? 'N/A',
                  style: const TextStyle(
                    color: Color(0xFF2196F3),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Detalle de almacenamiento
  // ═══════════════════════════════════════════════════
  Widget _buildStorageDetailsCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            Icons.storage_outlined,
            'Resumen de Almacenamiento',
            const Color(0xFF2196F3),
          ),
          const SizedBox(height: 16),
          _storageRow(
            'SharedPreferences',
            'nombre, correo, rol, tema, idioma',
            Icons.folder_open,
            const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 12),
          _storageRow(
            'Flutter Secure Storage',
            'access_token, refresh_token',
            Icons.lock_outline,
            const Color(0xFFFF9800),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Formulario de login
  // ═══════════════════════════════════════════════════
  Widget _buildLoginFormCard() {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _sectionHeader(
            Icons.login,
            'Iniciar Sesión',
            const Color(0xFF7C4DFF),
          ),
          const SizedBox(height: 8),
          const Text(
            'Backend BuildCheck — JWT + RSA',
            style: TextStyle(
              color: Color(0x66FFFFFF),
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 20),

          // Mensajes de estado
          if (_errorMessage != null) _statusMessage(_errorMessage!, isError: true),
          if (_successMessage != null)
            _statusMessage(_successMessage!, isError: false),

          _textField(
            controller: _correoController,
            label: 'Correo electrónico',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),

          _textField(
            controller: _passwordController,
            label: 'Contraseña',
            icon: Icons.lock_outline,
            obscure: true,
          ),
          const SizedBox(height: 24),

          _primaryButton(
            text: 'Iniciar Sesión',
            isLoading: _isLoading,
            onPressed: _handleLogin,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  Botón cerrar sesión
  // ═══════════════════════════════════════════════════
  Widget _buildLogoutButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _handleLogout,
        icon: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.logout, size: 22),
        label: Text(
          _isLoading ? 'Cerrando...' : 'Cerrar Sesión',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD32F2F),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════
  //  HELPERS (widgets reutilizables)
  // ═══════════════════════════════════════════════════

  Widget _glassCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x12FFFFFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1AFFFFFF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _dataRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0x80FFFFFF), size: 20),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 14),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _storageRow(String title, String items, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  items,
                  style: const TextStyle(
                    color: Color(0x99FFFFFF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0x80FFFFFF)),
        prefixIcon: Icon(icon, color: const Color(0x80FFFFFF), size: 22),
        filled: true,
        fillColor: const Color(0x14FFFFFF),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x26FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String text,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _statusMessage(String message, {required bool isError}) {
    final color = isError ? const Color(0xFFD32F2F) : const Color(0xFF4CAF50);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
