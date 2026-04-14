# Smart Agriculture IoT App 🌱

Ứng dụng hệ thống tưới cây tự động và giám sát môi trường nông nghiệp sử dụng IoT qua ESP32 với Flutter.

![Flutter](https://img.shields.io/badge/Flutter-3.11+-blue.svg)
![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 🌱 Giới Thiệu

Smart Agriculture IoT là ứng dụng hệ thống tưới cây thông minh cho phép bạn:
- 💧 Điều khiển máy bơm và van tưới từ xa
- 🌡️ Giám sát nhiệt độ, độ ẩm đất, độ ẩm không khí realtime  
- 📈 Phân tích dữ liệu cảm biến
- ⏰ Lập lịch tưới tự động
- 🔔 Nhận thông báo và cảnh báo
- 🌓 Hỗ trợ Dark mode

## ✨ Tính Năng

### 🔐 Xác Thực
- Đăng ký tài khoản
- Đăng nhập/Đăng xuất
- Quản lý profile

### 🌿 Quản Lý Thiết Bị Nông Nghiệp
- Xem danh sách thiết bị (máy bơm, van tưới, cảm biến)
- Bật/tắt máy bơm và van tưới
- Điều chỉnh lưu lượng nước
- Xem trạng thái online/offline

### 💧 Giám Sát Cảm Biến
- Độ ẩm đất (Soil Moisture)
- Nhiệt độ không khí (Temperature)
- Độ ẩm không khí (Humidity)
- Cường độ ánh sáng (Light Intensity)

### ⏰ Lập Lịch Tưới
- Tạo lịch tưới tự động
- Chọn ngày giờ cụ thể
- Bật/tắt lịch

### 📉 Phân Tích
- Biểu đồ tiêu thụ nước
- Thống kê theo ngày/tuần/tháng
- Phân tích độ ẩm đất

## 🛠️ Công Nghệ

- **Framework**: Flutter 3.11+
- **Language**: Dart 3.0+
- **State Management**: Provider
- **UI**: Material Design 3
- **IoT**: ESP32, MQTT, WebSocket

## 🚀 Cài Đặt

Xem chi tiết trong [INSTALLATION_GUIDE.md](INSTALLATION_GUIDE.md)

```bash
# Clone và cài đặt
git clone https://github.com/yourusername/smart-agriculture-iot.git
cd smart-agriculture-iot
flutter pub get

# Chạy app
flutter run
```

## 👨‍🌾 Đề Tài

**Thiết kế và xây dựng hệ thống tưới cây tự động và giám sát môi trường nông nghiệp sử dụng công nghệ IoT**

### Mục tiêu:
- Xây dựng hệ thống điều khiển tưới cây tự động, giám sát môi trường và tưới cây tự động
- Ứng dụng IoT để theo dõi và điều khiển hệ thống từ xa

### Kết quả dự kiến:
- Hệ thống có khả năng giám sát môi trường theo thời gian thực
- Tự động bật/tắt máy bơm khi độ ẩm đất thay đổi
- Người dùng có thể theo dõi và điều khiển từ xa qua Internet
- Góp phần tiết kiệm nước và nâng cao hiệu quả chăm sóc cây trồng

## 📖 Documentation

- [Wireframe & UI/UX Design](WIREFRAME_UI_UX.md)
- [Installation Guide](INSTALLATION_GUIDE.md)

## 📧 Contact

- Email: your.email@example.com
- GitHub: [@yourusername](https://github.com/yourusername)

---

⭐ **Star this repo if you find it helpful!**
