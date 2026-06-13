// BME280 I2C (GPIO 21, GPIO 22)
// DO AM DAT: GPIO 34 (Sơ đồ mạch thực tế dùng G34)
// CAM BIEN MUC NUOC ANALOG: GPIO 32 (Chân trống theo sơ đồ mạch)
// RELAY TUOI (IN): GPIO 27
// RELAY THOAT (OUT): GPIO 26
// NUT RESET FACTORY: GPIO 25 (giu 5 giay)
// LED CHE DO AP: GPIO 33 (luon sang khi AP)
// Nguon motor 12V qua relay
// Local API: POST /api/sensors/ingest
// Poll: GET /api/pump/latest, POST /api/pump/session

#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BME280.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <WebServer.h>
#include <Preferences.h>
#include <Update.h>
#include <time.h>

#define SOIL_PIN     34
#define WATER_PIN    32  
#define RELAY_IN     27
#define RELAY_OUT    26
#define BUTTON_PIN   25
#define CONFIG_LED   33

#define I2C_SDA      21
#define I2C_SCL      22

#define FACTORY_RESET_HOLD_MS 5000

const int DEFAULT_API_PORT = 3000;

const char* AP_SSID = "ESP32-Garden-Setup";
const char* AP_PASS = "garden2025";

const char* DEVICE_ID = "esp32_garden_01";
const char* API_TOKEN = "esp32-secret";

const long GMT_OFFSET_SECONDS = 7 * 3600;
const int DAYLIGHT_OFFSET_SECONDS = 0;
const char* NTP_SERVER_1 = "pool.ntp.org";
const char* NTP_SERVER_2 = "time.nist.gov";

Adafruit_BME280 bme;
Preferences preferences;
WebServer configServer(80);

String wifiSsid;
String wifiPass;
String apiHost;
int apiPort = DEFAULT_API_PORT;

bool configMode = false;
bool configServerStarted = false;
bool apPending = false;

// Capacitive Soil Moisture Sensor V2.0 (ADC 12-bit): raw cao = kho, raw thap = uot
const int SoilMoistureSamples = 12;
const int SoilDryRaw = 1000;   // Raw khi kho (0% do am)
const int SoilWetRaw = 620;    // Raw khi ngam nuoc (100% do am)
float soilPumpOnPercent = 30.0f;
float waterLevelThresholdPercent = 100.0f;
bool isAutoMode = true;

// Cấu hình Cảm biến mực nước Analog
const int WaterMaxRaw = 2500;  // Ngưỡng phát hiện ngập nước (Hệ số quy đổi 100%)

bool relayTriggered = false;
bool bmeFound = false;

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

unsigned long lastSettingsPollAt = 0;
const unsigned long settingsPollIntervalMs = 5000;

unsigned long lastUploadAt = 0;
const unsigned long uploadIntervalMs = 5000;

float latestTemperature = NAN;
float latestPressureHpa = NAN;
float latestHumidity = NAN;
int latestSoilRaw = 0;
float latestSoilPercent = NAN;
int latestWaterRaw = 0;        // Thêm biến lưu giá trị mực nước toàn cục

bool buttonWasPressed = false;
unsigned long buttonPressStart = 0;
bool factoryResetDone = false;

unsigned long lastWifiRetryAt = 0;
unsigned long wifiConnectStarted = 0;
bool wifiConnecting = false;
bool ntpSynced = false;
bool ntpSyncRequested = false;
unsigned long ntpSyncStarted = 0;

const unsigned long wifiRetryIntervalMs = 10000;
const unsigned long wifiConnectTimeoutMs = 15000;
const unsigned long ntpSyncTimeoutMs = 10000;
const unsigned long httpTimeoutMs = 3000;
const unsigned long apSetupWaitMs = 100;
const unsigned long restartDelayMs = 500;

bool bootComplete = false;

bool apSetupPending = false;
unsigned long apSetupStartedAt = 0;

bool restartPending = false;
unsigned long restartAt = 0;
bool firmwareUpdateOk = false;
void startWifiConnect();
void setApPendingFlag(bool value) {
  preferences.begin("garden_cfg", false);
  preferences.putBool("ap_pending", value);
  preferences.end();
  apPending = value;
}

void loadConfig() {
  preferences.begin("garden_cfg", true);
  apPending = preferences.getBool("ap_pending", false);
  wifiSsid = preferences.getString("wifi_ssid", "");
  wifiPass = preferences.getString("wifi_pass", "");
  apiHost = preferences.getString("api_host", "");
  apiPort = preferences.getInt("api_port", DEFAULT_API_PORT);
  preferences.end();

  if (!apPending && wifiSsid.length() == 0) {
    apPending = true;
    setApPendingFlag(true);
  }
}

bool shouldStayInApMode() {
  return apPending || wifiSsid.length() == 0;
}

void saveWifiConfig(const String& ssid, const String& pass) {
  preferences.begin("garden_cfg", false);
  preferences.putString("wifi_ssid", ssid);
  preferences.putString("wifi_pass", pass);
  preferences.putBool("ap_pending", false);
  preferences.end();

  wifiSsid = ssid;
  wifiPass = pass;
  apPending = false;
}

void saveServerConfig(const String& host, int port) {
  preferences.begin("garden_cfg", false);
  preferences.putString("api_host", host);
  preferences.putInt("api_port", port);
  preferences.end();

  apiHost = host;
  apiPort = port;
}

String htmlEscape(const String& input) {
  String out = "";
  out.reserve(input.length());

  for (unsigned int i = 0; i < input.length(); i++) {
    char c = input.charAt(i);

    if (c == '&') out += "&amp;";
    else if (c == '<') out += "&lt;";
    else if (c == '>') out += "&gt;";
    else if (c == '"') out += "&quot;";
    else out += c;
  }

  return out;
}

String jsonEscape(const String& input) {
  String out = "";
  out.reserve(input.length());

  for (unsigned int i = 0; i < input.length(); i++) {
    char c = input.charAt(i);

    if (c == '\\') out += "\\\\";
    else if (c == '"') out += "\\\"";
    else if (c == '\n') out += "\\n";
    else out += c;
  }

  return out;
}

void sendJson(bool ok, const String& message, int code = 200, bool restart = false) {
  String json = "{\"ok\":";
  json += ok ? "true" : "false";
  json += ",\"message\":\"";
  json += jsonEscape(message);
  json += "\"";

  if (restart) {
    json += ",\"restart\":true";
  }

  json += "}";
  configServer.send(code, "application/json; charset=utf-8", json);
}

void scheduleRestart() {
  restartPending = true;
  restartAt = millis() + restartDelayMs;
}

void handleConfigRoot() {
  String html = R"rawliteral(<!DOCTYPE html>
<html lang="vi">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Cấu hình ESP32 Garden</title>
<style>
*{box-sizing:border-box}
body{margin:0;font-family:Segoe UI,Roboto,Arial,sans-serif;background:#f0f4f1;color:#1f2937}
.wrap{max-width:720px;margin:0 auto;padding:20px 16px 96px}
.header{background:linear-gradient(135deg,#1b5e20,#2e7d32);color:#fff;padding:20px;border-radius:12px;margin-bottom:16px;box-shadow:0 4px 14px rgba(27,94,32,.25)}
.header h1{margin:0 0 6px;font-size:1.5rem}
.header p{margin:0;opacity:.92;font-size:.95rem;line-height:1.5}
.card{background:#fff;border-radius:12px;padding:18px;margin-bottom:14px;box-shadow:0 2px 10px rgba(0,0,0,.06)}
.card h2{margin:0 0 14px;font-size:1.1rem;color:#1b5e20;border-bottom:1px solid #e5e7eb;padding-bottom:8px}
.field{margin-bottom:12px}
.field label{display:block;margin-bottom:6px;font-weight:600;font-size:.9rem;color:#374151}
.field input{width:100%;padding:11px 12px;border:1px solid #d1d5db;border-radius:8px;font-size:1rem;transition:border-color .2s}
.field input:focus{outline:none;border-color:#2e7d32;box-shadow:0 0 0 3px rgba(46,125,50,.15)}
.note{margin:10px 0 0;font-size:.85rem;color:#6b7280;line-height:1.45}
.actions{display:flex;flex-direction:column;gap:10px;margin-top:14px}
.btn{display:inline-flex;align-items:center;justify-content:center;width:100%;padding:12px 14px;border:0;border-radius:8px;font-size:1rem;font-weight:600;cursor:pointer;transition:transform .15s,opacity .15s}
.btn:active{transform:scale(.98)}
.btn:disabled{opacity:.6;cursor:not-allowed}
.btn-primary{background:#2e7d32;color:#fff}
.btn-secondary{background:#1565c0;color:#fff}
.btn-warning{background:#ef6c00;color:#fff}
.file-row{display:flex;flex-direction:column;gap:10px}
.file-name{font-size:.9rem;color:#4b5563;word-break:break-all}
#toastBox{position:fixed;left:50%;bottom:20px;transform:translateX(-50%);width:min(92vw,420px);z-index:9999;display:flex;flex-direction:column;gap:8px;pointer-events:none}
.toast{padding:12px 14px;border-radius:10px;color:#fff;font-size:.92rem;line-height:1.45;box-shadow:0 6px 20px rgba(0,0,0,.18);opacity:0;transform:translateY(12px);animation:toastIn .25s forwards}
.toast.success{background:#2e7d32}
.toast.error{background:#c62828}
.toast.info{background:#1565c0}
@keyframes toastIn{to{opacity:1;transform:translateY(0)}}
@keyframes toastOut{to{opacity:0;transform:translateY(12px)}}
</style>
</head>
<body>
<div class="wrap">
<div class="header">
<h1>ESP32 Garden</h1>
</div>

<div class="card">
<h2>Cấu hình WiFi</h2>
<form id="wifiForm">
<div class="field"><label for="ssid">Tên mạng (SSID)</label>
<input id="ssid" name="ssid" value=")rawliteral";
  html += htmlEscape(wifiSsid);
  html += R"rawliteral(" required></div>
<div class="field"><label for="pass">Mật khẩu WiFi</label>
<input id="pass" name="pass" type="password" value=")rawliteral";
  html += htmlEscape(wifiPass);
  html += R"rawliteral("></div>
<div class="actions"><button class="btn btn-primary" type="submit">Lưu WiFi và khởi động lại</button></div>
<p class="note">Lưu WiFi sẽ khởi động lại thiết bị và kết nối mạng mới.</p>
</form>
</div>

<div class="card">
<h2>Cấu hình Server API</h2>
<form id="serverForm">
<div class="field"><label for="host">Địa chỉ máy chủ (IP)</label>
<input id="host" name="host" value=")rawliteral";
  html += htmlEscape(apiHost);
  html += R"rawliteral(" required></div>
<div class="field"><label for="port">Cổng API</label>
<input id="port" name="port" type="number" min="1" max="65535" value=")rawliteral";
  html += String(apiPort);
  html += R"rawliteral(" required></div>
<div class="actions"><button class="btn btn-primary" type="submit">Lưu máy chủ</button></div>
<p class="note">Lưu máy chủ chỉ ghi vào bộ nhớ, không khởi động lại.</p>
</form>
</div>

<div class="card">
<h2>Hệ thống</h2>
<div class="file-row">
<input id="firmwareFile" type="file" accept=".bin,application/octet-stream">
<div class="file-name" id="fileName">Chưa chọn tệp firmware (.bin)</div>
</div>
<div class="actions">
<button class="btn btn-secondary" id="btnUpload" type="button">Tải lên firmware</button>
<button class="btn btn-warning" id="btnRestart" type="button">Khởi động lại</button>
</div>
<p class="note">Tải firmware từ Arduino IDE: Sketch → Export Compiled Binary.</p>
</div>
</div>

<div id="toastBox"></div>
<script>
const toastBox=document.getElementById('toastBox');
function showToast(message,type='success',duration=3200){
  const el=document.createElement('div');
  el.className='toast '+type;
  el.textContent=message;
  toastBox.appendChild(el);
  setTimeout(()=>{el.style.animation='toastOut .25s forwards';setTimeout(()=>el.remove(),250)},duration);
}
async function postForm(url,form){
  const res=await fetch(url,{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded'},body:new URLSearchParams(new FormData(form))});
  let data={ok:false,message:'Phản hồi không hợp lệ'};
  try{data=await res.json()}catch(e){}
  if(!res.ok&&!data.message)data.message='Yêu cầu thất bại';
  showToast(data.message||'Hoàn tất',data.ok?'success':'error',data.restart?5000:3200);
  return data;
}
document.getElementById('wifiForm').addEventListener('submit',async(e)=>{e.preventDefault();const btn=e.target.querySelector('button[type=submit]');btn.disabled=true;await postForm('/save/wifi',e.target);btn.disabled=false});
document.getElementById('serverForm').addEventListener('submit',async(e)=>{e.preventDefault();const btn=e.target.querySelector('button[type=submit]');btn.disabled=true;await postForm('/save/server',e.target);btn.disabled=false});
document.getElementById('firmwareFile').addEventListener('change',(e)=>{const f=e.target.files[0];document.getElementById('fileName').textContent=f?f.name+` (${Math.round(f.size/1024)} KB)`:'Chưa chọn tệp firmware (.bin)'});
document.getElementById('btnRestart').addEventListener('click',async()=>{const btn=document.getElementById('btnRestart');btn.disabled=true;try{const res=await fetch('/restart',{method:'POST'});const data=await res.json();showToast(data.message,data.ok?'info':'error',4000)}catch(err){showToast('Không thể khởi động lại','error')}btn.disabled=false});
document.getElementById('btnUpload').addEventListener('click',async()=>{const file=document.getElementById('firmwareFile').files[0];if(!file){showToast('Vui lòng chọn tệp firmware .bin','error');return}const btn=document.getElementById('btnUpload');btn.disabled=true;showToast('Đang tải firmware lên...','info',6000);try{const fd=new FormData();fd.append('firmware',file);const res=await fetch('/upload/firmware',{method:'POST',body:fd});const data=await res.json();showToast(data.message,data.ok?'success':'error',data.restart?6000:4000)}catch(err){showToast('Tải firmware thất bại','error')}btn.disabled=false});
</script>
</body>
</html>)rawliteral";

  configServer.send(200, "text/html; charset=utf-8", html);
}

void handleSaveWifi() {
  if (!configServer.hasArg("ssid")) {
    sendJson(false, "Thiếu tên mạng WiFi", 400);
    return;
  }

  String ssid = configServer.arg("ssid");
  String pass = configServer.hasArg("pass") ? configServer.arg("pass") : "";

  if (ssid.length() == 0) {
    sendJson(false, "Tên mạng WiFi không hợp lệ", 400);
    return;
  }

  saveWifiConfig(ssid, pass);
  sendJson(true, "Đã lưu WiFi. Đang khởi động lại...", 200, true);
  scheduleRestart();
}

void handleSaveServer() {
  if (!configServer.hasArg("host") || !configServer.hasArg("port")) {
    sendJson(false, "Thiếu địa chỉ hoặc cổng máy chủ", 400);
    return;
  }

  String host = configServer.arg("host");
  int port = configServer.arg("port").toInt();

  if (host.length() == 0 || port <= 0 || port > 65535) {
    sendJson(false, "Địa chỉ hoặc cổng không hợp lệ", 400);
    return;
  }

  saveServerConfig(host, port);
  sendJson(true, "Đã lưu máy chủ: " + host + ":" + String(port));
}

void handleRestart() {
  sendJson(true, "Đang khởi động lại thiết bị...", 200, true);
  scheduleRestart();
}

void handleFirmwareUpload() {
  HTTPUpload& upload = configServer.upload();

  if (upload.status == UPLOAD_FILE_START) {
    firmwareUpdateOk = false;

    Serial.print("Firmware upload: ");
    Serial.println(upload.filename);

    if (!Update.begin(UPDATE_SIZE_UNKNOWN)) {
      Update.printError(Serial);
    }
  } else if (upload.status == UPLOAD_FILE_WRITE) {
    if (Update.write(upload.buf, upload.currentSize) != upload.currentSize) {
      Update.printError(Serial);
    }
  } else if (upload.status == UPLOAD_FILE_END) {
    firmwareUpdateOk = Update.end(true);
    Serial.printf("Firmware upload size: %u bytes\n", upload.totalSize);

    if (!firmwareUpdateOk) {
      Update.printError(Serial);
    }
  } else if (upload.status == UPLOAD_FILE_ABORTED) {
    Update.abort();
    firmwareUpdateOk = false;
  }
}

void handleFirmwareFinish() {
  if (Update.hasError() || !firmwareUpdateOk) {
    sendJson(false, "Cập nhật firmware thất bại", 500);
    return;
  }

  sendJson(true, "Cập nhật firmware thành công. Đang khởi động lại...", 200, true);
  scheduleRestart();
}

void startConfigWebServer() {
  configServer.on("/", HTTP_GET, handleConfigRoot);
  configServer.on("/save/wifi", HTTP_POST, handleSaveWifi);
  configServer.on("/save/server", HTTP_POST, handleSaveServer);
  configServer.on("/restart", HTTP_POST, handleRestart);
  configServer.on(
    "/upload/firmware",
    HTTP_POST,
    handleFirmwareFinish,
    handleFirmwareUpload
  );
  configServer.begin();
  configServerStarted = true;

  Serial.println("Web cau hinh AP da chay tai http://192.168.4.1/");
}

void enterConfigMode() {
  configMode = true;
  apPending = true;
  setApPendingFlag(true);
  bootComplete = true;
  wifiConnecting = false;
  ntpSynced = false;
  ntpSyncRequested = false;

  digitalWrite(RELAY_IN, LOW);
  digitalWrite(RELAY_OUT, LOW);
  pumpOn = false;
  drainOn = false;

  WiFi.setAutoReconnect(false);
  WiFi.persistent(false);
  WiFi.disconnect(true, true);
  WiFi.mode(WIFI_OFF);

  apSetupPending = true;
  apSetupStartedAt = millis();
  digitalWrite(CONFIG_LED, HIGH);

  Serial.println("Dang chuyen sang che do AP cau hinh...");
}

void ensureApActive() {
  if (!configMode) return;

  WiFi.setAutoReconnect(false);

  if (WiFi.getMode() != WIFI_AP) {
    WiFi.persistent(false);
    WiFi.disconnect(true, true);
    WiFi.mode(WIFI_AP);
    WiFi.softAP(AP_SSID, AP_PASS);

    if (!configServerStarted) {
      startConfigWebServer();
    }

    Serial.println("Giu che do AP (chan WiFi STA ghi de)");
  }
}

void tickApSetup() {
  if (!apSetupPending) return;
  if (millis() - apSetupStartedAt < apSetupWaitMs) return;

  apSetupPending = false;

  WiFi.mode(WIFI_AP);
  WiFi.softAP(AP_SSID, AP_PASS);

  if (!configServerStarted) {
    startConfigWebServer();
  }

  Serial.print("Che do AP cau hinh. SSID: ");
  Serial.print(AP_SSID);
  Serial.print(" | IP: ");
  Serial.println(WiFi.softAPIP());
}

void factoryResetAndEnterConfigMode() {
  preferences.begin("garden_cfg", false);
  preferences.clear();
  preferences.putBool("ap_pending", true);
  preferences.end();

  apPending = true;
  wifiSsid = "";
  wifiPass = "";
  apiHost = "";
  apiPort = DEFAULT_API_PORT;
  wifiConnecting = false;
  bootComplete = true;

  WiFi.setAutoReconnect(false);
  WiFi.persistent(false);
  WiFi.disconnect(true, true);

  Serial.println("Factory reset: da xoa WiFi + server, vao che do AP");

  enterConfigMode();
  factoryResetDone = true;
}

void finishBootNetworking() {
  if (configMode || apPending || shouldStayInApMode()) {
    if (!configMode) {
      Serial.println("Chua cau hinh WiFi - tu dong vao che do AP");
      enterConfigMode();
    }
    return;
  }

  if (wifiSsid.length() > 0) {
    startWifiConnect();
  }
}

void updateConfigLed() {
  digitalWrite(CONFIG_LED, configMode ? HIGH : LOW);
}

void tickPendingRestart() {
  if (restartPending && millis() >= restartAt) {
    ESP.restart();
  }
}

void checkFactoryResetButton() {
  bool pressed = digitalRead(BUTTON_PIN) == LOW;

  if (pressed) {
    if (!buttonWasPressed) {
      buttonWasPressed = true;
      buttonPressStart = millis();
      factoryResetDone = false;
      Serial.println("Nhan nut G25 - giu 5 giay de reset factory...");
    } else if (
      !factoryResetDone &&
      millis() - buttonPressStart >= FACTORY_RESET_HOLD_MS
    ) {
      factoryResetAndEnterConfigMode();
    }
  } else {
    buttonWasPressed = false;
    if (!configMode) {
      factoryResetDone = false;
    }
  }

  updateConfigLed();
}

void tickNtpSync() {
  if (configMode || WiFi.status() != WL_CONNECTED || ntpSynced) return;

  if (!ntpSyncRequested) {
    configTime(
      GMT_OFFSET_SECONDS,
      DAYLIGHT_OFFSET_SECONDS,
      NTP_SERVER_1,
      NTP_SERVER_2
    );
    ntpSyncRequested = true;
    ntpSyncStarted = millis();
    Serial.print("Dang dong bo gio NTP");
  }

  struct tm timeInfo;

  if (getLocalTime(&timeInfo)) {
    Serial.println();
    Serial.println("Dong bo gio NTP OK");
    ntpSynced = true;
    return;
  }

  if (millis() - ntpSyncStarted >= ntpSyncTimeoutMs) {
    Serial.println();
    Serial.println("Khong dong bo duoc gio NTP");
    ntpSynced = true;
  }
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

void startWifiConnect() {
  if (configMode || apPending || wifiSsid.length() == 0) return;

  WiFi.setAutoReconnect(false);
  WiFi.persistent(false);
  WiFi.mode(WIFI_STA);
  WiFi.begin(wifiSsid.c_str(), wifiPass.c_str());
  wifiConnecting = true;
  wifiConnectStarted = millis();
  lastWifiRetryAt = millis();

  Serial.print("Dang ket noi WiFi: ");
  Serial.println(wifiSsid);
}

void tickWiFi() {
  if (configMode || apPending || wifiSsid.length() == 0) return;

  if (WiFi.status() == WL_CONNECTED) {
    if (wifiConnecting) {
      wifiConnecting = false;
      Serial.print("WiFi OK, IP ESP32: ");
      Serial.println(WiFi.localIP());
      ntpSynced = false;
      ntpSyncRequested = false;
    }

    tickNtpSync();
    return;
  }

  unsigned long now = millis();

  if (wifiConnecting) {
    if (now - wifiConnectStarted >= wifiConnectTimeoutMs) {
      wifiConnecting = false;
      Serial.println("WiFi loi, se thu lai sau");
    }
    return;
  }

  if (now - lastWifiRetryAt >= wifiRetryIntervalMs) {
    startWifiConnect();
  }
}

float rawToPercent(int raw) {
  if (SoilDryRaw == SoilWetRaw) return 0.0f;

  float percent =
    (float)(SoilDryRaw - raw) * 100.0f /
    (float)(SoilDryRaw - SoilWetRaw);

  if (percent < 0.0f) return 0.0f;
  if (percent > 100.0f) return 100.0f;

  return percent;
}

int readSoilRaw() {
  long sum = 0;
  for (int i = 0; i < SoilMoistureSamples; i++) {
    sum += analogRead(SOIL_PIN);
    delay(5);
  }
  return (int)(sum / SoilMoistureSamples);
}

void readSensors() {
  if (bmeFound) {
    latestTemperature = bme.readTemperature();
    latestPressureHpa = bme.readPressure() / 100.0f;
    latestHumidity = bme.readHumidity();

    Serial.print("BME280 - Nhiet do: ");
    Serial.print(latestTemperature);
    Serial.print(" *C | Ap suat: ");
    Serial.print(latestPressureHpa);
    Serial.print(" hPa | Do am KK: ");
    Serial.print(latestHumidity, 1);
    Serial.println(" %");
  } else {
    latestTemperature = NAN;
    latestPressureHpa = NAN;
    latestHumidity = NAN;
    Serial.println("BME280 - Khong co du lieu");
  }

  latestSoilRaw = readSoilRaw();
  latestSoilPercent = rawToPercent(latestSoilRaw);

  Serial.print("Do am dat - Raw: ");
  Serial.print(latestSoilRaw);
  Serial.print(" | Percent: ");
  Serial.print(latestSoilPercent, 1);
  Serial.println(" %");

  // Đọc cảm biến mực nước Analog (Lấy mẫu trung bình 5 lần tránh sốc điện áp)
  long waterSum = 0;
  for (int i = 0; i < 5; i++) {
    waterSum += analogRead(WATER_PIN);
    delay(5);
  }
  latestWaterRaw = (int)(waterSum / 5);

  Serial.print("Muc nuoc - Raw: ");
  Serial.println(latestWaterRaw);
}

void postPumpSession(
  unsigned long durationSeconds,
  const String& triggeredBy,
  const String& deviceId
) {
  if (WiFi.status() != WL_CONNECTED || configMode) return;

  String url =
    "http://" + apiHost + ":" + String(apiPort) +
    "/api/pump/session";

  HTTPClient http;
  http.setConnectTimeout(httpTimeoutMs);
  http.setTimeout(httpTimeoutMs);
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("X-ESP32-Token", API_TOKEN);

  time_t endEpoch = getCurrentEpochSeconds();
  time_t startEpoch =
    endEpoch > 0 ? endEpoch - (time_t)durationSeconds : 0;

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
  if (WiFi.status() != WL_CONNECTED || configMode) return;

  {
    String url =
      "http://" + apiHost + ":" + String(apiPort) +
      "/api/pump/latest?deviceId=" + String(DEVICE_ID);

    HTTPClient http;
    http.setConnectTimeout(httpTimeoutMs);
    http.setTimeout(httpTimeoutMs);
    http.begin(url);
    http.addHeader("X-ESP32-Token", API_TOKEN);

    int code = http.GET();

    if (code == 200) {
      String body = http.getString();
      String commandTimestamp =
        extractJsonStringValue(body, "timestamp");

      if (
        commandTimestamp.length() > 0 &&
        commandTimestamp != lastPumpCommandTimestamp
      ) {
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

  {
    String url =
      "http://" + apiHost + ":" + String(apiPort) +
      "/api/pump/latest?deviceId=pump_drain_01";

    HTTPClient http;
    http.setConnectTimeout(httpTimeoutMs);
    http.setTimeout(httpTimeoutMs);
    http.begin(url);
    http.addHeader("X-ESP32-Token", API_TOKEN);

    int code = http.GET();

    if (code == 200) {
      String body = http.getString();
      String commandTimestamp =
        extractJsonStringValue(body, "timestamp");

      if (
        commandTimestamp.length() > 0 &&
        commandTimestamp != lastDrainCommandTimestamp
      ) {
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

void pollSystemSettings() {
  if (WiFi.status() != WL_CONNECTED || configMode) return;

  String url = "http://" + apiHost + ":" + String(apiPort) + "/api/settings";

  HTTPClient http;
  http.setConnectTimeout(httpTimeoutMs);
  http.setTimeout(httpTimeoutMs);
  http.begin(url);

  int code = http.GET();

  if (code == 200) {
    String body = http.getString();
    String mode = extractJsonStringValue(body, "systemMode");
    String soilThreshStr = extractJsonStringValue(body, "soilMoistureThreshold");
    String waterThreshStr = extractJsonStringValue(body, "waterLevelThreshold");

    if (mode == "manual") {
      isAutoMode = false;
    } else {
      isAutoMode = true;
    }

    if (soilThreshStr.length() > 0) {
      soilPumpOnPercent = soilThreshStr.toFloat();
    }
    if (waterThreshStr.length() > 0) {
      waterLevelThresholdPercent = waterThreshStr.toFloat();
    }
  }

  http.end();
}

void uploadToLocalApi() {
  if (WiFi.status() != WL_CONNECTED || configMode) return;

  if (isnan(latestTemperature) || isnan(latestSoilPercent)) {
    return;
  }

  float safePressure =
    isnan(latestPressureHpa) ? 0.0f : latestPressureHpa;
  float safeHumidity =
    isnan(latestHumidity) ? 0.0f : latestHumidity;

  String url =
    "http://" + apiHost + ":" + String(apiPort) +
    "/api/sensors/ingest";

  HTTPClient http;
  http.setConnectTimeout(httpTimeoutMs);
  http.setTimeout(httpTimeoutMs);
  http.begin(url);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("X-ESP32-Token", API_TOKEN);

  String payload = "{";
  payload += "\"deviceId\":\"" + String(DEVICE_ID) + "\",";
  payload += "\"soil_raw\":" + String(latestSoilRaw) + ",";
  payload += "\"soil_moisture\":" + String(latestSoilPercent, 1) + ",";
  payload += "\"humidity\":" + String(safeHumidity, 1) + ",";
  payload += "\"temperature\":" + String(latestTemperature, 1) + ",";
  payload += "\"pressure\":" + String(safePressure, 1) + ",";
  payload += "\"water_raw\":" + String(latestWaterRaw) + ","; // Đã thêm khoá truyền dữ liệu mực nước lên API
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
  if (!isAutoMode) {
    return; // Don't run auto rules if system is in manual mode!
  }

  // LUẬT TỰ ĐỘNG BƠM TƯỚI (IN)
  if (
    !isnan(latestSoilPercent) &&
    latestSoilPercent <= soilPumpOnPercent &&
    !relayTriggered &&
    !pumpOn
  ) {
    Serial.print("Do am dat <= ");
    Serial.print(soilPumpOnPercent, 0);
    Serial.println("% -> Bat relay tuoi 5 giay");

    digitalWrite(RELAY_IN, HIGH);
    pumpOn = true;
    pumpStartedAt = millis();
    pumpTrigger = "auto";
    relayTriggered = true;
  }

  if (
    pumpOn &&
    pumpTrigger == "auto" &&
    millis() - pumpStartedAt >= pumpDurationMs
  ) {
    digitalWrite(RELAY_IN, LOW);
    pumpOn = false;

    unsigned long dur = (millis() - pumpStartedAt) / 1000;
    postPumpSession(dur, pumpTrigger, String(DEVICE_ID));

    Serial.println("Tat relay tuoi (auto)");
  }

  if (
    !isnan(latestSoilPercent) &&
    latestSoilPercent >= (soilPumpOnPercent + 10.0f)
  ) {
    relayTriggered = false;
  }

  // LUẬT TỰ ĐỘNG BƠM THOÁT (OUT) THEO CẢM BIẾN MỰC NƯỚC
  // Quy đổi mực nước sang %
  float latestWaterPercent = ((float)latestWaterRaw * 100.0f) / 2500.0f;

  // Nếu mực nước vượt ngưỡng báo động (%) và bơm thoát đang tắt
  if (latestWaterPercent >= waterLevelThresholdPercent && !drainOn) {
    Serial.print("Canh bao: Nuoc ngap! Percent = ");
    Serial.print(latestWaterPercent, 1);
    Serial.println("% -> Tu dong bat bom thoat");

    digitalWrite(RELAY_OUT, HIGH);
    drainOn = true;
    drainStartedAt = millis();
  }

  // Tự động ngắt bơm thoát khi mực nước hạ xuống an toàn (Dưới ngưỡng bật 16%)
  if (drainOn && latestWaterPercent < (waterLevelThresholdPercent - 16.0f)) {
    Serial.println("Nuoc da rut an toan -> Tu dong tat bom thoat");
    digitalWrite(RELAY_OUT, LOW);
    drainOn = false;

    unsigned long dur = (millis() - drainStartedAt) / 1000;
    postPumpSession(dur, "auto", "pump_drain_01"); // Gửi phiên ghi nhận lịch sử bơm tự động về Server
  }
}

void setup() {
  Serial.begin(115200);

  WiFi.setAutoReconnect(false);
  WiFi.persistent(false);

  pinMode(BUTTON_PIN, INPUT_PULLUP);
  pinMode(CONFIG_LED, OUTPUT);
  digitalWrite(CONFIG_LED, LOW);

  pinMode(RELAY_IN, OUTPUT);
  digitalWrite(RELAY_IN, LOW);

  pinMode(RELAY_OUT, OUTPUT);
  digitalWrite(RELAY_OUT, LOW);

  loadConfig();

  Wire.begin(I2C_SDA, I2C_SCL);
  analogReadResolution(12);
  analogSetPinAttenuation(SOIL_PIN, ADC_11db);
  analogSetPinAttenuation(WATER_PIN, ADC_11db); // Cấu hình ADC chân đọc mực nước tương thích dải điện áp nguồn

  bmeFound = bme.begin(0x76);
  if (!bmeFound) {
    bmeFound = bme.begin(0x77);
  }

  if (bmeFound) {
    bme.setSampling(
      Adafruit_BME280::MODE_NORMAL,
      Adafruit_BME280::SAMPLING_X2,
      Adafruit_BME280::SAMPLING_X16,
      Adafruit_BME280::SAMPLING_X1,
      Adafruit_BME280::FILTER_OFF,
      Adafruit_BME280::STANDBY_MS_0_5
    );
    Serial.println("BME280 OK");
  } else {
    Serial.println("Khong tim thay BME280 (kiem tra day I2C, dia chi 0x76/0x77)");
  }

  Serial.println("Dang khoi dong...");
}

void loop() {
  checkFactoryResetButton();
  tickPendingRestart();
  tickApSetup();

  if (!bootComplete) {
    bootComplete = true;
    finishBootNetworking();

    Serial.println("Giu nut G25 trong 5 giay de reset factory va vao che do AP");
    Serial.print("Trang thai nut G25 luc khoi dong: ");
    Serial.println(digitalRead(BUTTON_PIN) == LOW ? "DANG NHAN" : "KHONG NHAN");
  }

  if (configMode) {
    ensureApActive();
    updateConfigLed();
    configServer.handleClient();
    return;
  }

  tickWiFi();

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

  if (now - lastSettingsPollAt >= settingsPollIntervalMs) {
    lastSettingsPollAt = now;
    pollSystemSettings();
  }
}