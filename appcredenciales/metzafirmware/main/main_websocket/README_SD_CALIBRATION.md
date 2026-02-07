# ✅ Integración Arduino ESP32 - Calibración y Backup

## 📋 Resumen de Funciones Implementadas

### 1. **Inicialización de SD Card**

```cpp
void initializeSD() {
  if (!SD.begin(SD_CS_PIN)) {
    Serial.println("SD Card initialization failed!");
    return;
  }
  Serial.println("SD Card initialized successfully");
}
```

- Se ejecuta en `setup()`
- Pines configurados: CS=5, MOSI=23, MISO=19, SCK=18

---

### 2. **Guardar Calibración en SD**

**Función:** `saveCalibrationToSD()`

**Qué guarda:**
- Fecha y hora del guardado
- Modo global (AUTO/MANUAL)
- Todos los schedules configurados
- Estado de los relés

**Archivo generado:** `/calibration.txt`

**Cuándo se ejecuta:**
- Comando: `SAVE_CALIBRATION` (desde settings_page)
- Automáticamente al guardar schedules

---

### 3. **Guardar Credenciales WiFi en SD**

**Función:** `saveCredentialsToSD(String ssid, String password)`

**Qué guarda:**
- SSID de la red WiFi
- Contraseña WiFi
- Fecha y hora del guardado

**Archivo generado:** `/credentials.txt`

**Cuándo se ejecuta:**
- Cuando se configura WiFi con comando `SETWIFI:ssid:password`

---

### 4. **Compartir Calibración por Bluetooth**

**Función:** `shareCalibrationViaBluetooth()`

**Flujo:**
1. App envía: `SHARE_CALIBRATION`
2. ESP32 abre `/calibration.txt`
3. Envía contenido línea por línea por Bluetooth
4. App puede guardar/procesar datos

---

### 5. **Compartir Credenciales por Bluetooth**

**Función:** `shareCredentialsViaBluetooth()`

**Flujo:**
1. App envía: `SHARE_CREDENTIALS`
2. ESP32 abre `/credentials.txt`
3. Envía contenido por Bluetooth
4. App puede guardar para referencia

---

## 📡 **Comandos Bluetooth Disponibles**

| Comando | Respuesta | Función |
|---------|-----------|---------|
| `SAVE_CALIBRATION` | `✓ CALIBRATION SAVED TO SD` | Guarda en SD |
| `LOAD_CALIBRATION` | `✓ CALIBRATION LOADED FROM SD` | Lee desde SD |
| `SHARE_CALIBRATION` | Contenido del archivo | Envía a app |
| `SHARE_CREDENTIALS` | Contenido del archivo | Envía a app |
| `SETWIFI:ssid:pass` | `Intentando conectar...` | Guarda credenciales |

---

## 🎯 **Integración con Flutter (Settings Page)**

### Botones en Settings:

```dart
// 1. Guardar Calibración
_buildActionButton(
  label: "Guardar Calibración en SD",
  icon: Icons.save_alt,
  onPressed: connected ? () => _sendCommand("SAVE_CALIBRATION") : null,
)

// 2. Compartir Calibración
_buildActionButton(
  label: "Compartir Calibración (BT)",
  icon: Icons.share,
  onPressed: connected ? () => _sendCommand("SHARE_CALIBRATION") : null,
)

// 3. Compartir Credenciales
_buildActionButton(
  label: "Compartir Credenciales (BT)",
  icon: Icons.key,
  onPressed: connected ? () => _sendCommand("SHARE_CREDENTIALS") : null,
)
```

---

## 🔍 **Validación en Serial Monitor**

Cuando se guardas calibración, deberías ver:

```
RX: SAVE_CALIBRATION
✓ Calibration saved to SD successfully
✓ CALIBRATION SAVED TO SD
```

Cuando se comparte:

```
RX: SHARE_CALIBRATION
✓ Calibration shared via Bluetooth
=== SHARING CALIBRATION ===
=== METZABOOK CALIBRATION ===
Saved: 2026-02-02 14:30:45
Global Mode: AUTO
=== SCHEDULES ===
...
=== END CALIBRATION ===
```

---

## ⚠️ **Requisitos Importantes**

1. **SD Card instalada** en el ESP32
2. **Bluetooth conectado** para compartir (no para guardar en SD)
3. **Librería SD instalada**:
   - Arduino IDE → Sketch → Include Library → Manage Libraries
   - Buscar: "SD" 
   - Instalar versión oficial

4. **Pines SPI disponibles** (verificar si hay conflictos con otros dispositivos)

---

## 🚀 **Flujo Completo de Uso**

### Escenario 1: Hacer Backup
```
Usuario abre Settings → Calibración y Backup
→ Click "Guardar Calibración en SD"
→ ESP32 recibe: SAVE_CALIBRATION
→ Guarda /calibration.txt en SD
→ Notificación: "✓ CALIBRATION SAVED TO SD"
```

### Escenario 2: Compartir Calibración
```
Usuario en Settings → Click "Compartir Calibración (BT)"
→ ESP32 recibe: SHARE_CALIBRATION
→ Envía contenido por Bluetooth línea por línea
→ App recibe y puede mostrar/guardar
```

### Escenario 3: Recuperar WiFi
```
Usuario configura WiFi en Settings
→ ESP32 recibe: SETWIFI:miRed:miContraseña
→ Guarda en /credentials.txt
→ Intenta conectar a WiFi
→ Credenciales disponibles en /credentials.txt
```

---

## 📊 **Tamaño de Archivos (Aproximado)**

- `/calibration.txt` ~ 2-5 KB (depende de schedules)
- `/credentials.txt` ~ 0.3 KB
- **Total:** < 10 KB (cabe fácilmente en cualquier SD)

---

## ✅ **Estado Final**

- [x] Funciones de SD implementadas y probadas
- [x] Comandos Bluetooth integrados
- [x] Error handling mejorado
- [x] Mensajes informativos en Serial
- [x] Interfaz Flutter lista
- [x] Documentación completa

---

**Nota:** Si tienes problemas de compilación, asegúrate de que las librerías estén instaladas:
- BluetoothSerial
- WiFi
- WebServer
- ESPmDNS
- WebSocketsServer
- Adafruit_GFX
- Adafruit_SSD1306
- RTClib
- Preferences
- **SD** ← Importante

