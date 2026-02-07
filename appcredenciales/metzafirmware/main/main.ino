#include "BluetoothSerial.h"
#include <WiFi.h>
#include <WebServer.h>
#include <ESPmDNS.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>
#include <RTClib.h>
#include <Preferences.h>

// Configuración OLED
#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 32
#define OLED_RESET -1
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

// Configuración RTC
RTC_DS3231 rtc;

// Configuración de Persistencia
Preferences preferences;

BluetoothSerial SerialBT;
WebServer server(80);

// Pines de Relays
const int RELAY_PINS[] = {32, 33, 25, 26};

const int MAX_SCHEDS = 5;

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

// Estados WiFi (Máquina de estados)
enum WiFiStatus { WIFI_DISCONNECTED, WIFI_CONNECTING, WIFI_CONNECTED };
WiFiStatus currentWiFiStatus = WIFI_DISCONNECTED;
unsigned long wifiConnectStart = 0;
const unsigned long WIFI_TIMEOUT = 20000;

// --- PERSISTENCIA CON PREFERENCES ---
void saveSchedules() {
  preferences.begin("scheds", false);
  preferences.putBytes("data", (uint8_t*)channelSchedules, sizeof(channelSchedules));
  preferences.end();
  Serial.println("Schedules guardados en NVS");
}

void loadSchedules() {
  preferences.begin("scheds", true);
  size_t read = preferences.getBytes("data", (uint8_t*)channelSchedules, sizeof(channelSchedules));
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
}

void saveMode() {
  preferences.begin("modes", false);
  preferences.putBool("globalAuto", autoMode);
  preferences.end();
}

void loadMode() {
  preferences.begin("modes", true);
  autoMode = preferences.getBool("globalAuto", false);
  preferences.end();
  Serial.printf("Global Mode: %s\n", autoMode ? "AUTO" : "MANUAL");
}

// --- DISPLAY ---
void updateDisplay() {
  display.clearDisplay();
  display.setTextSize(1);
  display.setTextColor(SSD1306_WHITE);
  
  DateTime now = rtc.now();
  
  display.setCursor(0,0);
  char buf[20];
  snprintf(buf, sizeof(buf), "%02d:%02d:%02d", now.hour(), now.minute(), now.second());
  display.println(buf);

  display.setCursor(0, 12);
  display.print("ST: ");
  for(int i=0; i<4; i++) {
    display.print(relayStatus[i] ? "I " : "O ");
  }

  display.setCursor(0, 24);
  const char* st = (currentWiFiStatus == WIFI_CONNECTED) ? "ON" : 
                   (currentWiFiStatus == WIFI_CONNECTING) ? "..." : "OFF";
  display.printf("WiFi: %s", st);
  
  display.display();
}

// --- LOGICA NO BLOQUEANTE DE WIFI ---
void handleWiFi() {
  if (currentWiFiStatus == WIFI_CONNECTING) {
    if (WiFi.status() == WL_CONNECTED) {
      currentWiFiStatus = WIFI_CONNECTED;
      SerialBT.println("WIFI OK! IP: " + WiFi.localIP().toString());
      MDNS.begin("metzabok");
      MDNS.addService("http", "tcp", 80);
      setupWebServer();
    } else if (millis() - wifiConnectStart > WIFI_TIMEOUT) {
      currentWiFiStatus = WIFI_DISCONNECTED;
      SerialBT.println("WIFI ERROR: Tiempo agotado");
      WiFi.disconnect();
    }
  }
}

void setup() {
  Serial.begin(115200);
  Wire.begin(21, 22);

  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
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
  
  for(int i=0; i<4; i++) {
    pinMode(RELAY_PINS[i], OUTPUT);
    digitalWrite(RELAY_PINS[i], LOW);
  }

  if (SerialBT.begin("Metzabook_ESP32")) { 
    Serial.println("Bluetooth listo: Metzabook_ESP32");
  }
}

void checkSchedules() {
  DateTime now = rtc.now();
  int currentMinutes = now.hour() * 60 + now.minute();
  int currentDay = now.dayOfTheWeek();

  if (!autoMode) return; // IGNORAR CALENDARIO SI NO ESTAMOS EN AUTO GLOBAL
  
  for (int i = 0; i < 4; i++) {
    
    bool anyScheduleSaysOn = false;
    bool anyScheduleEnabled = false;

    for (int j = 0; j < MAX_SCHEDS; j++) {
      if (channelSchedules[i][j].enabled) {
        anyScheduleEnabled = true;
        if (channelSchedules[i][j].daysMask & (1 << currentDay)) {
          int onM = channelSchedules[i][j].onHour * 60 + channelSchedules[i][j].onMinute;
          int offM = channelSchedules[i][j].offHour * 60 + channelSchedules[i][j].offMinute;

          if (onM < offM) {
            if (currentMinutes >= onM && currentMinutes < offM) anyScheduleSaysOn = true;
          } else {
            if (currentMinutes >= onM || currentMinutes < offM) anyScheduleSaysOn = true;
          }
        }
      }
    }

    if (anyScheduleEnabled) {
      if (anyScheduleSaysOn != lastSchedState[i]) {
        relayStatus[i] = anyScheduleSaysOn;
        digitalWrite(RELAY_PINS[i], relayStatus[i] ? HIGH : LOW);
        lastSchedState[i] = anyScheduleSaysOn;
        SerialBT.printf("CH%d=%s\n", i+1, relayStatus[i] ? "ON" : "OFF");
      }
    } else {
      lastSchedState[i] = false;
    }
  }
}

void loop() {
  static unsigned long lastUpdate = 0;
  
  if (SerialBT.available()) {
    String command = SerialBT.readStringUntil('\n');
    command.trim();
    if (command.length() > 0) processCommand(command);
  }

  handleWiFi();

  if (currentWiFiStatus == WIFI_CONNECTED) {
    server.handleClient();
  }

  if (millis() - lastUpdate >= 1000) {
    checkSchedules();
    updateDisplay();
    lastUpdate = millis();
  }
}

void processCommand(String cmd) {
  Serial.println("BT RX: " + cmd);

  // Control directo
  for (int i=0; i<4; i++) {
    char onCmd[5], offCmd[6];
    snprintf(onCmd, sizeof(onCmd), "ON%d", i+1);
    snprintf(offCmd, sizeof(offCmd), "OFF%d", i+1);
    
    if (cmd == onCmd) {
      if (autoMode) {
        SerialBT.printf("ERR: MODO AUTO ACTIVO\n");
        return;
      }
      digitalWrite(RELAY_PINS[i], HIGH);
      relayStatus[i] = true;
      SerialBT.printf("CH%d=ON\n", i+1);
      return;
    } else if (cmd == offCmd) {
      if (autoMode) {
        SerialBT.printf("ERR: MODO AUTO ACTIVO\n");
        return;
      }
      digitalWrite(RELAY_PINS[i], LOW);
      relayStatus[i] = false;
      SerialBT.printf("CH%d=OFF\n", i+1);
      return;
    }
  }

  // Cambio de modo Global
  if (cmd == "GLOBAL_AUTO") {
    autoMode = true;
    saveMode();
    for(int i=0; i<4; i++) lastSchedState[i] = !relayStatus[i]; 
    SerialBT.println("MODE:GLOBAL:AUTO");
  } else if (cmd == "GLOBAL_MANUAL") {
    autoMode = false;
    saveMode();
    SerialBT.println("MODE:GLOBAL:MAN");
  }

  if (cmd.startsWith("SETSCHED:")) {
    // FORMATO: SETSCHED:CH:IDX:MASK:ON_H:ON_M:OFF_H:OFF_M
    int p[8];
    int count = 0;
    int pos = 0;
    while (pos != -1 && count < 8) {
      int next = cmd.indexOf(':', pos);
      p[count++] = (next == -1) ? cmd.substring(pos).toInt() : cmd.substring(pos, next).toInt();
      pos = (next == -1) ? -1 : next + 1;
    }

    if (count == 8) {
      int ch = p[1] - 1; 
      int idx = p[2];
      if (ch >= 0 && ch < 4 && idx >= 0 && idx < MAX_SCHEDS) {
        channelSchedules[ch][idx] = {(uint8_t)p[4], (uint8_t)p[5], (uint8_t)p[6], (uint8_t)p[7], (uint8_t)p[3], true};
        saveSchedules();
        SerialBT.printf("SCHED CH%d IDX%d OK\n", ch+1, idx);
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
        SerialBT.printf("SCHED CH%d IDX%d DISABLED\n", ch+1, idx);
      }
    }
  } else if (cmd.startsWith("CLEAR_SCHEDS:")) {
    int ch = cmd.substring(13).toInt() - 1;
    if (ch >= 0 && ch < 4) {
      for (int j = 0; j < MAX_SCHEDS; j++) {
        channelSchedules[ch][j].enabled = false;
      }
      saveSchedules();
      SerialBT.printf("SCHEDS CH%d CLEARED\n", ch+1);
    }
  } else if (cmd == "GETSCHEDS") {
    Serial.println("Enviando schedules para sincronización...");
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < MAX_SCHEDS; j++) {
        if (channelSchedules[i][j].enabled) {
          // FORMATO: LSCHED:CH:IDX:MASK:ON_H:ON_M:OFF_H:OFF_M
          SerialBT.printf("LSCHED:%d:%d:%d:%d:%d:%d:%d\n", i+1, j, 
            channelSchedules[i][j].daysMask, 
            channelSchedules[i][j].onHour, 
            channelSchedules[i][j].onMinute, 
            channelSchedules[i][j].offHour, 
            channelSchedules[i][j].offMinute);
          delay(20); // Pequeño respiro para el stream BT
        }
      }
    }
    SerialBT.println("SYNC_DONE");
  } else if (cmd == "ALLON" || cmd == "ALLOFF") {
    bool state = (cmd == "ALLON");
    for (int i = 0; i < 4; i++) {
      digitalWrite(RELAY_PINS[i], state ? HIGH : LOW);
      relayStatus[i] = state;
      SerialBT.printf("CH%d=%s\n", i+1, state ? "ON" : "OFF");
    }
    SerialBT.println(state ? "ALL ON OK" : "ALL OFF OK");
  } else if (cmd == "STATUS") {
    for (int i = 0; i < 4; i++) {
      SerialBT.printf("CH%d=%s\n", i+1, relayStatus[i] ? "ON" : "OFF");
    }
    SerialBT.printf("MODE:GLOBAL:%s\n", autoMode ? "AUTO" : "MAN");
  } else if (cmd.startsWith("SETTIME:")) {
    // SETTIME:HH:MM:SS:DD:MM:YYYY
    int h = cmd.substring(8, 10).toInt();
    int m = cmd.substring(11, 13).toInt();
    int s = cmd.substring(14, 16).toInt();
    int d = cmd.substring(17, 19).toInt();
    int mo = cmd.substring(20, 22).toInt();
    int y = cmd.substring(23).toInt();
    rtc.adjust(DateTime(y, mo, d, h, m, s));
    SerialBT.println("TIME UPDATED");
  } else if (cmd.startsWith("SETWIFI:")) {
    int first = cmd.indexOf(':');
    int second = cmd.indexOf(':', first + 1);
    if (second != -1) {
      String ssid = cmd.substring(first + 1, second);
      String pass = cmd.substring(second + 1);
      WiFi.begin(ssid.c_str(), pass.c_str());
      currentWiFiStatus = WIFI_CONNECTING;
      wifiConnectStart = millis();
      SerialBT.println("Intentando conectar a WiFi...");
    }
  }
}

void setupWebServer() {
  server.on("/status", []() { server.send(200, "text/plain", "OK"); });
  server.on("/", []() {
    String h = "<h1>Metzabok Web</h1><p>Status: Active</p>";
    server.send(200, "text/html", h);
  });
  
  for (int i=0; i<4; i++) {
    String pathOn = "/foco" + String(i+1) + "/on";
    String pathOff = "/foco" + String(i+1) + "/off";
    server.on(pathOn.c_str(), [i]() { 
      digitalWrite(RELAY_PINS[i], HIGH); 
      relayStatus[i] = true;
      server.send(200, "text/plain", "F" + String(i+1) + " ON"); 
    });
    server.on(pathOff.c_str(), [i]() { 
      digitalWrite(RELAY_PINS[i], LOW); 
      relayStatus[i] = false;
      server.send(200, "text/plain", "F" + String(i+1) + " OFF"); 
    });
  }
  server.begin();
}