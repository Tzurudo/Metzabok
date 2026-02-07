import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bluetooth_manager.dart';

class WifiSetupPage extends StatefulWidget {
  const WifiSetupPage({super.key});

  @override
  State<WifiSetupPage> createState() => _WifiSetupPageState();
}

class _WifiSetupPageState extends State<WifiSetupPage> {
  final BluetoothManager _btManager = BluetoothManager();
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWifiCredentials();
  }

  Future<void> _loadWifiCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ssidController.text = prefs.getString('wifi_ssid') ?? '';
      _passwordController.text = prefs.getString('wifi_password') ?? '';
    });
  }

  Future<void> _saveWifiCredentials(String ssid, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wifi_ssid', ssid);
    await prefs.setString('wifi_password', password);
  }

  void _sendBTCommand(String command) async {
    if (!_btManager.isConnected.value) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No conectado a Bluetooth')));
      return;
    }
    _btManager.write(command);
  }

  void _handleSubmit() async {
    String ssid = _ssidController.text.trim();
    String password = _passwordController.text.trim();

    if (ssid.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor completa todos los campos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simular un pequeño delay para feedback visual
    await Future.delayed(const Duration(milliseconds: 500));

    _sendBTCommand('SETWIFI:$ssid:$password');
    await _saveWifiCredentials(ssid, password);

    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración enviada correctamente')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Configurar WiFi"),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Hero(
                tag: 'wifi_icon',
                child: Icon(
                  Icons.wifi_rounded,
                  size: 80,
                  color: Color(0xFFD4AF37),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                "Vincular Metzabok a Internet",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Ingresa los datos de tu red WiFi local. El dispositivo se reiniciará para conectarse.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 40),

              // Formulario
              _buildInputLabel("Nombre de la Red (SSID)"),
              _buildTextField(
                controller: _ssidController,
                hint: "Ej: MiRed_WiFi",
                icon: Icons.wifi,
              ),

              const SizedBox(height: 20),

              _buildInputLabel("Contraseña"),
              _buildTextField(
                controller: _passwordController,
                hint: "Contraseña de tu red",
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        "Enviar al Dispositivo",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Asegúrate de estar cerca del dispositivo y que el Bluetooth esté conectado.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF555555),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFFD4AF37)),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
        ),
      ),
    );
  }
}
