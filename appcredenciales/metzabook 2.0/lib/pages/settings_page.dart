import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bluetooth_classic/models/device.dart';
import '../services/bluetooth_manager.dart';
<<<<<<< HEAD
=======
import 'wifi_setup_page.dart';
>>>>>>> 5c92128 (Initial commit)

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final BluetoothManager _btManager = BluetoothManager();

  final TextEditingController _foco1Controller = TextEditingController();
  final TextEditingController _foco2Controller = TextEditingController();
  final TextEditingController _foco3Controller = TextEditingController();
  final TextEditingController _foco4Controller = TextEditingController();

  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
<<<<<<< HEAD
  final TextEditingController _smsController = TextEditingController();
=======
>>>>>>> 5c92128 (Initial commit)

  StreamSubscription<Device>? _scanSubscription;
  StreamSubscription<String>? _dataSubscription;
  Timer? _scanTimeoutTimer;
<<<<<<< HEAD
  List<Device> _devices = [];
  bool isConnecting = false;
=======

  List<Device> _devices = [];
  bool isConnecting = false;
  bool _permissionsReady = false;
  bool _isScanning = false;
>>>>>>> 5c92128 (Initial commit)

  @override
  void initState() {
    super.initState();
<<<<<<< HEAD
    _loadLabels();
    _loadWifiCredentials();
    _initBluetooth();

    _btManager.isConnected.addListener(_onConnectionChanged);
    if (_btManager.isConnected.value) {
      _subscribeToData();
=======

    _loadLabels();
    _loadWifiCredentials();

    _btManager.isConnected.addListener(_onConnectionChanged);

    _initBluetoothOnce();
  }

  // ============================
  // Bluetooth Init
  // ============================
  Future<void> _initBluetoothOnce() async {
    try {
      await _btManager.initPermissions();
      _permissionsReady = true;

      if (_btManager.isConnected.value) {
        _subscribeToData();
        return;
      }

      await _startScan();
    } catch (e) {
      debugPrint("Error init bluetooth: $e");
>>>>>>> 5c92128 (Initial commit)
    }
  }

  void _onConnectionChanged() {
<<<<<<< HEAD
    if (mounted) setState(() {});
=======
    if (!mounted) return;

    setState(() {});

>>>>>>> 5c92128 (Initial commit)
    if (_btManager.isConnected.value) {
      _subscribeToData();
    } else {
      _dataSubscription?.cancel();
<<<<<<< HEAD
=======
      _dataSubscription = null;
>>>>>>> 5c92128 (Initial commit)
    }
  }

  void _subscribeToData() {
    _dataSubscription?.cancel();
    _dataSubscription = _btManager.deviceDataStream.listen(_processLine);
  }

  void _processLine(String line) {
    if (line.isEmpty || !mounted) return;
<<<<<<< HEAD
=======

>>>>>>> 5c92128 (Initial commit)
    debugPrint('Procesando línea BT: $line');

    if (line.contains('WIFI SET')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('WiFi configurado correctamente en el dispositivo'),
        ),
      );
    } else if (line.contains('CMD ERROR')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comando inválido (cmd error)')),
      );
    }
  }

<<<<<<< HEAD
  Future<void> _loadLabels() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _foco1Controller.text =
            prefs.getString('foco1_label') ?? 'Interruptor 1';
        _foco2Controller.text =
            prefs.getString('foco2_label') ?? 'Interruptor 2';
        _foco3Controller.text =
            prefs.getString('foco3_label') ?? 'Interruptor 3';
        _foco4Controller.text =
            prefs.getString('foco4_label') ?? 'Interruptor 4';
      });
    }
=======
  // ============================
  // SharedPreferences
  // ============================
  Future<void> _loadLabels() async {
    if (!mounted) return;

    final names = _btManager.channelNames.value;
    setState(() {
      _foco1Controller.text = names[0];
      _foco2Controller.text = names[1];
      _foco3Controller.text = names[2];
      _foco4Controller.text = names[3];
    });
>>>>>>> 5c92128 (Initial commit)
  }

  Future<void> _loadWifiCredentials() async {
    final prefs = await SharedPreferences.getInstance();
<<<<<<< HEAD
    if (mounted) {
      setState(() {
        _ssidController.text = prefs.getString('wifi_ssid') ?? '';
        _passwordController.text = prefs.getString('wifi_password') ?? '';
        _ipController.text = prefs.getString('metzabok_ip') ?? 'metzabok.local';
        _smsController.text = prefs.getString('sms_number') ?? '';
      });
    }
  }

  Future<void> _saveLabels() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('foco1_label', _foco1Controller.text);
    await prefs.setString('foco2_label', _foco2Controller.text);
    await prefs.setString('foco3_label', _foco3Controller.text);
    await prefs.setString('foco4_label', _foco4Controller.text);
    await prefs.setString('sms_number', _smsController.text.trim());

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración guardada exitosamente')),
      );
    }
  }

  Future<void> _saveWifiCredentials(String ssid, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wifi_ssid', ssid);
    await prefs.setString('wifi_password', password);
=======
    if (!mounted) return;

    setState(() {
      _ssidController.text = prefs.getString('wifi_ssid') ?? '';
      _passwordController.text = prefs.getString('wifi_password') ?? '';
      _ipController.text = prefs.getString('metzabok_ip') ?? 'metzabok.local';
    });
  }

  Future<void> _saveLabels() async {
    await _btManager.updateChannelName(0, _foco1Controller.text.trim());
    await _btManager.updateChannelName(1, _foco2Controller.text.trim());
    await _btManager.updateChannelName(2, _foco3Controller.text.trim());
    await _btManager.updateChannelName(3, _foco4Controller.text.trim());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuración guardada exitosamente')),
    );
>>>>>>> 5c92128 (Initial commit)
  }

  Future<void> _saveIp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('metzabok_ip', _ipController.text.trim());
<<<<<<< HEAD
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('IP/Host guardado exitosamente')),
      );
    }
  }

  void _initBluetooth() async {
    await _btManager.initPermissions();
    _startScan();
  }

  Future<List<Device>> _startScan() async {
    if (mounted) setState(() => _devices = []);

    try {
      List<Device> pairedDevices = await _btManager.getPairedDevices();
      if (mounted) {
        setState(() => _devices = pairedDevices);
=======

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('IP/Host guardado exitosamente')),
    );
  }

  // ============================
  // Scan Logic
  // ============================
  Future<List<Device>> _startScan() async {
    if (!_permissionsReady) {
      await _initBluetoothOnce();
      return _devices;
    }

    if (_btManager.isConnected.value) {
      // No escanear si ya está conectado
      return _devices;
    }

    if (_isScanning) return _devices;

    if (!mounted) return _devices;

    setState(() {
      _devices = [];
      _isScanning = true;
    });

    // 1) Primero: dispositivos vinculados
    try {
      final pairedDevices = await _btManager.getPairedDevices();
      if (mounted) {
        setState(() {
          for (final d in pairedDevices) {
            if (!_devices.any((x) => x.address == d.address)) {
              _devices.add(d);
            }
          }
        });
>>>>>>> 5c92128 (Initial commit)
      }
    } catch (e) {
      debugPrint("Error obteniendo vinculados: $e");
    }

<<<<<<< HEAD
=======
    // 2) Luego: escaneo
>>>>>>> 5c92128 (Initial commit)
    try {
      await _scanSubscription?.cancel();
      _scanSubscription = _btManager.onDeviceDiscovered().listen((device) {
        if (!mounted) return;
<<<<<<< HEAD
        setState(() {
          final exists = _devices.any((d) => d.address == device.address);
          if (!exists) {
            _devices.add(device);
          }
        });
=======

        // Optimización: Solo llamar a setState si el dispositivo es NUEVO
        final exists = _devices.any((d) => d.address == device.address);
        if (!exists) {
          setState(() {
            _devices.add(device);
          });
        }
>>>>>>> 5c92128 (Initial commit)
      });

      await _btManager.startScan();

      _scanTimeoutTimer?.cancel();
      _scanTimeoutTimer = Timer(const Duration(seconds: 15), () async {
<<<<<<< HEAD
        if (mounted) {
          await _btManager.stopScan();
        }
=======
        await _stopScan();
>>>>>>> 5c92128 (Initial commit)
      });

      return _devices;
    } catch (e) {
      debugPrint("Error escaneando: $e");
<<<<<<< HEAD
=======
      await _stopScan();
>>>>>>> 5c92128 (Initial commit)
      return _devices;
    }
  }

<<<<<<< HEAD
  Future<void> _connectToDevice(Device device) async {
=======
  Future<void> _stopScan() async {
    try {
      await _btManager.stopScan();
    } catch (_) {}

    await _scanSubscription?.cancel();
    _scanSubscription = null;

    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = null;

    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  // ============================
  // Connect
  // ============================
  Future<void> _connectToDevice(Device device) async {
    // IMPORTANT: detener scan antes de conectar
    await _stopScan();

>>>>>>> 5c92128 (Initial commit)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Conectando..."),
              ],
            ),
          ),
        );
      },
    );

    if (mounted) setState(() => isConnecting = true);

    try {
      await _btManager.connect(device.address, device.name ?? "Unknown");

      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) setState(() => isConnecting = false);
    } catch (e) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
<<<<<<< HEAD
=======

>>>>>>> 5c92128 (Initial commit)
      if (mounted) {
        setState(() => isConnecting = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error al conectar: $e")));
      }
    }
  }

<<<<<<< HEAD
  void _sendBTCommand(String command) async {
    if (!_btManager.isConnected.value) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No conectado a Bluetooth')));
      return;
    }
    _btManager.write(command);
  }

  void _showWifiDialog() {
    bool obscurePassword = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Pasar internet a Metzabok'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Ingresa los datos de tu red WiFi para enviarlos al dispositivo.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _ssidController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Red (SSID)',
                      hintText: 'Ej: MiCasaWiFi',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.wifi),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      hintText: 'Tu contraseña WiFi',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: obscurePassword,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    String ssid = _ssidController.text.trim();
                    String password = _passwordController.text.trim();
                    if (ssid.isNotEmpty && password.isNotEmpty) {
                      _sendBTCommand('SETWIFI:$ssid:$password');
                      _saveWifiCredentials(ssid, password);
                      Navigator.of(context).pop();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Por favor llena ambos campos'),
                        ),
                      );
                    }
                  },
                  child: const Text('Pasar Internet'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    _scanTimeoutTimer?.cancel();
    _btManager.isConnected.removeListener(_onConnectionChanged);
    _dataSubscription?.cancel();
    _btManager.stopScan();
=======
  // ============================
  // Dispose
  // ============================
  @override
  void dispose() {
    _stopScan();

    _btManager.isConnected.removeListener(_onConnectionChanged);
    _dataSubscription?.cancel();
    _dataSubscription = null;
>>>>>>> 5c92128 (Initial commit)

    _foco1Controller.dispose();
    _foco2Controller.dispose();
    _foco3Controller.dispose();
    _foco4Controller.dispose();
<<<<<<< HEAD
    _ssidController.dispose();
    _passwordController.dispose();
    _ipController.dispose();
    _smsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool connected = _btManager.isConnected.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Configuración",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFFD4AF37),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF757575),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF757575)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionHeader("Personalización", Icons.edit),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildTextField(_foco1Controller, "Nombre Interruptor 1"),
                      _buildTextField(_foco2Controller, "Nombre Interruptor 2"),
                      _buildTextField(_foco3Controller, "Nombre Interruptor 3"),
                      _buildTextField(_foco4Controller, "Nombre Interruptor 4"),
                      _buildTextField(
                        _smsController,
                        "Número de Metzabok (SMS)",
                        isPhone: true,
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("Guardar Configuración"),
                        onPressed: _saveLabels,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 45),
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),
              _buildSectionHeader("Conexión Bluetooth", Icons.bluetooth),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: connected
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: connected ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Text(
                          connected
                              ? "DIspositivo Conectado"
                              : "Dispositivo Desconectado",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: connected
                                ? Colors.green[700]
                                : Colors.red[700],
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (!connected) ...[
                        ElevatedButton.icon(
                          onPressed: () {
                            _initBluetooth();
                          },
                          icon: const Icon(Icons.search),
                          label: const Text("Buscar Dispositivos"),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 45),
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFD4AF37),
                            side: const BorderSide(color: Color(0xFFD4AF37)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (_devices.isNotEmpty) ...[
                          const Text(
                            "Dispositivos encontrados:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5),
                          Container(
                            height: 150,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _devices.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) => ListTile(
                                title: Text(
                                  _devices[i].name ?? "Desconocido",
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  _devices[i].address,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: const Icon(Icons.link, size: 20),
                                dense: true,
                                onTap: () => _connectToDevice(_devices[i]),
                              ),
                            ),
                          ),
                        ],
                      ] else ...[
                        ElevatedButton.icon(
                          onPressed: () => _btManager.disconnect(),
                          icon: const Icon(Icons.bluetooth_disabled),
                          label: const Text("Desconectar"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 45),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),
              _buildSectionHeader("Configuración WiFi", Icons.wifi),
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        "Envía las credenciales de tu red WiFi al dispositivo Metzabok o configura su dirección IP manualmente.",
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(
                        _ipController,
                        "IP o Host (ej: 192.168.1.15)",
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text("Guardar IP/Host"),
                        onPressed: _saveIp,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 45),
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFD4AF37),
                          side: const BorderSide(color: Color(0xFFD4AF37)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: connected ? _showWifiDialog : null,
                        icon: const Icon(Icons.send),
                        label: const Text("Pasar internet a Metzabok"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 45),
                          backgroundColor: const Color(0xFFD4AF37),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
=======

    _ssidController.dispose();
    _passwordController.dispose();
    _ipController.dispose();

    super.dispose();
  }

  // ============================
  // UI
  // ============================
  @override
  Widget build(BuildContext context) {
    final bool connected = _btManager.isConnected.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Configuración",
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          IconButton(icon: const Icon(Icons.help_outline), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            // ============================
            // Personalización
            // ============================
            _buildSettingsGroup(
              title: "Personalización",
              icon: Icons.palette_outlined,
              children: [
                _buildModernTextField(
                  _foco1Controller,
                  "Nombre Interruptor 1",
                  Icons.power_settings_new,
                ),
                _buildModernTextField(
                  _foco2Controller,
                  "Nombre Interruptor 2",
                  Icons.power_settings_new,
                ),
                _buildModernTextField(
                  _foco3Controller,
                  "Nombre Interruptor 3",
                  Icons.power_settings_new,
                ),
                _buildModernTextField(
                  _foco4Controller,
                  "Nombre Interruptor 4",
                  Icons.power_settings_new,
                ),
                const SizedBox(height: 16),
                _buildActionButton(
                  label: "Guardar Nombres",
                  icon: Icons.save_outlined,
                  onPressed: _saveLabels,
                  isPrimary: true,
                ),
              ],
            ),

            // ============================
            // Bluetooth
            // ============================
            _buildSettingsGroup(
              title: "Conectividad Bluetooth",
              icon: Icons.bluetooth_outlined,
              children: [
                _buildStatusIndicator(connected),
                const SizedBox(height: 16),

                if (!connected) ...[
                  _buildActionButton(
                    label: _isScanning ? "Buscando..." : "Buscar Dispositivos",
                    icon: Icons.search_outlined,
                    onPressed: _isScanning ? null : _startScan,
                    isPrimary: false,
                  ),
                  if (_devices.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.0),
                      child: Text(
                        "DISPOSITIVOS CERCANOS",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    _buildDeviceList(),
                  ],
                ] else ...[
                  _buildActionButton(
                    label: "Desconectar",
                    icon: Icons.bluetooth_disabled_outlined,
                    onPressed: () => _btManager.disconnect(),
                    isPrimary: false,
                    isDanger: true,
                  ),
                ],
              ],
            ),

            // ============================
            // WiFi
            // ============================
            _buildSettingsGroup(
              title: "Configuración WiFi",
              icon: Icons.wifi_outlined,
              children: [
                const Text(
                  "Configure la conexión a internet de su dispositivo Metzabok.",
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                ),
                const SizedBox(height: 16),
                _buildModernTextField(
                  _ipController,
                  "IP o Host Local",
                  Icons.lan_outlined,
                  hint: "ej: 192.168.1.15",
                ),
                _buildActionButton(
                  label: "Guardar IP/Host",
                  icon: Icons.dns_outlined,
                  onPressed: _saveIp,
                  isPrimary: false,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  label: "Configurar WiFi Metzabok",
                  icon: Icons.settings_remote_rounded,
                  onPressed: connected
                      ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WifiSetupPage(),
                          ),
                        )
                      : null,
                  isPrimary: true,
                ),
                if (!connected)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text(
                      "Conecta Bluetooth para enviar WiFi",
                      style: TextStyle(color: Colors.orange, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 48),
          ],
>>>>>>> 5c92128 (Initial commit)
        ),
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFD4AF37), size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
=======
  // ============================
  // Widgets
  // ============================
  Widget _buildSettingsGroup({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFD4AF37), size: 22),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
>>>>>>> 5c92128 (Initial commit)
            ),
          ),
        ],
      ),
    );
  }

<<<<<<< HEAD
  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isPhone = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
=======
  Widget _buildModernTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPhone = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFFD4AF37)),
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 1.5),
          ),
          labelStyle: const TextStyle(color: Colors.black54, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool connected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: connected
            ? Colors.green.withOpacity(0.08)
            : Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: connected
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            connected
                ? Icons.check_circle_rounded
                : Icons.error_outline_rounded,
            color: connected ? Colors.green : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            connected ? "Dispositivo Conectado" : "Esperando conexión",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: connected ? Colors.green[800] : Colors.red[800],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isPrimary,
    bool isDanger = false,
  }) {
    final Color bgColor = isPrimary
        ? const Color(0xFFD4AF37)
        : (isDanger ? Colors.red.withOpacity(0.1) : Colors.white);

    final Color fgColor = isPrimary
        ? Colors.white
        : (isDanger ? Colors.red : const Color(0xFFD4AF37));

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      style: ElevatedButton.styleFrom(
        elevation: isPrimary ? 2 : 0,
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: !isPrimary && !isDanger
              ? const BorderSide(color: Color(0xFFD4AF37), width: 1)
              : BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildDeviceList() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _devices.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey[300]),
        itemBuilder: (context, i) => ListTile(
          leading: const CircleAvatar(
            backgroundColor: Color(0xFFD4AF37),
            radius: 16,
            child: Icon(Icons.bluetooth, color: Colors.white, size: 16),
          ),
          title: Text(
            _devices[i].name ?? "Dispositivo Desconocido",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            _devices[i].address,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () => _connectToDevice(_devices[i]),
>>>>>>> 5c92128 (Initial commit)
        ),
      ),
    );
  }
}
