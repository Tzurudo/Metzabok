import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:nsd/nsd.dart' as nsd;
import 'package:permission_handler/permission_handler.dart';
import '../widgets/foco_switch.dart';
import '../services/bluetooth_manager.dart'; // Importar BluetoothManager para checar modo global
import 'settings_page.dart';
import 'about_page.dart';

class WifiPage extends StatefulWidget {
  const WifiPage({super.key});

  @override
  State<WifiPage> createState() => _WifiPageState();
}

class _WifiPageState extends State<WifiPage> {
  // IP por defecto o cargada de ajustes
  String baseUrl = "http://metzabok.local";
  bool _estaConectado = false;
  bool _buscando = false;
  bool _inicializando = false; // Muestra si se están apagando los focos
  bool _primerApagadoRealizado = false; // Flag for sequential off

  // Recursos de red
  final http.Client _httpClient = http.Client();
  nsd.Discovery? _discoveryObject;
  Timer? _reconnectTimer;
  Timer? _scanTimeoutTimer;

  // Estados de los interruptores
  bool foco1 = false;
  bool foco2 = false;
  bool foco3 = false;
  bool foco4 = false;

  // Etiquetas personalizables
  String foco1Label = 'Interruptor 1';
  String foco2Label = 'Interruptor 2';
  String foco3Label = 'Interruptor 3';
  String foco4Label = 'Interruptor 4';

  // Manejo de foco para teclado/control remoto
  final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());
  int currentFocus = 0;
  late FocusNode _keyboardFocusNode;

  @override
  void initState() {
    super.initState();
    _keyboardFocusNode = FocusNode();
    _loadInitialState();
  }

  // Carga etiquetas e IP guardada, luego inicia búsqueda
  Future<void> _loadInitialState() async {
    await _loadLabels();
    _initBusqueda();
  }

  Future<void> _loadLabels() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        foco1Label = prefs.getString('foco1_label') ?? 'Interruptor 1';
        foco2Label = prefs.getString('foco2_label') ?? 'Interruptor 2';
        foco3Label = prefs.getString('foco3_label') ?? 'Interruptor 3';
        foco4Label = prefs.getString('foco4_label') ?? 'Interruptor 4';

        // Cargamos la IP guardada en Settings
        final String savedIp =
            prefs.getString('metzabok_ip') ?? 'metzabok.local';
        if (!savedIp.startsWith('http')) {
          baseUrl = "http://$savedIp";
        } else {
          baseUrl = savedIp;
        }
      });
    }
  }

  // Intenta conectar a la IP actual, si falla busca por mDNS y resolución directa
  void _initBusqueda() {
    _probarConexion().then((conectado) {
      if (mounted && !conectado) {
        unawaited(_intentarResolucionDirecta());
        unawaited(_buscarDispositivoMDNS());
      }
    });
  }

  // Intenta resolver 'metzabok.local' directamente (vía rápida)
  Future<void> _intentarResolucionDirecta() async {
    debugPrint("Direct -> Intentando resolución directa de metzabok.local...");
    try {
      final List<InternetAddress> results = await InternetAddress.lookup(
        'metzabok.local',
      ).timeout(const Duration(seconds: 2));

      if (results.isNotEmpty) {
        final String foundIp = results.first.address;
        debugPrint("Direct -> ¡Resolución exitosa! IP: $foundIp");
        if (mounted && !_estaConectado) {
          setState(() {
            baseUrl = "http://$foundIp";
          });
          unawaited(_probarConexion());
        }
      }
    } catch (e) {
      debugPrint("Direct -> Falló resolución directa: $e");
    }
  }

  // Verifica si el dispositivo responde en la URL actual
  Future<bool> _probarConexion() async {
    if (!mounted) return false;
    try {
      final response = await _httpClient
          .get(Uri.parse("$baseUrl/status"))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _estaConectado = true;
            _buscando = false;
          });
          // Si es la primera vez que conectamos y estamos en MODO MANUAL, apagamos todo por seguridad
          if (!_primerApagadoRealizado) {
            final isAuto = BluetoothManager().isGlobalAuto.value;
            if (!isAuto) {
              // Solo apagamos si es MANUAL. Si es AUTO, el calendario manda.
              setState(() {
                _primerApagadoRealizado = true;
              });
              unawaited(_sendAllOffSequentially());
            } else {
              // Marcamos como realizado para no intentar de nuevo, pero no apagamos nada.
              setState(() {
                _primerApagadoRealizado = true;
              });
            }
          }
        }
        return true;
      }
    } catch (e) {
      debugPrint("Conexión fallida en $baseUrl: $e");
    }

    if (mounted) {
      setState(() => _estaConectado = false);
    }

    // Si no estamos conectados y no estamos buscando activamente, reintentar en 5 segundos
    _reconnectTimer?.cancel();
    if (mounted && !_estaConectado && !_buscando) {
      _reconnectTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && !_estaConectado && !_buscando) {
          unawaited(_probarConexion());
        }
      });
    }

    return false;
  }

  // Busca el servicio 'metzabok' en la red local
  Future<void> _buscarDispositivoMDNS() async {
    if (_buscando) return;

    // Solicitar permisos necesarios en Android para descubrimiento de red
    if (Platform.isAndroid) {
      final PermissionStatus status = await Permission.locationWhenInUse
          .request();
      if (status != PermissionStatus.granted) {
        debugPrint("mDNS -> Permiso de ubicación denegado");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Se requiere permiso de ubicación para buscar dispositivos',
              ),
            ),
          );
        }
        return;
      }
    }

    if (mounted) {
      setState(() {
        _buscando = true;
        _estaConectado = false;
      });
    }

    try {
      _discoveryObject = await nsd.startDiscovery('_http._tcp');

      _discoveryObject?.addServiceListener((service, nsd.ServiceStatus status) {
        debugPrint('mDNS -> Detectado: ${service.name} ($status)');

        // Criterio de búsqueda: nombre o host contienen "metza"
        final bool coincide =
            (service.name?.toLowerCase().contains('metza') == true) ||
            (service.host?.toLowerCase().contains('metza') == true);

        if (status == nsd.ServiceStatus.found && coincide) {
          String? foundAddr;
          if (service.addresses != null && service.addresses!.isNotEmpty) {
            foundAddr = service.addresses!.first.address;
          } else if (service.host != null) {
            foundAddr = service.host;
          }

          if (foundAddr != null) {
            debugPrint("mDNS -> ¡Encontrado! Dirección: $foundAddr");
            if (mounted) {
              setState(() {
                baseUrl = "http://$foundAddr";
              });
              if (_discoveryObject != null) {
                unawaited(nsd.stopDiscovery(_discoveryObject!));
              }
              _discoveryObject = null;
              unawaited(_probarConexion());
            }
          }
        }
      });

      // Timeout después de 15 segundos
      _scanTimeoutTimer?.cancel();
      _scanTimeoutTimer = Timer(const Duration(seconds: 15), () {
        if (_buscando && mounted) {
          if (_discoveryObject != null) {
            unawaited(nsd.stopDiscovery(_discoveryObject!));
          }
          _discoveryObject = null;
          setState(() => _buscando = false);
          debugPrint("mDNS -> Búsqueda finalizada por tiempo");
        }
      });
    } catch (e) {
      debugPrint("mDNS ERROR: $e");
      if (mounted) setState(() => _buscando = false);
    }
  }

  // Envía comandos HTTP al dispositivo (Fuego y olvido)
  Future<void> enviar(String ruta) async {
    debugPrint("Enviando comando a: $baseUrl$ruta");

    try {
      final response = await _httpClient
          .get(Uri.parse("$baseUrl$ruta"))
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        debugPrint("Comando confirmado por el dispositivo");
        if (mounted && !_estaConectado) {
          setState(() => _estaConectado = true);
        }
      } else {
        debugPrint("Error HTTP: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error al enviar (posiblemente offline): $e");
      // No bloqueamos al usuario, solo registramos el fallo
    }
  }

  void _toggleCurrent() {
    setState(() {
      if (currentFocus == 0) {
        foco1 = !foco1;
        unawaited(enviar(foco1 ? "/foco1/on" : "/foco1/off"));
      } else if (currentFocus == 1) {
        foco2 = !foco2;
        unawaited(enviar(foco2 ? "/foco2/on" : "/foco2/off"));
      } else if (currentFocus == 2) {
        foco3 = !foco3;
        unawaited(enviar(foco3 ? "/foco3/on" : "/foco3/off"));
      } else if (currentFocus == 3) {
        foco4 = !foco4;
        unawaited(enviar(foco4 ? "/foco4/on" : "/foco4/off"));
      }
    });
  }

  Future<void> _sendAllOffSequentially() async {
    if (!mounted) return;
    setState(() => _inicializando = true);

    debugPrint("WiFi -> Iniciando secuencia de desactivación secuencial...");
    await enviar("/foco1/off");
    setState(() => foco1 = false);
    await Future.delayed(const Duration(milliseconds: 100));

    await enviar("/foco2/off");
    setState(() => foco2 = false);
    await Future.delayed(const Duration(milliseconds: 100));

    await enviar("/foco3/off");
    setState(() => foco3 = false);
    await Future.delayed(const Duration(milliseconds: 100));

    await enviar("/foco4/off");
    setState(() => foco4 = false);

    if (mounted) {
      setState(() => _inicializando = false);
    }
    debugPrint("WiFi -> Secuencia completada.");
  }

  // Versión rápida para salida
  Future<void> _sendAllOffAndClose() async {
    // Usamos un cliente temporal o el actual si aún vive
    try {
      // Como dispose cierra el cliente, creamos uno efímero para asegurar
      final tempClient = http.Client();
      final futures = <Future>[];
      // Enviamos OFF a todos simultáneamente para acelerar la salida
      futures.add(tempClient.get(Uri.parse("$baseUrl/foco1/off")));
      futures.add(tempClient.get(Uri.parse("$baseUrl/foco2/off")));
      futures.add(tempClient.get(Uri.parse("$baseUrl/foco3/off")));
      futures.add(tempClient.get(Uri.parse("$baseUrl/foco4/off")));

      await Future.wait(futures).timeout(const Duration(seconds: 2));
      tempClient.close();
      debugPrint("WifiPage -> Apagado de salida completado");
    } catch (e) {
      debugPrint("WifiPage -> Error en apagado de salida: $e");
    }
  }

  @override
  void dispose() {
    _reconnectTimer?.cancel();
    _scanTimeoutTimer?.cancel();
    if (_discoveryObject != null) {
      unawaited(nsd.stopDiscovery(_discoveryObject!));
    }
    _httpClient.close();
    for (final f in focusNodes) {
      f.dispose();
    }
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        // Auto-Check: Si NO es Global Auto (es decir, es Manual) y estamos saliendo
        // mandamos apagar todo por seguridad.
        if (!BluetoothManager().isGlobalAuto.value) {
          debugPrint(
            "WifiPage -> Saliendo en MODO MANUAL: Enviando secuencia de apagado",
          );
          // No podemos usar await aquí porque el pop ya ocurrió o está ocurriendo.
          // Lanzamos la secuencia "fire and forget" pero asegurando que el cliente no muera inmediatamente.
          unawaited(_sendAllOffAndClose());
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _estaConectado
                ? "Metzabok"
                : (_buscando ? "Buscando..." : "Sin conexión"),
            style: const TextStyle(
              color: Color(0xFFD4AF37),
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            if (!_estaConectado)
              IconButton(
                icon: const Icon(Icons.refresh, color: Color(0xFF757575)),
                onPressed: _initBusqueda,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                _estaConectado ? Icons.wifi : Icons.wifi_off,
                color: _estaConectado ? Colors.green : Colors.red,
              ),
            ),
            Builder(
              builder: (context) {
                return IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF757575)),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                );
              },
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
                    color: Color(0xFFD4AF37),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Configuración'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SettingsPage(),
                    ),
                  ).then((_) => _loadLabels());
                },
              ),
              ListTile(
                leading: const Icon(Icons.info),
                title: const Text('Acerca de'),
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
        body: KeyboardListener(
          focusNode: _keyboardFocusNode,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                setState(() {
                  currentFocus = (currentFocus + 1) % 4;
                  focusNodes[currentFocus].requestFocus();
                });
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                setState(() {
                  currentFocus = (currentFocus - 1 + 4) % 4;
                  focusNodes[currentFocus].requestFocus();
                });
              } else if (event.logicalKey == LogicalKeyboardKey.space) {
                _toggleCurrent();
              }
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_buscando)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: LinearProgressIndicator(color: Color(0xFFD4AF37)),
                  ),
                _buildStatusBanner(),
                const SizedBox(height: 16),
                if (!_estaConectado && !_buscando)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.orange,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "No se pudo encontrar el dispositivo automáticamente.",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SettingsPage(),
                                    ),
                                  ).then((_) => _loadLabels());
                                },
                                icon: const Icon(Icons.edit, size: 18),
                                label: const Text("Configurar IP Manualmente"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFD4AF37),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_estaConectado)
                  Card(
                    margin: const EdgeInsets.only(bottom: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: BluetoothManager().isGlobalAuto.value
                        ? Colors.blue[50]
                        : Colors.orange[50],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Modo Global",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: BluetoothManager().isGlobalAuto.value
                                      ? Colors.blue[800]
                                      : Colors.orange[900],
                                ),
                              ),
                              Text(
                                BluetoothManager().isGlobalAuto.value
                                    ? "AUTOMÁTICO"
                                    : "MANUAL",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: BluetoothManager().isGlobalAuto.value
                                      ? Colors.blue
                                      : Colors.deepOrange,
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: BluetoothManager().isGlobalAuto.value,
                            activeThumbColor: Colors.blue,
                            inactiveThumbColor: Colors.orange,
                            trackColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.selected)) {
                                return Colors.blue[200];
                              }
                              return Colors.orange[200];
                            }),
                            onChanged: (val) {
                              setState(() {
                                BluetoothManager().isGlobalAuto.value = val;
                              });
                              unawaited(
                                enviar(val ? "/global/auto" : "/global/manual"),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                _buildFocoSwitch(0, foco1Label, foco1, (v) {
                  if (BluetoothManager().isGlobalAuto.value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Modo AUTOMÁTICO activo: Cambia a MANUAL primero",
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  setState(() => foco1 = v);
                  unawaited(enviar(v ? "/foco1/on" : "/foco1/off"));
                }),
                _buildFocoSwitch(1, foco2Label, foco2, (v) {
                  if (BluetoothManager().isGlobalAuto.value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Modo AUTOMÁTICO activo: Cambia a MANUAL primero",
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  setState(() => foco2 = v);
                  unawaited(enviar(v ? "/foco2/on" : "/foco2/off"));
                }),
                _buildFocoSwitch(2, foco3Label, foco3, (v) {
                  if (BluetoothManager().isGlobalAuto.value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Modo AUTOMÁTICO activo: Cambia a MANUAL primero",
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  setState(() => foco3 = v);
                  unawaited(enviar(v ? "/foco3/on" : "/foco3/off"));
                }),
                _buildFocoSwitch(3, foco4Label, foco4, (v) {
                  if (BluetoothManager().isGlobalAuto.value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Modo AUTOMÁTICO activo: Cambia a MANUAL primero",
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  setState(() => foco4 = v);
                  unawaited(enviar(v ? "/foco4/on" : "/foco4/off"));
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    String message = "Esperando...";
    Color color = Colors.grey;
    IconData icon = Icons.hourglass_empty;

    if (_buscando) {
      message = "Buscando Metzabok...";
      color = Colors.blue;
      icon = Icons.search;
    } else if (_inicializando) {
      message = "Inicializando focos...";
      color = Colors.orange;
      icon = Icons.settings_input_component;
    } else if (_estaConectado) {
      message = "Conectado y listo";
      color = Colors.green;
      icon = Icons.check_circle;
    } else {
      message = "Sin conexión";
      color = Colors.red;
      icon = Icons.wifi_off;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          if (_buscando || _inicializando)
            const Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFocoSwitch(
    int index,
    String label,
    bool state,
    Function(bool) onChanged,
  ) {
    return FocoSwitch(
      titulo: label,
      estado: state,
      loading: _inicializando && state, // Muestra loading si se está apagando
      enabled: !_inicializando, // Deshabilitado durante la inicialización
      focusNode: focusNodes[index],
      onChanged: onChanged,
    );
  }
}
