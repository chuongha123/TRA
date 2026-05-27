// DHT11 GPIO 17
// BMP280 I2C (GPIO 21 GPIO 22)
// ĐỘ ẨM ĐẤT GPIO 32
// RELAY TƯỚI (IN)  GPIO 27
// RELAY THOÁT (OUT) GPIO 26
// NGUỒN CHO MOTOR 12V
// DỮ LIỆU GỬI VỀ LOCAL API: /api/sensors/ingest
#include <Wire.h>
#include <DHT.h>
#include <Adafruit_BMP280.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <time.h>

#define DHT_PIN      17
#define DHT_TYPE     DHT11
#define SOIL_PIN     32
#define RELAY_IN     27   // Bơm tưới
#define RELAY_OUT    26   // Bơm thoát

#define I2C_SDA      21
#define I2C_SCL      22

const char* WIFI_SSID = "YOUR_WIFI_SSID";
const char* WIFI_PASS = "YOUR_WIFI_PASSWORD";

const char* API_HOST = "192.168.1.100";
const int API_PORT = 3000;

const char* DEVICE_ID = "esp32_garden_01";
const char* API_TOKEN = "esp32-secret";

const long GMT_OFFSET_SECONDS = 7 * 3600;
const int DAYLIGHT_OFFSET_SECONDS = 0;
const char* NTP_SERVER_1 = "pool.ntp.org";
const char* NTP_SERVER_2 = "time.nist.gov";

DHT dht(DHT_PIN, DHT_TYPE);
Adafruit_BMP280 bmp;

const int AirValue = 520;     
const int WaterValue = 260;   
int intervals = (AirValue - WaterValue) / 3;

bool relayTriggered = false;
bool bmpFound = false;

bool pumpOn = false;
unsigned long pumpStartedAt = 0;
const unsigned long pumpDurationMs = 5000;
String pumpTrigger = "auto";
String lastPumpCommandTimestamp = "";

bool drainOn = false;
unsigned long drainStartedAt = 0;
String lastDrainCommandTimestamp = "";

unsigned long lastSensorReadAt = 0;
const unsigned long sensorReadIntervalMs = 2000;

unsigned long lastPumpPollAt = 0;
const unsigned long pumpPollIntervalMs = 3000;

unsigned long lastUploadAt = 0;
const unsigned long uploadIntervalMs = 5000;

float latestHumidity = NAN;
float latestTemperature = NAN;
float latestPressureHpa = NAN;
int latestSoilRaw = 0;
float latestSoilPercent = NAN;

bool syncClock() {
  configTime(GMT_OFFSET_SECONDS, DAYLIGHT_OFFSET_SECONDS, NTP_SERVER_1, NTP_SERVER_2);
  Serial.print("Dang dong bo gio NTP");

  struct tm timeInfo;
  int retry = 0;
  while (!getLocalTime(&timeInfo) && retry < 20) {
    delay(500);
    Serial.print(".");
    retry++;
  }
  Serial.println();

  if (!getLocalTime(&timeInfo)) {
    Serial.println("Khong dong bo duoc gio NTP");
    return false;
  }

  Serial.println("Dong bo gio NTP OK");
  return true;
}

time_t getCurrentEpochSeconds() {
  time_t now = time(nullptr);
  return now > 100000 ? now : 0;
}

String extractJsonStringValue(const String& body, const char* key) {
  String pattern = "\"" + String(key) + "\":\"";
  int start = body.indexOf(pattern);
  if (start < 0) return "";

  start += pattern.length();
  int end = body.indexOf("\"", start);
  if (end < 0) return "";

  return body.substring(start, end);
}

void connectWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("Dang ket noi WiFi");

  int retry = 0;
  while (WiFi.status() != WL_CONNECTED && retry < 30) {
    delay(500);
    Serial.print(".");
    retry++;
  }
  Serial.println();

  if (WiFi.status() == WL_CONNECTED) {
    Serial.print("WiFi OK, IP ESP32: ");
    Serial.println(WiFi.localIP());
    syncClock();
  } else {
    Serial.println("WiFi loi, se thu lai trong loop");
  }
}

float rawToPercent(int raw) {
  float percent = (float)(AirValue - raw) * 100.0 / (AirValue - WaterValue);
  if (percent < 0) return 0;
  if (percent > 100) return 100;
  return percent;
}

void readSensors() {
  latestHumidity = dht.readHumidity();
  latestTemperature = dht.readTemperature();

  if (isnan(latestHumidity) || isnan(latestTemperature)) {
    Serial.println("Loi doc DHT11");
  } else {
    Serial.print("DHT11 - Nhiet do: ");
    Serial.print(latestTemperature);
    Serial.print(" *C | Do am khong khi: ");
    Serial.print(latestHumidity);
    Serial.println(" %");
  }

  if (bmpFound) {
    float pressurePa = bmp.readPressure();
    latestPressureHpa = pressurePa / 100.0;

    Serial.print("BMP280 - Nhiet do: ");
    Serial.print(bmp.readTemperature());
    Serial.print(" *C | Ap suat: ");
    Serial.print(pressurePa);
    Serial.print(" Pa | ");
    Serial.print(latestPressureHpa);
    Serial.println(" hPa");
  } else {
    latestPressureHpa = NAN;
    Serial.println("BMP280 - Khong co du lieu");
  }

  latestSoilRaw = analogRead(SOIL_PIN);
  latestSoilPercent = rawToPercent(latestSoilRaw);

  Serial.print("Do am dat - Raw: ");
  Serial.print(latestSoilRaw);
  Serial.print(" | Percent: ");
  Serial.print(latestSoilPercent);
  Serial.println(" %");
}

void postPumpSession(unsigned long durationSeconds, const String& triggeredBy, const String& deviceId) {
  if (WiFi.status() != WL_CONNECTED) return;

  String url = "http://" + String(API_HOST) + ":" + String(API_PORT) + "/api/pump/session";

  HTTPClient http;
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("X-ESP32-Token", API_TOKEN);

  time_t endEpoch = getCurrentEpochSeconds();
  time_t startEpoch = endEpoch > 0 ? endEpoch - durationSeconds : 0;

  String payload = "{";
  payload += "\"deviceId\":\"" + deviceId + "\",";
  payload += "\"durationSeconds\":" + String(durationSeconds) + ",";
  payload += "\"triggeredBy\":\"" + triggeredBy + "\"";
  if (startEpoch > 0) {
    payload += ",\"startTime\":" + String((unsigned long long)startEpoch);
    payload += ",\"endTime\":" + String((unsigned long long)endEpoch);
  }
  payload += "}";

  int code = http.POST(payload);
  if (code > 0) {
    Serial.print("Pump session ghi OK, code: ");
    Serial.println(code);
  } else {
    Serial.print("Pump session loi: ");
    Serial.println(http.errorToString(code));
  }
  http.end();
}

void pollPumpCommand() {
  if (WiFi.status() != WL_CONNECTED) return;

  // ── Bơm tưới (RELAY_IN / pump_01) ──────────────────────────────────────
  {
    String url = "http://" + String(API_HOST) + ":" + String(API_PORT) +
                 "/api/pump/latest?deviceId=" + String(DEVICE_ID);
    HTTPClient http;
    http.begin(url);
    http.addHeader("X-ESP32-Token", API_TOKEN);
    int code = http.GET();
    if (code == 200) {
      String body = http.getString();
      String commandTimestamp = extractJsonStringValue(body, "timestamp");
      if (commandTimestamp.length() > 0 && commandTimestamp != lastPumpCommandTimestamp) {
        lastPumpCommandTimestamp = commandTimestamp;
        bool commanded = body.indexOf("\"isOn\":true") >= 0;
        if (commanded && !pumpOn) {
          Serial.println("Lenh tu app: Bat bom tuoi");
          digitalWrite(RELAY_IN, HIGH);
          pumpOn = true;
          pumpStartedAt = millis();
          pumpTrigger = "manual";
        } else if (!commanded && pumpOn) {
          Serial.println("Lenh tu app: Tat bom tuoi");
          digitalWrite(RELAY_IN, LOW);
          pumpOn = false;
          unsigned long dur = (millis() - pumpStartedAt) / 1000;
          postPumpSession(dur, pumpTrigger, String(DEVICE_ID));
        }
      }
    }
    http.end();
  }

  // ── Bơm thoát (RELAY_OUT / pump_drain_01) ────────────────────────────────
  {
    String url = "http://" + String(API_HOST) + ":" + String(API_PORT) +
                 "/api/pump/latest?deviceId=pump_drain_01";
    HTTPClient http;
    http.begin(url);
    http.addHeader("X-ESP32-Token", API_TOKEN);
    int code = http.GET();
    if (code == 200) {
      String body = http.getString();
      String commandTimestamp = extractJsonStringValue(body, "timestamp");
      if (commandTimestamp.length() > 0 && commandTimestamp != lastDrainCommandTimestamp) {
        lastDrainCommandTimestamp = commandTimestamp;
        bool commanded = body.indexOf("\"isOn\":true") >= 0;
        if (commanded && !drainOn) {
          Serial.println("Lenh tu app: Bat bom thoat");
          digitalWrite(RELAY_OUT, HIGH);
          drainOn = true;
          drainStartedAt = millis();
        } else if (!commanded && drainOn) {
          Serial.println("Lenh tu app: Tat bom thoat");
          digitalWrite(RELAY_OUT, LOW);
          drainOn = false;
          unsigned long dur = (millis() - drainStartedAt) / 1000;
          postPumpSession(dur, "manual", "pump_drain_01");
        }
      }
    }
    http.end();
  }
}

void uploadToLocalApi() {
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }

  if (isnan(latestHumidity) || isnan(latestTemperature) || isnan(latestSoilPercent)) {
    return;
  }

  float safePressure = isnan(latestPressureHpa) ? 0.0 : latestPressureHpa;

  String url = "http://" + String(API_HOST) + ":" + String(API_PORT) + "/api/sensors/ingest";

  HTTPClient http;
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("X-ESP32-Token", API_TOKEN);

  String payload = "{";
  payload += "\"deviceId\":\"" + String(DEVICE_ID) + "\",";
  payload += "\"soil_raw\":" + String(latestSoilRaw) + ",";
  payload += "\"soil_moisture\":" + String(latestSoilPercent, 1) + ",";
  payload += "\"humidity\":" + String(latestHumidity, 1) + ",";
  payload += "\"temperature\":" + String(latestTemperature, 1) + ",";
  payload += "\"pressure\":" + String(safePressure, 1) + ",";
  payload += "\"pumpOn\":" + String(pumpOn ? "true" : "false") + ",";
  payload += "\"drainOn\":" + String(drainOn ? "true" : "false");
  payload += "}";

  int code = http.POST(payload);
  if (code > 0) {
    Serial.print("Upload API code: ");
    Serial.println(code);
    Serial.println(http.getString());
  } else {
    Serial.print("Upload loi: ");
    Serial.println(http.errorToString(code));
  }
  http.end();
}

void controlPumpByRule() {
  // Quy tắc demo: đất quá khô thì bật bơm tưới 5 giây, tránh lặp lại liên tục.
  if (latestSoilRaw >= 1000 && !relayTriggered && !pumpOn) {
    Serial.println("Soil RAW >= 1000 -> Bat relay tuoi 5 giay");
    digitalWrite(RELAY_IN, HIGH);
    pumpOn = true;
    pumpStartedAt = millis();
    pumpTrigger = "auto";
    relayTriggered = true;
  }

  if (pumpOn && pumpTrigger == "auto" && millis() - pumpStartedAt >= pumpDurationMs) {
    digitalWrite(RELAY_IN, LOW);
    pumpOn = false;
    unsigned long dur = (millis() - pumpStartedAt) / 1000;
    postPumpSession(dur, pumpTrigger, String(DEVICE_ID));
    Serial.println("Tat relay tuoi");
  }

  if (latestSoilRaw < 1000) {
    relayTriggered = false;
  }
}

void setup() {
  Serial.begin(115200);
  delay(1000);

  dht.begin();
  Wire.begin(I2C_SDA, I2C_SCL);

  analogReadResolution(12);

  pinMode(RELAY_IN, OUTPUT);
  digitalWrite(RELAY_IN, LOW);
  pinMode(RELAY_OUT, OUTPUT);
  digitalWrite(RELAY_OUT, LOW);

  bmpFound = bmp.begin(0x76);
  if (!bmpFound) {
    bmpFound = bmp.begin(0x77);
  }

  if (bmpFound) {
    Serial.println("BMP280 OK");
  } else {
    Serial.println("Khong tim thay BMP280");
  }

  connectWiFi();
}

void loop() {
  if (WiFi.status() != WL_CONNECTED) {
    connectWiFi();
  }

  unsigned long now = millis();

  if (now - lastSensorReadAt >= sensorReadIntervalMs) {
    lastSensorReadAt = now;
    readSensors();
    controlPumpByRule();
    Serial.println("----------------------------");
  }

  if (now - lastUploadAt >= uploadIntervalMs) {
    lastUploadAt = now;
    uploadToLocalApi();
  }

  if (now - lastPumpPollAt >= pumpPollIntervalMs) {
    lastPumpPollAt = now;
    pollPumpCommand();
  }

  delay(10);
}