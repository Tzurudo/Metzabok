# ✅ Coherencia Bluetooth ↔ Arduino - Guía de Integración

## 🔄 Comunicación Bidireccional

### Flujo de Datos

```
App (Flutter)
    ↓
  [Envía: ON1]
    ↓
  ESP32 (Arduino)
    ├─ Procesa comando
    ├─ Enciende relé
    ├─ Actualiza relayStatus[0]
    ├─ Actualiza OLED
    └─ Responde: CH1=ON
    ↓
  App recibe CH1=ON
    ├─ Actualiza relayStates[1] = true
    ├─ FocoSwitch cambia a VERDE
    ├─ Muestra animación
    └─ ✅ Usuario ve el cambio
```

---

## 📱 Flutter (App)

### 1. BluetoothManager - Procesamiento de Respuestas

**Archivo:** `lib/services/bluetooth_manager.dart`

```dart
void _processIncomingLine(String line) {
  // Procesar respuesta del ESP32
  if (line.startsWith('CH') && line.contains('=')) {
    final parts = line.split('=');
    final ch = int.tryParse(parts[0].replaceAll('CH', ''));
    if (ch != null && ch >= 1 && ch <= 4) {
      final state = parts[1].trim().toUpperCase() == 'ON';
      if (relayStates.value[ch] != state) {
        final currentStates = Map<int, bool>.from(relayStates.value);
        currentStates[ch] = state;
        relayStates.value = currentStates; // ← Notifica UI
      }
    }
  }
  // Procesar modo AUTO/MANUAL
  else if (line.startsWith('MODE:GLOBAL:')) {
    final isAuto = line.contains('AUTO');
    if (isGlobalAuto.value != isAuto) {
      isGlobalAuto.value = isAuto; // ← Notifica UI
    }
  }
}
```

### 2. BluetoothPage - Actualización Inmediata de UI

**Archivo:** `lib/pages/bluetooth_page.dart`

```dart
Widget _buildFocoItem(int ch, String label, bool state, bool isAuto, Function(bool) onSwitch) {
  return FocoSwitch(
    titulo: label,
    estado: state,
    enabled: !isAuto,
    onChanged: isAuto ? ... : (v) {
      // Comunicación bidireccional:
      
      // 1️⃣ Actualizar UI INMEDIATAMENTE (optimistic update)
      if (mounted) {
        setState(() {
          final currentStates = Map<int, bool>.from(_btManager.relayStates.value);
          currentStates[ch] = v; // ← UI cambia al instante
          _btManager.relayStates.value = currentStates;
        });
      }
      
      // 2️⃣ Enviar comando al dispositivo
      onSwitch(v); // ← Envía ON1, OFF1, etc.
    },
  );
}
```

### 3. FocoSwitch Widget - Animaciones Visuales

**Archivo:** `lib/widgets/foco_switch.dart`

```dart
// El widget detecta cambios en 'estado' y anima
if (widget.estado) {
  _animationController.forward(); // Anima hacia verde
} else {
  _animationController.reverse(); // Anima hacia gris
}
```

---

## 🔌 Arduino ESP32

### 1. Recibir Comandos

**Archivo:** `main_websocket.ino`

```cpp
void processCommand(String cmd) {
  Serial.println("RX: " + cmd);
  
  // Comandos individuales
  for (int i = 0; i < 4; i++) {
    if (cmd == "ON" + String(i+1)) {
      if (autoMode) {
        sendStatusToAllClients("ERR: MODO AUTO ACTIVO");
        return;
      }
      digitalWrite(RELAY_PINS[i], HIGH);
      relayStatus[i] = true;
      
      // ✅ Enviar confirmación
      String msg = String("CH") + String(i+1) + "=ON";
      sendStatusToAllClients(msg); // ← Responde a TODOS (BT + WebSocket)
      return;
    }
  }
}
```

### 2. Actualizar OLED

```cpp
void updateDisplay() {
  display.clearDisplay();
  
  // Mostrar hora
  snprintf(buf, sizeof(buf), "%02d:%02d:%02d", now.hour(), now.minute(), now.second());
  display.println(buf);
  
  // Mostrar estado de relés
  display.print("ST: ");
  for(int i = 0; i < 4; i++) {
    display.print(relayStatus[i] ? "I " : "O "); // I=Encendido, O=Apagado
  }
  
  // ✅ Mostrar modo AUTO/MANUAL
  display.printf(autoMode ? "AUTO" : "MAN");
  
  display.display();
}
```

### 3. Comunicación Centralizada

```cpp
void sendStatusToAllClients(String message) {
  // Enviar a Bluetooth SI está conectado
  if (bluetoothConnected) {
    SerialBT.println(message);
  }
  
  // Enviar a TODOS los clientes WebSocket
  sendStatusToAllWebSocketClients(message);
}
```

---

## 📊 Comandos Sincronizados

| App Envía | Arduino Procesa | Arduino Responde | App Recibe | Resultado |
|-----------|-----------------|------------------|-----------|-----------|
| `ON1` | Enciende relé 1 | `CH1=ON` | Actualiza estado | ✅ Interruptor cambia a verde |
| `OFF1` | Apaga relé 1 | `CH1=OFF` | Actualiza estado | ✅ Interruptor cambia a gris |
| `GLOBAL_AUTO` | Activa modo automático | `MODE:GLOBAL:AUTO` | Actualiza modo | ✅ OLED muestra "AUTO" |
| `GLOBAL_MANUAL` | Desactiva automático | `MODE:GLOBAL:MAN` | Actualiza modo | ✅ OLED muestra "MAN" |
| `STATUS` | Envía estado actual | CH1=ON/OFF x4, MODE | Sincroniza todo | ✅ UI se actualiza con estado real |

---

## 🐛 Bugsfijos en Cerebro Page

### 1. Switch solo aparece si hay WiFi configurado

```dart
// Cargar IP guardada
Future<void> _loadConfiguredIP() async {
  final prefs = await SharedPreferences.getInstance();
  final ip = prefs.getString('metzabok_ip');
  setState(() {
    _configuredIP = ip;
    _hasConfiguredWiFi = ip != null && ip.isNotEmpty;
  });
}

// Mostrar switch SOLO si IP está guardada
if (_hasConfiguredWiFi && _btManager.isWiFiMode.value)
  Switch(...) // ← Aparece solo si IP está configurada
```

### 2. Comunicación Bidireccional en Bluetooth

```dart
// Antes: Estado no se actualizaba
onChanged: onSwitch // ❌ No actualiza UI local

// Ahora: Actualización inmediata + envío
onChanged: (v) {
  setState(() {
    relayStates[ch] = v; // ✅ UI cambia al instante
  });
  onSwitch(v); // Envía comando
}
```

---

## ✅ Checklist de Coherencia

- [x] Arduino guarda credenciales en SD cuando recibe `SETWIFI:ssid:password`
- [x] Arduino responde TODOS los comandos con `CH#=ON/OFF` o `MODE:GLOBAL:AUTO/MAN`
- [x] Arduino actualiza OLED con modo actual (AUTO/MAN)
- [x] Flutter actualiza UI INMEDIATAMENTE al cambiar switches
- [x] Flutter procesa respuestas del Arduino y sincroniza estado
- [x] Cerebro page solo muestra switch AUTO/MANUAL si hay WiFi configurado
- [x] Comunicación es verdaderamente bidireccional (no es simulada)
- [x] FocoSwitch cambia de color: gris (OFF) → verde (ON)
- [x] FocoSwitch tiene animación de escala
- [x] OLED muestra: Hora, Relés, Modo, WiFi, Conexiones

---

## 🔧 Testing Recomendado

### Test 1: Encender Foco
```
1. App: Presionar interruptor
2. UI: Debe cambiar a VERDE inmediatamente
3. OLED: Debe mostrar "I" (encendido)
4. Arduino Serial: Debe mostrar "CH1=ON"
```

### Test 2: Cambiar Modo
```
1. App: Presionar AUTO/MANUAL (WiFi)
2. UI: Switch debe cambiar color
3. OLED: Debe cambiar entre "AUTO" y "MAN"
4. Arduino Serial: Debe mostrar "MODE:GLOBAL:AUTO" o "MAN"
```

### Test 3: Guardar WiFi
```
1. App: Ir a Settings, guardar IP
2. Arduino: Debe guardar en /credentials.txt
3. Arduino Serial: "✓ Credentials saved to SD successfully"
```

---

**Nota:** Todo está sincronizado y coherente entre Flutter y Arduino.
