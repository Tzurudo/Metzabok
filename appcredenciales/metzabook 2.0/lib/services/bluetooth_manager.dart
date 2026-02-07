import 'dart:async';
import 'dart:collection';
import 'dart:convert';
<<<<<<< HEAD
import 'dart:typed_data';
=======
>>>>>>> 5c92128 (Initial commit)
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
<<<<<<< HEAD
=======
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
>>>>>>> 5c92128 (Initial commit)

class BluetoothManager {
  static final BluetoothManager _instance = BluetoothManager._internal();

  factory BluetoothManager() {
    return _instance;
  }

  BluetoothManager._internal() {
    _bluetooth = BluetoothClassic();
  }

  late BluetoothClassic _bluetooth;

  // Estado de conexión observable
  final ValueNotifier<bool> isConnected = ValueNotifier<bool>(false);

  // Estados de los canales (centralizado)
  final ValueNotifier<Map<int, bool>> relayStates =
      ValueNotifier<Map<int, bool>>({1: false, 2: false, 3: false, 4: false});

  // Modo Global (AUTO/MANUAL)
  final ValueNotifier<bool> isGlobalAuto = ValueNotifier<bool>(false);

<<<<<<< HEAD
=======
  // Nombres de los interruptores (Centralizado para sincronización fluida)
  final ValueNotifier<List<String>> channelNames = ValueNotifier<List<String>>([
    'Interruptor 1',
    'Interruptor 2',
    'Interruptor 3',
    'Interruptor 4',
  ]);

>>>>>>> 5c92128 (Initial commit)
  // Stream de datos (broadcast para múltiples oyentes)
  final StreamController<String> _dataStreamController =
      StreamController<String>.broadcast();
  Stream<String> get deviceDataStream => _dataStreamController.stream;

  StreamSubscription<Uint8List>? _subscription;
  StreamSubscription<String>? _dataSubscription; // Agregado para seguimiento
  String _rxBuffer = '';

  // Cola de comandos para evitar saturar el buffer
  final Queue<String> _commandQueue = Queue<String>();
  bool _isProcessingQueue = false;

  BluetoothClassic get instance => _bluetooth;

<<<<<<< HEAD
=======
  // --- WiFi WebSocket ---
  final ValueNotifier<bool> _isWiFiMode = ValueNotifier<bool>(false);
  ValueNotifier<bool> get isWiFiMode => _isWiFiMode;

  WebSocketChannel? _wsChannel;
  StreamSubscription<dynamic>? _wsSubscription;
  String? _wifiIP;

  // Controlador para comandos WiFi pendientes
  final List<String> _pendingWiFiCommands = [];

>>>>>>> 5c92128 (Initial commit)
  Future<void> initPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.location,
    ].request();
    await _bluetooth.initPermissions();
<<<<<<< HEAD
=======
    await _loadChannelNames(); // Cargar nombres al iniciar
  }

  Future<void> _loadChannelNames() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> loadedNames = [];
    loadedNames.add(prefs.getString('foco1_label') ?? 'Interruptor 1');
    loadedNames.add(prefs.getString('foco2_label') ?? 'Interruptor 2');
    loadedNames.add(prefs.getString('foco3_label') ?? 'Interruptor 3');
    loadedNames.add(prefs.getString('foco4_label') ?? 'Interruptor 4');
    channelNames.value = loadedNames;
  }

  Future<void> updateChannelName(int index, String newName) async {
    if (index < 0 || index >= 4) return;

    // Actualizar lista en memoria
    List<String> current = List.from(channelNames.value);
    current[index] = newName;
    channelNames.value = current;

    // Guardar en persistencia
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('foco${index + 1}_label', newName);
>>>>>>> 5c92128 (Initial commit)
  }

  Future<List<Device>> getPairedDevices() => _bluetooth.getPairedDevices();

  Stream<Device> onDeviceDiscovered() => _bluetooth.onDeviceDiscovered();

  Future<void> startScan() => _bluetooth.startScan();

  Future<void> stopScan() => _bluetooth.stopScan();

  Future<void> connect(String address, String name) async {
    try {
      await stopScan();
      await _bluetooth.connect(address, "00001101-0000-1000-8000-00805f9b34fb");

      isConnected.value = true;
      debugPrint("BluetoothManager: Conectado a $name");

      _rxBuffer = '';
<<<<<<< HEAD
      _subscription?.cancel();
=======
      await _subscription?.cancel();
>>>>>>> 5c92128 (Initial commit)
      _subscription = _bluetooth.onDeviceDataReceived().listen(
        (Uint8List data) {
          String chunk = ascii.decode(data);
          _rxBuffer += chunk;
<<<<<<< HEAD
=======
          // Safety: Prevent unlimited buffer growth
          if (_rxBuffer.length > 4096) {
            _rxBuffer = "";
            debugPrint(
              "BluetoothManager: Buffer overflow protection triggered",
            );
          }

>>>>>>> 5c92128 (Initial commit)
          List<String> parts = _rxBuffer.split('\n');
          if (parts.length > 1) {
            for (int i = 0; i < parts.length - 1; i++) {
              String line = parts[i].trim();
              if (line.isNotEmpty) {
                _processIncomingLine(line);
                _dataStreamController.add(line);
              }
            }
            _rxBuffer = parts.last;
          }
        },
        onDone: () {
          debugPrint("BluetoothManager: Conexión cerrada por dispositivo");
          disconnect();
        },
        onError: (e) {
          debugPrint("BluetoothManager: Error stream - $e");
          disconnect();
        },
      );

      write("STATUS");
    } catch (e) {
      debugPrint("BluetoothManager: Error al conectar - $e");
      isConnected.value = false;
      rethrow;
    }
  }

  void _processIncomingLine(String line) {
    if (line.startsWith('CH') && line.contains('=')) {
      final parts = line.split('=');
      final ch = int.tryParse(parts[0].replaceAll('CH', ''));
      if (ch != null && ch >= 1 && ch <= 4) {
        final state = parts[1].trim().toUpperCase() == 'ON';
        if (relayStates.value[ch] != state) {
          final currentStates = Map<int, bool>.from(relayStates.value);
          currentStates[ch] = state;
          relayStates.value = currentStates;
        }
      }
    } else if (line.startsWith('MODE:GLOBAL:')) {
      final isAuto = line.contains('AUTO');
      if (isGlobalAuto.value != isAuto) {
        isGlobalAuto.value = isAuto;
      }
    }
  }

  Future<void> disconnect() async {
    try {
      await _bluetooth.disconnect();
    } catch (e) {
      debugPrint("BluetoothManager: Error desconectando - $e");
    } finally {
      isConnected.value = false;
      _subscription?.cancel();
      _commandQueue.clear();
      _isProcessingQueue = false;
    }
  }

  void write(String command) {
<<<<<<< HEAD
=======
    if (!isConnected.value) return;

>>>>>>> 5c92128 (Initial commit)
    if (_commandQueue.contains(command)) {
      return;
    }
    _commandQueue.add(command);
    if (!_isProcessingQueue) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue) return;
    _isProcessingQueue = true;

    while (_commandQueue.isNotEmpty && isConnected.value) {
      final command = _commandQueue.removeFirst();
      try {
        await _bluetooth.write("$command\n");
        await Future.delayed(const Duration(milliseconds: 80));
      } catch (e) {
        debugPrint("BluetoothManager: Error escribiendo - $e");
        break;
      }
    }
    _isProcessingQueue = false;
  }

  void dispose() {
    _dataSubscription?.cancel();
    _dataStreamController.close();
<<<<<<< HEAD
=======
    _wsSubscription?.cancel();
    _wsChannel?.sink.close();
  }

  // --- WiFi WebSocket Methods ---

  /// Conectar a ESP32 por WebSocket WiFi
  Future<void> connectWiFi(String ipAddress) async {
    try {
      _wifiIP = ipAddress;
      final wsUri = Uri.parse('ws://$ipAddress:81');

      debugPrint("BluetoothManager: Conectando WiFi a $wsUri");

      _wsChannel = WebSocketChannel.connect(wsUri);
      _isWiFiMode.value = true;

      // Escuchar respuestas WebSocket
      _wsSubscription?.cancel();
      _wsSubscription = _wsChannel!.stream.listen(
        (message) {
          debugPrint("BluetoothManager: WebSocket RX: $message");
          if (message is String) {
            _processIncomingLine(message);
            _dataStreamController.add(message);
          }
        },
        onDone: () {
          debugPrint("BluetoothManager: WebSocket cerrado");
          disconnectWiFi();
        },
        onError: (e) {
          debugPrint("BluetoothManager: WebSocket error - $e");
          disconnectWiFi();
        },
      );

      // Solicitar estado inicial
      _sendWiFiCommand("STATUS");
    } catch (e) {
      debugPrint("BluetoothManager: Error conectando WiFi - $e");
      _isWiFiMode.value = false;
      rethrow;
    }
  }

  /// Enviar comando por WebSocket
  void _sendWiFiCommand(String command) {
    try {
      if (_wsChannel != null && _isWiFiMode.value) {
        debugPrint("BluetoothManager: Enviando WiFi: $command");
        _wsChannel!.sink.add("$command\n");
      } else {
        debugPrint("BluetoothManager: WebSocket no activo");
      }
    } catch (e) {
      debugPrint("BluetoothManager: Error enviando WiFi - $e");
    }
  }

  /// Desconectar WiFi
  void disconnectWiFi() {
    try {
      _wsChannel?.sink.close();
    } catch (e) {
      debugPrint("BluetoothManager: Error cerrando WebSocket - $e");
    } finally {
      _wsSubscription?.cancel();
      _wsChannel = null;
      _isWiFiMode.value = false;
      _wifiIP = null;
      _pendingWiFiCommands.clear();
      debugPrint("BluetoothManager: WiFi desconectado");
    }
  }

  /// Enviar comando (funciona con Bluetooth o WiFi)
  void sendCommand(String command) {
    if (isConnected.value) {
      // Modo Bluetooth
      write(command);
    } else if (_isWiFiMode.value) {
      // Modo WiFi
      _sendWiFiCommand(command);
    } else {
      debugPrint("BluetoothManager: No hay conexión activa");
    }
  }

  /// Cambiar a WiFi automáticamente cuando se pierde Bluetooth
  void _checkWiFiFallback() {
    // Aquí deberías verificar si hay conexión WiFi disponible
    // Por ahora, solo log
    debugPrint("BluetoothManager: Fallback a WiFi si es necesario");
>>>>>>> 5c92128 (Initial commit)
  }
}
