#include "BluetoothSerial.h"
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <ESPmDNS.h>
#include <Preferences.h>
#include <RTClib.h>
#include <SD.h>
#include <SPI.h>
#include <WebServer.h>
#include <WebSocketsServer.h>
#include <WiFi.h>
#include <Wire.h>

// Guard para evitar conflictos con main.ino
#ifndef METZABOOK_WEBSOCKET_H
#define METZABOOK_WEBSOCKET_H

// Configuración OLED
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 32
#define OLED_RESET -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// Configuración RTC
RTC_DS3231 rtc;

// Configuración de Persistencia
Preferences preferences;

// Configuración SD Card (pines SPI estándar del ESP32)
#define SD_CS_PIN 5
#define SD_MOSI_PIN 17
#define SD_MISO_PIN 19
#define SD_SCK_PIN 18

BluetoothSerial SerialBT;
WebServer server(80);
WebSocketsServer webSocket = WebSocketsServer(81);

// Pines de Relays
const int RELAY_PINS[] = {32, 33, 25, 26};

// Pin del botón para controlar Bluetooth
const int BT_BUTTON_PIN = 14;
bool bluetoothEnabled = false; // Por defecto desactivado
bool lastButtonState = HIGH;   // Estado anterior de lectura (para debounce)
bool buttonState = HIGH;       // Estado estable del botón
unsigned long lastDebounceTime = 0;
const unsigned long debounceDelay = 50;

const int MAX_SCHEDS = 5;
const int MAX_WEBSOCKET_CLIENTS = 10;

struct Schedule {
  uint8_t onHour;
  uint8_t onMinute;
  uint8_t offHour;
  uint8_t offMinute;
  uint8_t daysMask; // Bits: 0=Dom, 1=Lun, 2=Mar, 3=Mie, 4=Jue, 5=Vie, 6=Sab
  bool enabled;
};

Schedule channelSchedules[4][MAX_SCHEDS];
bool relayStatus[4] = {false, false, false, false};
bool lastSchedState[4] = {false, false, false, false};
bool autoMode = false; // true = AUTOMATICO, false = MANUAL (GLOBAL)

// Control de conexión Bluetooth
bool bluetoothConnected = false;
unsigned long lastBluetoothCheck = 0;
const unsigned long BT_CHECK_INTERVAL = 1000; // Revisar cada 1 segundo

// Control de clientes WebSocket activos
bool wsClientsActive[MAX_WEBSOCKET_CLIENTS] = {false};
int activeWSClients = 0;

// Estados WiFi (Máquina de estados)
enum WiFiStatus { WIFI_DISCONNECTED, WIFI_CONNECTING, WIFI_CONNECTED };
WiFiStatus currentWiFiStatus = WIFI_DISCONNECTED;
unsigned long wifiConnectStart = 0;
const unsigned long WIFI_TIMEOUT = 20000;

// Heartbeat WebSocket
unsigned long lastWSHeartbeat = 0;
const unsigned long WS_HEARTBEAT_INTERVAL = 30000; // 30 segundos

// --- PERSISTENCIA CON PREFERENCES ---
void saveSchedules() {
  preferences.begin("scheds", false);
  preferences.putBytes("data", (uint8_t *)channelSchedules,
                       sizeof(channelSchedules));
  preferences.end();
  Serial.println("Schedules guardados en NVS");

  // Guardar en SD como Source of Truth (Binario y Texto)
  saveCalibrationToSD();     // Humano
  saveSchedulesToSDBinary(); // Maquina (Source of Truth)
}

void loadSchedules() {
  preferences.begin("scheds", true);
  size_t read = preferences.getBytes("data", (uint8_t *)channelSchedules,
                                     sizeof(channelSchedules));
  preferences.end();

  if (read != sizeof(channelSchedules)) {
    Serial.println("Inicializando schedules por defecto...");
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < MAX_SCHEDS; j++) {
        channelSchedules[i][j] = {0, 0, 0, 0, 0, false};
      }
    }
    saveSchedules();
  } else {
    Serial.println("Schedules cargados de NVS");
  }

  // INTENTAR CARGAR DESDE SD (SOURCE OF TRUTH) -> Sobrescribe NVS si existe
  loadSchedulesFromSDBinary();
}

// --- SD MODE PERSISTENCE ---
void saveModeToSD() {
  if (!SD.exists("/"))
    return;
  SD.remove("/mode.txt");
  File file = SD.open("/mode.txt", FILE_WRITE);
  if (file) {
    file.print(autoMode ? "AUTO" : "MANUAL");
    file.close();
    Serial.println("Mode saved to SD: " + String(autoMode ? "AUTO" : "MANUAL"));
  }
}

void loadModeFromSD() {
  if (!SD.exists("/mode.txt"))
    return;
  File file = SD.open("/mode.txt", FILE_READ);
  if (file) {
    String m = file.readStringUntil('\n');
    m.trim();
    if (m == "AUTO")
      autoMode = true;
    else if (m == "MANUAL")
      autoMode = false;
    file.close();
    Serial.println("Mode LOADED from SD: " +
                   String(autoMode ? "AUTO" : "MANUAL"));
  }
}

void saveMode() {
  preferences.begin("modes", false);
  preferences.putBool("globalAuto", autoMode);
  preferences.end();
  // Also save to SD
  saveModeToSD();
}

void loadMode() {
  preferences.begin("modes", true);
  autoMode = preferences.getBool("globalAuto", false);
  preferences.end();
  Serial.printf("Global Mode (NVS): %s\n", autoMode ? "AUTO" : "MANUAL");

  // Try to load from SD (Source of Truth)
  loadModeFromSD();
}

// --- SD CARD: CREDENCIALES Y CALIBRACIÓN ---

void initializeSD() {
  if (!SD.begin(SD_CS_PIN)) {
    Serial.println("SD Card initialization failed!");
    return;
  }
  Serial.println("SD Card initialized successfully");
}

void saveCalibrationToSD() {
  // Verificar si SD está disponible
  if (!SD.exists("/")) {
    Serial.println("SD Card not available");
    return;
  }

  // Eliminar archivo anterior si existe
  SD.remove("/calibration.txt");

  File file = SD.open("/calibration.txt", FILE_WRITE);
  if (!file) {
    Serial.println("Error: Cannot open calibration.txt for writing");
    return;
  }

  DateTime now = rtc.now();

  file.printf("=== METZABOOK CALIBRATION ===\n");
  file.printf("Saved: %04d-%02d-%02d %02d:%02d:%02d\n", now.year(), now.month(),
              now.day(), now.hour(), now.minute(), now.second());
  file.printf("Global Mode: %s\n", autoMode ? "AUTO" : "MANUAL");
  file.printf("\n=== SCHEDULES ===\n");

  int totalScheds = 0;
  for (int i = 0; i < 4; i++) {
    file.printf("Channel %d:\n", i + 1);
    for (int j = 0; j < MAX_SCHEDS; j++) {
      if (channelSchedules[i][j].enabled) {
        file.printf(
            "  Sched %d: %02d:%02d-%02d:%02d Days:0x%02X\n", j,
            channelSchedules[i][j].onHour, channelSchedules[i][j].onMinute,
            channelSchedules[i][j].offHour, channelSchedules[i][j].offMinute,
            channelSchedules[i][j].daysMask);
        totalScheds++;
      }
    }
  }

  file.printf("\nTotal Schedules: %d\n", totalScheds);
  file.printf("\n=== RELAY STATUS ===\n");
  for (int i = 0; i < 4; i++) {
    file.printf("Relay %d: %s\n", i + 1, relayStatus[i] ? "ON" : "OFF");
  }

  file.close();
  Serial.println("✓ Calibration saved to SD successfully");
}

void loadCalibrationFromSD() {
  File file = SD.open("/calibration.txt");
  if (!file) {
    Serial.println("Calibration file not found on SD");
    return;
  }

  Serial.println("=== CALIBRATION FROM SD ===");
  while (file.available()) {
    Serial.write(file.read());
  }
  file.close();
}

void saveCredentialsToSD(String ssid, String password) {
  // Verificar si SD está disponible
  if (!SD.exists("/")) {
    Serial.println("SD Card not available");
    return;
  }

  // Eliminar archivo anterior si existe
  SD.remove("/credentials.txt");

  File file = SD.open("/credentials.txt", FILE_WRITE);
  if (!file) {
    Serial.println("Error: Cannot open credentials.txt for writing");
    return;
  }

  file.printf("=== METZABOOK WIFI CREDENTIALS ===\n");
  file.printf("SSID: %s\n", ssid.c_str());
  file.printf("Password: %s\n", password.c_str());
  file.printf("Saved: %04d-%02d-%02d %02d:%02d:%02d\n", rtc.now().year(),
              rtc.now().month(), rtc.now().day(), rtc.now().hour(),
              rtc.now().minute(), rtc.now().second());
  file.printf("\nUse these credentials to connect to the WiFi network.\n");

  file.close();
  Serial.println("✓ Credentials saved to SD successfully");
}

void loadCredentialsFromSD() {
  if (!SD.exists("/"))
    return;
  File file = SD.open("/credentials.txt");
  if (!file)
    return;

  String ssid = "";
  String pass = "";

  while (file.available()) {
    String line = file.readStringUntil('\n');
    line.trim();
    if (line.startsWith("SSID: ")) {
      ssid = line.substring(6);
    } else if (line.startsWith("Password: ")) {
      pass = line.substring(10);
    }
  }
  file.close();

  if (ssid.length() > 0) {
    Serial.println("Intentando conectar a WiFi guardado: " + ssid);
    WiFi.begin(ssid.c_str(), pass.c_str());
    currentWiFiStatus = WIFI_CONNECTING;
    wifiConnectStart = millis();
  }
}

// --- BINARY SCHEDULES ON SD (REAL SOURCE OF TRUTH) ---
void saveSchedulesToSDBinary() {
  if (!SD.exists("/"))
    return;
  SD.remove("/scheds.bin");
  File file = SD.open("/scheds.bin", FILE_WRITE);
  if (file) {
    file.write((uint8_t *)channelSchedules, sizeof(channelSchedules));
    file.close();
    Serial.println("✓ Schedules saved to SD (Binary)");
  } else {
    Serial.println("Error saving binary scheds to SD");
  }
}

void loadSchedulesFromSDBinary() {
  if (!SD.exists("/scheds.bin")) {
    Serial.println(
        "Binary schedules file not found on SD. Using NVS/Defaults.");
    return;
  }
  File file = SD.open("/scheds.bin", FILE_READ);
  if (file) {
    if (file.size() == sizeof(channelSchedules)) {
      file.read((uint8_t *)channelSchedules, sizeof(channelSchedules));
      Serial.println("✓ Schedules LOADED from SD (Binary - Source of Truth)");
    } else {
      Serial.println("Error: Binary scheds size mismatch");
    }
    file.close();
  } else {
    Serial.println("Error opening binary scheds from SD");
  }
}

void shareCalibrationViaBluetooth() {
  if (!bluetoothConnected) {
    Serial.println("Bluetooth not connected");
    SerialBT.println("ERROR: Bluetooth not connected");
    return;
  }

  if (!SD.exists("/")) {
    Serial.println("SD Card not available");
    SerialBT.println("ERROR: SD Card not available");
    return;
  }

  File file = SD.open("/calibration.txt");
  if (!file) {
    Serial.println("Calibration file not found");
    SerialBT.println("ERROR: Calibration file not found");
    return;
  }

  SerialBT.println("\n=== SHARING CALIBRATION ===");

  // Enviar contenido del archivo línea por línea
  while (file.available()) {
    String line = file.readStringUntil('\n');
    SerialBT.println(line);
    delay(10); // Pequeño delay para evitar overflow del buffer
  }

  file.close();
  SerialBT.println("=== END CALIBRATION ===\n");
  Serial.println("✓ Calibration shared via Bluetooth");
}

void shareCredentialsViaBluetooth() {
  if (!bluetoothConnected) {
    Serial.println("Bluetooth not connected");
    SerialBT.println("ERROR: Bluetooth not connected");
    return;
  }

  if (!SD.exists("/")) {
    Serial.println("SD Card not available");
    SerialBT.println("ERROR: SD Card not available");
    return;
  }

  File file = SD.open("/credentials.txt");
  if (!file) {
    Serial.println("Credentials file not found");
    SerialBT.println("ERROR: Credentials file not found");
    return;
  }

  SerialBT.println("\n=== SHARING CREDENTIALS ===");

  // Enviar contenido del archivo línea por línea
  while (file.available()) {
    String line = file.readStringUntil('\n');
    SerialBT.println(line);
    delay(10); // Pequeño delay para evitar overflow del buffer
  }

  file.close();
  SerialBT.println("=== END CREDENTIALS ===\n");
  Serial.println("✓ Credentials shared via Bluetooth");
}

// --- DISPLAY ---
void updateDisplay() {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);

  DateTime now = rtc.now();

  // Línea 1: Hora y conexiones
  display.setCursor(0, 0);
  char buf[30];
  snprintf(buf, sizeof(buf), "%02d:%02d:%02d  ", now.hour(), now.minute(),
           now.second());
  display.print(buf);

  // Indicadores de conexión: Bluetooth y WiFi
  if (bluetoothEnabled) {
    display.print(bluetoothConnected
                      ? "B*"
                      : "b"); // B* = conectado, b = habilitado sin conexión
  } else {
    display.print("X"); // Bluetooth deshabilitado
  }

  display.print(" ");

  if (currentWiFiStatus == WIFI_CONNECTED) {
    display.print("((W))"); // WiFi activo
  } else {
    display.print("X"); // WiFi desconectado
  }

  // Línea 2: Estado de relés (ST: I O I O) y Modo (AUTO/MANUAL)
  display.setCursor(0, 12);
  display.print("ST: ");
  for (int i = 0; i < 4; i++) {
    display.print(relayStatus[i] ? "I " : "O ");
  }

  // Mostrar modo en la misma línea
  display.setCursor(70, 12);
  display.print(autoMode ? "AUTO" : "MAN");

  // Línea 3: WebSocket clientes (si hay)
  display.setCursor(0, 24);
  if (activeWSClients > 0) {
    display.printf("WS Clients: %d", activeWSClients);
  } else {
    display.println("");
  }

  display.display();
}

// --- LOGICA NO BLOQUEANTE DE WIFI ---
void handleWiFi() {
  if (currentWiFiStatus == WIFI_CONNECTING) {
    if (WiFi.status() == WL_CONNECTED) {
      currentWiFiStatus = WIFI_CONNECTED;
      SerialBT.println("WIFI OK! IP: " + WiFi.localIP().toString());

      // Iniciar mDNS con servicios HTTP y WebSocket
      MDNS.begin("metzabok");
      MDNS.addService("http", "tcp", 80);
      MDNS.addService("ws", "tcp", 81); // Servicio WebSocket

      Serial.println("mDNS iniciado con servicios http (80) y ws (81)");

      setupWebServer();
      setupWebSocket();
    } else if (millis() - wifiConnectStart > WIFI_TIMEOUT) {
      currentWiFiStatus = WIFI_DISCONNECTED;
      SerialBT.println("WIFI ERROR: Tiempo agotado");
      WiFi.disconnect();
    }
  }
}

// --- FUNCIONES WEBSOCKET ---
void setupWebSocket() {
  webSocket.begin();
  webSocket.onEvent(webSocketEvent);
  Serial.println("WebSocket Server iniciado en puerto 81");
}

void webSocketEvent(uint8_t num, WStype_t type, uint8_t *payload,
                    size_t length) {
  switch (type) {
  case WStype_DISCONNECTED:
    Serial.printf("[%u] desconectado\n", num);
    if (num < MAX_WEBSOCKET_CLIENTS) {
      wsClientsActive[num] = false;
      activeWSClients--;
    }
    break;

  case WStype_CONNECTED:
    Serial.printf("[%u] conectado desde %s\n", num,
                  webSocket.remoteIP(num).toString().c_str());
    if (num < MAX_WEBSOCKET_CLIENTS) {
      wsClientsActive[num] = true;
      activeWSClients++;
    }
    // Enviar estado actual al cliente conectado
    sendCurrentStatusToClient(num);
    break;

  case WStype_TEXT:
    if (payload && length > 0) {
      char command[256] = {0};
      strncpy(command, (const char *)payload, min((size_t)255, length));
      Serial.printf("[%u] Comando WebSocket: %s\n", num, command);

      // Procesar comando (reutiliza la misma función que Bluetooth)
      processCommand(String(command));
    }
    break;

  case WStype_BIN:
    Serial.printf("[%u] Dato binario recibido\n", num);
    break;

  default:
    break;
  }
}

// Enviar estado actual a un cliente específico
void sendCurrentStatusToClient(uint8_t clientNum) {
  String status = "";
  for (int i = 0; i < 4; i++) {
    status += String(i + 1) + ":" + (relayStatus[i] ? "ON" : "OFF") + "|";
  }
  status += "MODE:" + String(autoMode ? "AUTO" : "MANUAL");

  if (clientNum < MAX_WEBSOCKET_CLIENTS && wsClientsActive[clientNum]) {
    webSocket.sendTXT(clientNum, status);
  }
}

// Enviar estado a todos los clientes WebSocket conectados
void sendStatusToAllWebSocketClients(String message) {
  for (uint8_t i = 0; i < MAX_WEBSOCKET_CLIENTS; i++) {
    if (wsClientsActive[i]) {
      webSocket.sendTXT(i, message);
    }
  }
}

// FUNCIÓN PRINCIPAL: Enviar estado a TODOS los clientes (Bluetooth + WebSocket)
void sendStatusToAllClients(String message) {
  // Enviar a Bluetooth si está conectado
  if (bluetoothConnected) {
    SerialBT.println(message);
  }

  // Enviar a todos los clientes WebSocket
  sendStatusToAllWebSocketClients(message);
}

// Detectar conexión Bluetooth
void checkBluetoothConnection() {
  // En Arduino, bluetoothConnected se determina por si hay datos disponibles
  // o por intentos recientes de comunicación
  static unsigned long lastBTActivity = 0;

  // Si Bluetooth está deshabilitado, marcar como desconectado
  if (!bluetoothEnabled) {
    bluetoothConnected = false;
    return;
  }

  // Si hay datos en el buffer BT, asumimos conexión activa
  if (SerialBT.available()) {
    lastBTActivity = millis();
    bluetoothConnected = true;
  } else if (millis() - lastBTActivity > 5000) {
    // Si no hay actividad en 5 segundos, asumimos desconexión
    bluetoothConnected = false;
  }
}

void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22);

  if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
    Serial.println("OLED failed");
  }
  display.clearDisplay();
  display.println("Iniciando...");
  display.display();

  if (!rtc.begin()) {
    Serial.println("RTC failed");
  }

  loadSchedules();
  loadMode();

  // Inicializar SD Card
  initializeSD();
  loadCredentialsFromSD();

  for (int i = 0; i < 4; i++) {
    pinMode(RELAY_PINS[i], OUTPUT);
    digitalWrite(RELAY_PINS[i], LOW);
  }

  // Configurar botón de Bluetooth en pin 14
  pinMode(BT_BUTTON_PIN, INPUT_PULLUP);

  // NO iniciar Bluetooth automáticamente al arranque
  Serial.println("Bluetooth en espera de botón D14...");
}

void checkSchedules() {
  DateTime now = rtc.now();
  int currentMinutes = now.hour() * 60 + now.minute();
  int currentDay = now.dayOfTheWeek();

  if (!autoMode)
    return; // IGNORAR CALENDARIO SI NO ESTAMOS EN AUTO GLOBAL

  for (int i = 0; i < 4; i++) {

    bool anyScheduleSaysOn = false;
    bool anyScheduleEnabled = false;

    for (int j = 0; j < MAX_SCHEDS; j++) {
      if (channelSchedules[i][j].enabled) {
        anyScheduleEnabled = true;
        if (channelSchedules[i][j].daysMask & (1 << currentDay)) {
          int onM = channelSchedules[i][j].onHour * 60 +
                    channelSchedules[i][j].onMinute;
          int offM = channelSchedules[i][j].offHour * 60 +
                     channelSchedules[i][j].offMinute;

          if (onM < offM) {
            if (currentMinutes >= onM && currentMinutes < offM)
              anyScheduleSaysOn = true;
          } else {
            if (currentMinutes >= onM || currentMinutes < offM)
              anyScheduleSaysOn = true;
          }
        }
      }
    }

    if (anyScheduleEnabled) {
      if (anyScheduleSaysOn != lastSchedState[i]) {
        relayStatus[i] = anyScheduleSaysOn;
        digitalWrite(RELAY_PINS[i], relayStatus[i] ? HIGH : LOW);
        lastSchedState[i] = anyScheduleSaysOn;
        String statusMsg = String("CH") + String(i + 1) + "=" +
                           (relayStatus[i] ? "ON" : "OFF");
        sendStatusToAllClients(statusMsg); // Notificar cambio a TODOS
      }
    } else {
      lastSchedState[i] = false;
    }
  }
}

void loop() {
  static unsigned long lastUpdate = 0;

  // Detectar botón de Bluetooth
  int reading = digitalRead(BT_BUTTON_PIN);

  // Si la lectura cambió (ruido o presión), reiniciar temporizador
  if (reading != lastButtonState) {
    lastDebounceTime = millis();
  }

  if ((millis() - lastDebounceTime) > debounceDelay) {
    // Si la lectura ha sido estable por el tiempo de debounce
    if (reading != buttonState) {
      buttonState = reading; // Actualizar estado estable

      // Solo actuar si el nuevo estado estable es LOW (presionado)
      if (buttonState == LOW) {
        if (bluetoothEnabled) {
          // Si ya está activo, REINICIAR
          Serial.println("Botón: Reiniciando Bluetooth...");
          display.clearDisplay();
          display.setCursor(0, 0);
          display.println("RESTARTING BT...");
          display.display();

          SerialBT.end();
          delay(1000); // Dar tiempo para cerrar
          if (SerialBT.begin("Metzabok_ESP32")) {
            Serial.println("Bluetooth Reiniciado OK");
          } else {
            Serial.println("Error al reiniciar Bluetooth");
          }
        } else {
          // Si está apagado, ENCENDER
          bluetoothEnabled = true;
          if (SerialBT.begin("Metzabok_ESP32")) {
            Serial.println("Bluetooth ACTIVADO por botón");
            display.clearDisplay();
            display.setCursor(0, 0);
            display.println("BT ENABLED");
            display.display();
          }
        }
      }
    }
  }
  lastButtonState = reading;

  // Si Bluetooth está habilitado pero desconectado (tras haber estado conectado
  // o tras un tiempo), apagarlo Estrategia: "Si se desconecta el bluetooth...
  // se apaga" Detectamos desconexión vs no-conectado-todavía. Usaremos
  // SerialBT.hasClient() si está disponible, o heurística. La librería
  // BluetoothSerial estándar de ESP32 tiene hasClient().

  static bool wasConnected = false;
  if (bluetoothEnabled) {
    bool currentlyConnected = SerialBT.hasClient();

    if (currentlyConnected && !wasConnected) {
      wasConnected = true;
      Serial.println("Cliente BT Conectado");
    } else if (!currentlyConnected && wasConnected) {
      // Se desconectó
      Serial.println("Cliente BT Desconectado -> Apagando Bluetooth");
      delay(500); // Pequeña pausa
      SerialBT.end();
      bluetoothEnabled = false;
      wasConnected = false;
      display.clearDisplay();
      display.setCursor(0, 0);
      display.println("BT DISABLED");
      display.display();
    }
  }

  if (SerialBT.available() && bluetoothEnabled) {
    String command = SerialBT.readStringUntil('\n');
    command.trim();
    if (command.length() > 0)
      processCommand(command);
  }

  handleWiFi();

  if (currentWiFiStatus == WIFI_CONNECTED) {
    server.handleClient();
    webSocket.loop(); // IMPORTANTE: Procesar eventos WebSocket
  }

  // Revisar conexión Bluetooth periódicamente
  if (millis() - lastBluetoothCheck >= BT_CHECK_INTERVAL) {
    checkBluetoothConnection();
    lastBluetoothCheck = millis();
  }

  // Heartbeat WebSocket opcional
  if (millis() - lastWSHeartbeat >= WS_HEARTBEAT_INTERVAL &&
      activeWSClients > 0) {
    sendStatusToAllWebSocketClients("PING");
    lastWSHeartbeat = millis();
  }

  if (millis() - lastUpdate >= 1000) {
    checkSchedules();
    updateDisplay();
    lastUpdate = millis();
  }
}

void processCommand(String cmd) {
  Serial.println("RX: " + cmd);

  // Control directo
  for (int i = 0; i < 4; i++) {
    char onCmd[5], offCmd[6];
    snprintf(onCmd, sizeof(onCmd), "ON%d", i + 1);
    snprintf(offCmd, sizeof(offCmd), "OFF%d", i + 1);

    if (cmd == onCmd) {
      if (autoMode) {
        sendStatusToAllClients("ERR: MODO AUTO ACTIVO");
        return;
      }
      digitalWrite(RELAY_PINS[i], HIGH);
      relayStatus[i] = true;
      String msg = String("CH") + String(i + 1) + "=ON";
      sendStatusToAllClients(msg); // Notificar a TODOS
      return;
    } else if (cmd == offCmd) {
      if (autoMode) {
        sendStatusToAllClients("ERR: MODO AUTO ACTIVO");
        return;
      }
      digitalWrite(RELAY_PINS[i], LOW);
      relayStatus[i] = false;
      String msg = String("CH") + String(i + 1) + "=OFF";
      sendStatusToAllClients(msg); // Notificar a TODOS
      return;
    }
  }

  // Cambio de modo Global
  if (cmd == "GLOBAL_AUTO") {
    autoMode = true;
    saveMode();
    for (int i = 0; i < 4; i++)
      lastSchedState[i] = !relayStatus[i];
    updateDisplay(); // Actualizar OLED inmediatamente
    sendStatusToAllClients("MODE:GLOBAL:AUTO");
  } else if (cmd == "GLOBAL_MANUAL") {
    autoMode = false;
    saveMode();
    updateDisplay(); // Actualizar OLED inmediatamente
    sendStatusToAllClients("MODE:GLOBAL:MAN");
  }

  if (cmd.startsWith("SETSCHED:")) {
    // FORMATO: SETSCHED:CH:IDX:MASK:ON_H:ON_M:OFF_H:OFF_M
    int p[8];
    int count = 0;
    int pos = 0;
    while (pos != -1 && count < 8) {
      int next = cmd.indexOf(':', pos);
      p[count++] = (next == -1) ? cmd.substring(pos).toInt()
                                : cmd.substring(pos, next).toInt();
      pos = (next == -1) ? -1 : next + 1;
    }

    if (count == 8) {
      int ch = p[1] - 1;
      int idx = p[2];
      if (ch >= 0 && ch < 4 && idx >= 0 && idx < MAX_SCHEDS) {
        channelSchedules[ch][idx] = {(uint8_t)p[4], (uint8_t)p[5],
                                     (uint8_t)p[6], (uint8_t)p[7],
                                     (uint8_t)p[3], true};
        saveSchedules();
        String msg =
            String("SCHED CH") + String(ch + 1) + " IDX" + String(idx) + " OK";
        sendStatusToAllClients(msg); // Notificar a TODOS
      }
    }
  } else if (cmd.startsWith("DIS_SCHED:")) {
    int first = cmd.indexOf(':');
    int second = cmd.indexOf(':', first + 1);
    if (second != -1) {
      int ch = cmd.substring(first + 1, second).toInt() - 1;
      int idx = cmd.substring(second + 1).toInt();
      if (ch >= 0 && ch < 4 && idx >= 0 && idx < MAX_SCHEDS) {
        channelSchedules[ch][idx].enabled = false;
        saveSchedules();
        String msg = String("SCHED CH") + String(ch + 1) + " IDX" +
                     String(idx) + " DISABLED";
        sendStatusToAllClients(msg); // Notificar a TODOS
      }
    }
  } else if (cmd.startsWith("CLEAR_SCHEDS:")) {
    int ch = cmd.substring(13).toInt() - 1;
    if (ch >= 0 && ch < 4) {
      for (int j = 0; j < MAX_SCHEDS; j++) {
        channelSchedules[ch][j].enabled = false;
      }
      saveSchedules();
      String msg = String("SCHEDS CH") + String(ch + 1) + " CLEARED";
      sendStatusToAllClients(msg); // Notificar a TODOS
    }
  } else if (cmd == "GETSCHEDS") {
    Serial.println("Enviando schedules para sincronización...");
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < MAX_SCHEDS; j++) {
        if (channelSchedules[i][j].enabled) {
          // FORMATO: LSCHED:CH:IDX:MASK:ON_H:ON_M:OFF_H:OFF_M
          String msg = String("LSCHED:") + String(i + 1) + ":" + String(j) +
                       ":" + String(channelSchedules[i][j].daysMask) + ":" +
                       String(channelSchedules[i][j].onHour) + ":" +
                       String(channelSchedules[i][j].onMinute) + ":" +
                       String(channelSchedules[i][j].offHour) + ":" +
                       String(channelSchedules[i][j].offMinute);
          sendStatusToAllClients(msg);
          delay(20); // Pequeño respiro
        }
      }
    }
    sendStatusToAllClients("SYNC_DONE");
  } else if (cmd == "ALLON" || cmd == "ALLOFF") {
    bool state = (cmd == "ALLON");
    for (int i = 0; i < 4; i++) {
      digitalWrite(RELAY_PINS[i], state ? HIGH : LOW);
      relayStatus[i] = state;
      String msg = String("CH") + String(i + 1) + "=" + (state ? "ON" : "OFF");
      sendStatusToAllClients(msg); // Notificar a TODOS
    }
    String finalMsg = String(state ? "ALL ON OK" : "ALL OFF OK");
    sendStatusToAllClients(finalMsg);
  } else if (cmd == "STATUS") {
    // Enviar estado de todos los canales
    for (int i = 0; i < 4; i++) {
      String msg =
          String("CH") + String(i + 1) + "=" + (relayStatus[i] ? "ON" : "OFF");
      sendStatusToAllClients(msg);
      delay(10);
    }
    // Enviar modo global
    sendStatusToAllClients(autoMode ? "MODE:GLOBAL:AUTO" : "MODE:GLOBAL:MAN");
    Serial.println("Status sent to all clients");
  }

  else if (cmd.startsWith("SETTIME:")) {
    // SETTIME:HH:MM:SS:DD:MM:YYYY
    int h = cmd.substring(8, 10).toInt();
    int m = cmd.substring(11, 13).toInt();
    int s = cmd.substring(14, 16).toInt();
    int d = cmd.substring(17, 19).toInt();
    int mo = cmd.substring(20, 22).toInt();
    int y = cmd.substring(23).toInt();
    rtc.adjust(DateTime(y, mo, d, h, m, s));
    sendStatusToAllClients("TIME UPDATED");
  } else if (cmd.startsWith("SETWIFI:")) {
    int first = cmd.indexOf(':');
    int second = cmd.indexOf(':', first + 1);
    if (second != -1) {
      String ssid = cmd.substring(first + 1, second);
      String pass = cmd.substring(second + 1);
      WiFi.begin(ssid.c_str(), pass.c_str());
      currentWiFiStatus = WIFI_CONNECTING;
      wifiConnectStart = millis();
      sendStatusToAllClients("Intentando conectar a WiFi...");

      // Guardar credenciales en SD
      saveCredentialsToSD(ssid, pass);
    }
  } else if (cmd == "SAVE_CALIBRATION") {
    // Guardar calibración actual en SD
    saveCalibrationToSD();
    sendStatusToAllClients("✓ CALIBRATION SAVED TO SD");
  } else if (cmd == "LOAD_CALIBRATION") {
    // Cargar calibración desde SD (solo lectura)
    loadCalibrationFromSD();
    sendStatusToAllClients("✓ CALIBRATION LOADED FROM SD");
  } else if (cmd == "SHARE_CALIBRATION") {
    // Compartir calibración por Bluetooth
    shareCalibrationViaBluetooth();
  } else if (cmd == "SHARE_CREDENTIALS") {
    // Compartir credenciales por Bluetooth
    shareCredentialsViaBluetooth();
  }
}

void setupWebServer() {
  server.on("/status", []() { server.send(200, "text/plain", "OK"); });
  server.on("/", []() {
    String h = "<h1>Metzabok Web</h1><p>Status: Active</p><p>WebSocket: "
               "ws://metzabok.local:81</p>";
    server.send(200, "text/html", h);
  });

  for (int i = 0; i < 4; i++) {
    String pathOn = "/foco" + String(i + 1) + "/on";
    String pathOff = "/foco" + String(i + 1) + "/off";
    server.on(pathOn.c_str(), [i]() {
      if (!autoMode) {
        digitalWrite(RELAY_PINS[i], HIGH);
        relayStatus[i] = true;
        String msg = String("F") + String(i + 1) + " ON";
        sendStatusToAllClients(msg); // Notificar a TODOS
        server.send(200, "text/plain", msg);
      } else {
        server.send(400, "text/plain", "MODO AUTO ACTIVO");
      }
    });
    server.on(pathOff.c_str(), [i]() {
      if (!autoMode) {
        digitalWrite(RELAY_PINS[i], LOW);
        relayStatus[i] = false;
        String msg = String("F") + String(i + 1) + " OFF";
        sendStatusToAllClients(msg); // Notificar a TODOS
        server.send(200, "text/plain", msg);
      } else {
        server.send(400, "text/plain", "MODO AUTO ACTIVO");
      }
    });
  }
  // Endpoints para Modo Global
  server.on("/global/auto", []() {
    processCommand("GLOBAL_AUTO");
    server.send(200, "text/plain", "OK: AUTO");
  });

  server.on("/global/manual", []() {
    processCommand("GLOBAL_MANUAL");
    server.send(200, "text/plain", "OK: MANUAL");
  });

  server.begin();
}

#endif // METZABOOK_WEBSOCKET_H
