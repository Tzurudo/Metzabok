import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import 'package:shared_preferences/shared_preferences.dart';
>>>>>>> 5c92128 (Initial commit)
import 'bluetooth_page.dart';
import 'wifi_page.dart';
import 'settings_page.dart';
import 'about_page.dart';
<<<<<<< HEAD
import 'sms_page.dart';
import 'automation_page.dart';

=======
import 'automation_page.dart';
>>>>>>> 5c92128 (Initial commit)
import '../services/bluetooth_manager.dart';

class CerebroPage extends StatefulWidget {
  const CerebroPage({super.key});

  @override
  State<CerebroPage> createState() => _CerebroPageState();
}

class _CerebroPageState extends State<CerebroPage> {
  bool _canPop = false;
  final BluetoothManager _btManager = BluetoothManager();
<<<<<<< HEAD
=======
  bool _hasConfiguredWiFi = false;

  // Paleta Premium: Blanco, Oro y Plata
  static const Color premiumGold = Color.fromARGB(255, 41, 122, 243);
  static const Color darkSilver = Color.fromARGB(255, 37, 37, 37);
>>>>>>> 5c92128 (Initial commit)

  @override
  void initState() {
    super.initState();
    _btManager.isConnected.addListener(_updateState);
    _btManager.isGlobalAuto.addListener(_updateState);
<<<<<<< HEAD
=======
    _btManager.isWiFiMode.addListener(_updateState);
    _loadConfiguredIP();
  }

  Future<void> _loadConfiguredIP() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('metzabok_ip');
    setState(() {
      _hasConfiguredWiFi = ip != null && ip.isNotEmpty;
      // Si hay WiFi configurado, intentar conectar automáticamente
      if (_hasConfiguredWiFi) {
        _btManager.connectWiFi(ip!);
      }
    });
>>>>>>> 5c92128 (Initial commit)
  }

  @override
  void dispose() {
    _btManager.isConnected.removeListener(_updateState);
    _btManager.isGlobalAuto.removeListener(_updateState);
<<<<<<< HEAD
=======
    _btManager.isWiFiMode.removeListener(_updateState);
>>>>>>> 5c92128 (Initial commit)
    super.dispose();
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  Widget botonMenu(
    BuildContext context,
    String texto,
    IconData icono,
    Widget destino,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icono),
        label: Text(texto),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => destino));
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    // Paleta Premium: Blanco, Oro y Plata
    const Color premiumGold = Color.fromARGB(255, 41, 122, 243);
    const Color darkSilver = Color.fromARGB(255, 37, 37, 37);

=======
>>>>>>> 5c92128 (Initial commit)
    return PopScope(
      canPop: _canPop,
      onPopInvoked: (didPop) async {
        if (didPop) return;

<<<<<<< HEAD
        final isAuto = BluetoothManager().isGlobalAuto.value;
=======
        final isAuto = _btManager.isGlobalAuto.value;
        final isWiFi = _btManager.isWiFiMode.value;
>>>>>>> 5c92128 (Initial commit)
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: const Text("¿Salir del Menú?"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text("Modo actual: "),
                      Text(
                        isAuto ? "AUTOMÁTICO" : "MANUAL",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isAuto ? Colors.blue : Colors.orange,
                        ),
                      ),
<<<<<<< HEAD
=======
                      if (isWiFi) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            "WiFi",
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
>>>>>>> 5c92128 (Initial commit)
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
<<<<<<< HEAD
                    "¿Estás seguro de que quieres salir dejando el sistema en modo ${isAuto ? 'AUTOMÁTICO' : 'MANUAL'}?",
=======
                    "¿Estás seguro de que quieres salir dejando el sistema en modo ${isAuto ? 'AUTOMÁTICO' : 'MANUAL'}${isWiFi ? ' (WiFi)' : ''}?",
>>>>>>> 5c92128 (Initial commit)
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAuto
<<<<<<< HEAD
                        ? "El calendario seguirá ejecutándose."
=======
                        ? "El calendario seguirá ejecutándose${isWiFi ? ' vía WiFi' : ''}."
>>>>>>> 5c92128 (Initial commit)
                        : "El calendario NO se ejecutará.",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
<<<<<<< HEAD
=======

>>>>>>> 5c92128 (Initial commit)
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text("Cancelar"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    "Salir",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );

        if (shouldPop == true) {
          setState(() {
            _canPop = true;
          });
          if (mounted) {
<<<<<<< HEAD
=======
            // ignore: use_build_context_synchronously
>>>>>>> 5c92128 (Initial commit)
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Metzabok",
            style: TextStyle(
              color: Color(0xFFD4AF37), // Oro
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: darkSilver),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
          actions: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  if (Scaffold.of(context).hasDrawer) {
                    Scaffold.of(context).openDrawer();
                  }
                },
              ),
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Color(0xFFE0E0E0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(
                  'Menú',
                  style: TextStyle(
                    color: premiumGold,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: darkSilver),
                title: const Text(
                  'Configuración',
                  style: TextStyle(color: darkSilver),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.info, color: darkSilver),
                title: const Text(
                  'Acerca de',
                  style: TextStyle(color: darkSilver),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
              ),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFF5F5F5)],
            ),
          ),
<<<<<<< HEAD
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Etiqueta informativa RESTAURADA (Solicitud de usuario)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFD4AF37),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Importante: Asegúrate de estar conectado a la misma red WiFi que tu Metzabok y tener el Bluetooth encendido.",
                          style: TextStyle(
                            color: Color.fromARGB(255, 60, 60, 60),
                            fontSize: 13,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Panel de Control Global (Bluetooth)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _btManager.isConnected.value
                        ? (_btManager.isGlobalAuto.value
                              ? Colors.blue[50]
                              : Colors.orange[50])
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: _btManager.isConnected.value
                          ? (_btManager.isGlobalAuto.value
                                ? Colors.blue[200]!
                                : Colors.orange[200]!)
                          : Colors.grey[400]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _btManager.isConnected.value
                                ? (_btManager.isGlobalAuto.value
                                      ? Icons.auto_mode
                                      : Icons.touch_app)
                                : Icons.bluetooth_disabled,
                            color: _btManager.isConnected.value
                                ? (_btManager.isGlobalAuto.value
                                      ? Colors.blue
                                      : Colors.orange)
                                : Colors.grey,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _btManager.isConnected.value
                                      ? (_btManager.isGlobalAuto.value
                                            ? "MODO AUTOMÁTICO"
                                            : "MODO MANUAL")
                                      : "DESCONECTADO",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _btManager.isConnected.value
                                        ? (_btManager.isGlobalAuto.value
                                              ? Colors.blue[800]
                                              : Colors.orange[800])
                                        : Colors.grey[700],
                                  ),
                                ),
                                Text(
                                  _btManager.isConnected.value
                                      ? (_btManager.isGlobalAuto.value
                                            ? "Controlado por Horarios"
                                            : "Control Manual Habilitado")
                                      : "Conéctate para controlar",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_btManager.isConnected.value)
                            Switch(
                              value: _btManager.isGlobalAuto.value,
                              activeColor: Colors.blue,
                              inactiveThumbColor: Colors.orange,
                              onChanged: (val) {
                                _btManager.write(
                                  val ? "GLOBAL_AUTO" : "GLOBAL_MANUAL",
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildPremiumButton(
                  context,
                  "Comunicación WiFi",
                  Icons.wifi,
                  const WifiPage(),
                  premiumGold,
                ),
                const SizedBox(height: 20),
                _buildPremiumButton(
                  context,
                  "Vincular con Metzabok",
                  Icons.bluetooth,
                  const BluetoothPage(),
                  premiumGold,
                ),
                const SizedBox(height: 20),
                _buildPremiumButton(
                  context,
                  "Configurar SMS",
                  Icons.sms,
                  const SmsPage(),
                  premiumGold,
                ),
                const SizedBox(height: 20),
                _buildPremiumButton(
                  context,
                  "Modo Automático",
                  Icons.auto_mode,
                  const AutomationPage(),
                  const Color(
                    0xFFD4AF37,
                  ), // Color Oro para resaltar la nueva función
                ),
                const SizedBox(height: 20),
              ],
=======
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Etiqueta informativa RESTAURADA (Solicitud de usuario)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: const Color(0xFFD4AF37),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFFD4AF37),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Importante: Asegúrate de estar conectado a la misma red WiFi que tu Metzabok y tener el Bluetooth encendido.",
                            style: TextStyle(
                              color: Color.fromARGB(255, 60, 60, 60),
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Reemplaza desde la línea 156 (el Container que dice "Panel de Control Global (Bluetooth)")
                  // hasta la línea 219 (justo antes del _buildPremiumButton)

                  // Panel de Estado de Conexión (Informativo)
                  if (_btManager.isConnected.value ||
                      _btManager.isWiFiMode.value)
                    Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getPanelColor(),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: _getBorderColor(), width: 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getStatusIcon(),
                            color: _getStatusColor(),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _getStatusText(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: _getTextColor(),
                            ),
                          ),
                        ],
                      ),
                    ),

                  _buildPremiumButton(
                    context,
                    "Comunicación WiFi",
                    Icons.wifi,
                    const WifiPage(),
                    premiumGold,
                  ),
                  const SizedBox(height: 12),
                  _buildPremiumButton(
                    context,
                    "Vincular con Metzabok",
                    Icons.bluetooth,
                    const BluetoothPage(),
                    premiumGold,
                  ),

                  const SizedBox(height: 12),
                  _buildPremiumButton(
                    context,
                    "Modo Automático",
                    Icons.auto_mode,
                    const AutomationPage(),
                    const Color(
                      0xFFD4AF37,
                    ), // Color Oro para resaltar la nueva función
                  ),

                  const SizedBox(height: 12),
                ],
              ),
>>>>>>> 5c92128 (Initial commit)
            ),
          ),
        ),
      ),
    );
  }

<<<<<<< HEAD
=======
  Color _getPanelColor() {
    if (_btManager.isConnected.value || _btManager.isWiFiMode.value) {
      return const Color(0xFFE8F5E9);
    }
    return const Color(0xFFFFEBEE);
  }

  Color _getBorderColor() {
    if (_btManager.isConnected.value || _btManager.isWiFiMode.value) {
      return Colors.green;
    }
    return Colors.red;
  }

  IconData _getStatusIcon() {
    if (_btManager.isConnected.value) {
      return Icons.bluetooth_connected;
    } else if (_btManager.isWiFiMode.value) {
      return Icons.wifi;
    }
    return Icons.bluetooth_disabled;
  }

  Color _getStatusColor() {
    if (_btManager.isConnected.value || _btManager.isWiFiMode.value) {
      return Colors.green;
    }
    return Colors.red;
  }

  String _getStatusText() {
    if (_btManager.isConnected.value) {
      return "Conectado (Bluetooth)";
    } else if (_btManager.isWiFiMode.value) {
      return "Conectado (WiFi)";
    }
    return "Desconectado";
  }

  String _getSubtitleText() {
    if (_btManager.isConnected.value || _btManager.isWiFiMode.value) {
      return _btManager.isGlobalAuto.value
          ? "Modo: AUTOMÁTICO"
          : "Modo: MANUAL";
    }
    return "Conecta tu dispositivo para continuar";
  }

  Color _getTextColor() {
    if (_btManager.isConnected.value || _btManager.isWiFiMode.value) {
      return Colors.black87;
    }
    return Colors.red;
  }

  void _toggleGlobalMode(bool value) {
    _btManager.isGlobalAuto.value = value;

    // Enviar comando por Bluetooth o WiFi
    final command = value ? "GLOBAL_AUTO" : "GLOBAL_MANUAL";

    if (_btManager.isConnected.value) {
      _btManager.write(command);
    } else if (_btManager.isWiFiMode.value) {
      _btManager.sendCommand(command);
    }

    setState(() {});
  }

>>>>>>> 5c92128 (Initial commit)
  Widget _buildPremiumButton(
    BuildContext context,
    String texto,
    IconData icono,
    Widget destino,
    Color color,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => destino));
          },
          child: Padding(
<<<<<<< HEAD
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            child: Row(
              children: [
                Icon(icono, color: color, size: 28),
                const SizedBox(width: 20),
                Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 16,
=======
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              children: [
                Icon(icono, color: color, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    texto,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: 14,
>>>>>>> 5c92128 (Initial commit)
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
