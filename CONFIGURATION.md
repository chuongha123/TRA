# Configuration Guide - Hướng dẫn Cấu hình

## Overview
Dự án Tra IoT đã được cấu hình để sử dụng dữ liệu thực từ cảm biến ESP32 và server Node.js. Hướng dẫn này giúp bạn thiết lập môi trường với các thông số thực.

## 1. Server Configuration (Node.js)

### Biến môi trường (Environment Variables)

Tạo file `.env` trong thư mục `server/`:

```bash
# server/.env
PORT=3000
MONGODB_URI=mongodb://127.0.0.1:27017
MONGODB_DB_NAME=smartfarm
ESP32_TOKEN=esp32-secret
ENABLE_CORS=true
```

**Giải thích:**
- `PORT`: Cổng server chạy trên (mặc định 3000)
- `MONGODB_URI`: URI kết nối MongoDB (local hoặc cloud như MongoDB Atlas)
- `MONGODB_DB_NAME`: Tên database MongoDB
- `ESP32_TOKEN`: Token xác thực cho các request từ ESP32
- `ENABLE_CORS`: Bật/tắt CORS (cần bật để Flutter app kết nối)

### Khởi động Server

```bash
cd server
npm install
npm start
```

Server sẽ lắng nghe tại `http://localhost:3000`

### API Endpoints

Các endpoint chính:
- `POST /api/sensors/ingest` - Nhận dữ liệu cảm biến từ ESP32
- `GET /api/sensors/latest` - Lấy dữ liệu cảm biến mới nhất
- `GET /api/sensors/history` - Lấy lịch sử dữ liệu cảm biến
- `POST /api/pump/toggle` - Bật/tắt máy bơm
- `GET /api/pump/latest` - Trạng thái máy bơm mới nhất
- `POST /api/pump/session` - Ghi lại phiên tưới nước
- `GET /api/pump/sessions` - Lịch sử tưới nước

## 2. Flutter App Configuration

### Option A: Sử dụng Dart Defines (Build-time)

Compile app với biến môi trường:

```bash
# Cho Android/iOS emulator
flutter run

# Cho real device với server local
flutter run --dart-define=API_BASE_URL="http://192.168.1.100:3000/api" \
            --dart-define=WEBSOCKET_URL="ws://192.168.1.100:3000" \
            --dart-define=ESP32_HOST="192.168.1.100"

# Build APK
flutter build apk --dart-define=API_BASE_URL="http://192.168.1.100:3000/api"
```

**Các biến có sẵn:**
- `API_BASE_URL`: URL API server (mặc định: `http://10.0.2.2:3000/api`)
- `WEBSOCKET_URL`: URL WebSocket (mặc định: `ws://10.0.2.2:3000`)
- `ESP32_HOST`: IP địa chỉ ESP32 (mặc định: `192.168.1.100`)

### Option B: Chỉnh sửa trong Code

Chỉnh sửa `Tra/lib/constants/app_constants.dart`:

```dart
static const String apiBaseUrl = 'http://192.168.1.100:3000/api';  // Thay IP server
static const String esp32DefaultHost = '192.168.1.100';  // IP ESP32
```

### Zones Configuration

Thay đổi danh sách khu vực trong `Tra/lib/constants/app_constants.dart`:

```dart
static const List<String> availableZones = [
  'Vườn rau A',      // Khu vực 1
  'Vườn hoa B',      // Khu vực 2
  'Nhà kính C',      // Khu vực 3
  'Vườn cây ăn quả', // Khu vực 4
];
```

## 3. ESP32 Configuration

### Hardware Setup

Cầu nối GPIO cho ESP32-DevKitC:

```
DHT11        → GPIO 17
BMP280 SDA   → GPIO 21
BMP280 SCL   → GPIO 22
Soil Sensor  → GPIO 32 (ADC)
Relay (Pump) → GPIO 5
```

### Software Configuration

Chỉnh sửa `main.ino`:

```cpp
// WiFi - Thay với SSID và password thực tế
const char* WIFI_SSID = "YOUR_WIFI_SSID";
const char* WIFI_PASS = "YOUR_WIFI_PASSWORD";

// Server - Thay với IP của máy chạy Node.js server
const char* API_HOST = "192.168.1.100";
const int API_PORT = 3000;

// Device Identity
const char* DEVICE_ID = "esp32_garden_01";  // Có thể đặt tên khác
const char* API_TOKEN = "esp32-secret";     // Phải match với ESP32_TOKEN trên server
```

### Upload to ESP32

```bash
# Sử dụng Arduino IDE hoặc PlatformIO
# PlatformIO command:
pio run -t upload

# Hoặc sử dụng esptool.py
esptool.py -p /dev/ttyUSB0 write_flash 0x0 firmware.bin
```

## 4. Network Setup

### Local Network Configuration

Đảm bảo các thiết bị trong cùng mạng WiFi:

```
App (Phone/Tablet)    ← WiFi → Router
ESP32                 ← WiFi → Router  
Server (Computer)     ← Ethernet/WiFi → Router
```

### Find Device IPs

**Windows:**
```bash
ipconfig
```

**macOS/Linux:**
```bash
ifconfig
```

### Test Connectivity

**Kiểm tra server:**
```bash
curl http://192.168.1.100:3000/api/health
# Response: {"ok":true,"message":"Server and database are ready"}
```

**Kiểm tra ESP32:**
```bash
ping 192.168.1.100
# Hoặc mở Web Serial Monitor trong Arduino IDE để xem logs
```

## 5. MongoDB Setup

### Local MongoDB

```bash
# Windows (using MongoDB Community Edition)
mongod --dbpath "C:\data\db"

# macOS
brew services start mongodb-community

# Linux
sudo systemctl start mongod
```

### Cloud MongoDB (MongoDB Atlas)

1. Tạo tài khoản tại https://www.mongodb.com/cloud/atlas
2. Tạo cluster
3. Lấy connection string: `mongodb+srv://username:password@cluster.mongodb.net/smartfarm`
4. Cập nhật `MONGODB_URI` trong `server/.env`

## 6. Sensor Calibration

### Soil Moisture Sensor

Chỉnh sửa giá trị hiệu chuẩn trong `main.ino`:

```cpp
const int AirValue = 520;    // Giá trị ADC khi khô (không chạm đất)
const int WaterValue = 260;  // Giá trị ADC khi ướt (chạm nước)
```

**Cách hiệu chuẩn:**
1. Bật Serial Monitor (Baud: 115200)
2. Để cảm biến ở không khí, ghi lại giá trị ADC
3. Nhúng cảm biến vào nước, ghi lại giá trị ADC
4. Cập nhật AirValue và WaterValue

## 7. Troubleshooting

### App không kết nối được server

**Kiểm tra:**
- IP server có chính xác? (ping IP)
- Firewall có block port 3000?
- Server có đang chạy? (check logs)
- CORS có bật trong `server/.env`?

### ESP32 không gửi dữ liệu

**Kiểm tra:**
- WiFi có kết nối? (Serial Monitor)
- Token có khớp với server config?
- API_HOST có chính xác?
- Sensors có connect đúng GPIO?

### MongoDB connection error

**Kiểm tra:**
- MongoDB service có chạy?
- Connection string có chính xác?
- Firewall/Network có cho phép?

## 8. Security Considerations

⚠️ **Important for Production:**

1. **Thay đổi API_TOKEN** - Không sử dụng token mặc định
2. **Sử dụng HTTPS/WSS** - Thay vì HTTP/WS
3. **Set MongoDB credentials** - Không để public access
4. **Firewall rules** - Chỉ cho phép IPs cần thiết
5. **Rotate credentials** - Định kỳ thay đổi mật khẩu

## 9. References

- [Flutter Build Modes](https://flutter.dev/docs/testing/build-modes)
- [Node.js Environment Variables](https://nodejs.org/en/docs/guides/nodejs-env-var/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [ESP32 Arduino Documentation](https://docs.espressif.com/projects/arduino-esp32/en/latest/)

---

**Last Updated:** April 2026
**Version:** 1.0.0
