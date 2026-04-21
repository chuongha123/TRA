# Pump Control Bug Fixes - Hướng dẫn Kiểm tra

## 🐛 Vấn đề Tìm Được

### 1. **Race Condition - Bấm nhanh nhiều lần** ✅ FIXED
- **Vấn đề**: Khi bấm bút ON/OFF nhanh nhiều lần, nhiều API request gửi cùng lúc gây state inconsistency
- **Fix**: Thêm flag `_isTogglingPump` để ngăn rapid toggle. Nếu đang toggle, click sẽ bị ignore

### 2. **Không có Loading State** ✅ FIXED
- **Vấn đề**: UI không hiển thị loading spinner khi đang gửi request tới server
- **Fix**: 
  - Thêm `isToggling` getter để UI check
  - Pump button hiển thị spinner khi đang toggle
  - Button disable (không click được) khi loading

### 3. **Silent Error Handling** ✅ FIXED
- **Vấn đề**: Nếu API call fail, user không biết (error bị catch mà không log)
- **Fix**:
  - Thêm `pumpErrorMessage` để lưu error
  - Hiển thị error message dưới pump button
  - Add console logging (print) để debug
  - User có thể dismiss error bằng nút close

### 4. **Duplicate Pump Logs** ✅ FIXED
- **Vấn đề**: Khi fetch state từ server, nếu state thay đổi, nó lại gọi `_setPumpStateLocal()` tạo duplicate log
- **Fix**: Check `stateChanged` trước, chỉ log khi state thực sự thay đổi

### 5. **Incomplete Irrigation Sessions** ✅ FIXED
- **Vấn đề**: Khi pump tắt, session không được gửi lên server
- **Fix**: Thêm hàm `_uploadIrrigationSession()` để post session data khi pump tắt

### 6. **API Timeout Quá Ngắn** ✅ FIXED
- **Vấn đề**: 4 giây timeout quá ngắn cho mạng chậm
- **Fix**: Tăng thành 5 giây timeout

## 📋 Checklist Kiểm Tra

### Test 1: Bấm Bơm Đơn Giản
```
1. Mở app
2. Nhấn nút "Bật bơm" → Máy bơm nên chạy
3. Xem spinner quay trong 0.5-1.5 giây
4. Khi thành công, button hiển thị "Máy bơm đang chạy"
5. Nhấn nút "Tắt bơm" → Máy bơm nên tắt
6. Kiểm tra log trong Irrigation History screen
```

### Test 2: Bấm Nhanh Nhiều Lần (Race Condition)
```
1. Bấm ON/OFF liên tục 5-10 lần nhanh
2. App nên lock button sau lần bấm đầu tiên
3. Chỉ một request được gửi tới server
4. State nên consistent, không nhập nhoạn
```

### Test 3: Server Offline (Error Handling)
```
1. Tắt Node.js server (hoặc kill process)
2. Nhấn bơm ON
3. Kỳ vọng:
   - Loading spinner hiển thị ~5 giây
   - Sau 5 giây, error message xuất hiện:
     "Không thể điều khiển bơm. Kiểm tra kết nối server"
   - Pump state revert về OFF (không lock ở ON)
4. Nhấn nút X trên error message để dismiss
5. Khởi động lại server, test lại bơm
```

### Test 4: Slow Network (Timeout)
```
1. Từ Network Developer Tools, throttle connection (slow 3G)
2. Nhấn bơm
3. Xem spinner quay 3-5 giây
4. Nếu request succeed, button update
5. Nếu timeout, error message xuất hiện
```

### Test 5: Irrigation Session Logging
```
1. Bấm bơm ON, chờ ~30 giây
2. Bấm bơm OFF
3. Vào Irrigation History screen
4. Kiểm tra:
   - Có một session mới nhất
   - Start time = khi bấm ON
   - End time = khi bấm OFF
   - Duration = ~30 phút
   - Flow amount = duration * 12 liters
5. Scroll xuống, kiểm tra history ngày hôm trước
```

### Test 6: Scheduled Irrigation
```
1. Tạo schedule bơm lúc [current_time + 1 minute]
2. Chờ schedule execute
3. Pump nên bật tự động
4. Sau duration, pump tắt tự động
5. Kiểm tra log có "schedule" trigger type
```

### Test 7: Multiple Device Scenarios
```
1. Mở app trên 2 device/browser
2. Bấm bơm trên device 1
3. Device 2 nên refresh state trong 5 giây
4. Cả 2 device nên consistent
```

## 🔍 Debugging Tips

### Xem Console Logs
- Mở terminal/console của Flutter app
- Tìm dòng:
  - `Pump toggle API error: 400` → Check request format
  - `Pump toggle timeout` → Network issue
  - `Pump toggle error: ...` → Unexpected error

### Check Server Logs
```bash
# Terminal server (Node.js)
# Xem logs để confirm pump toggle request được nhận
```

### Check Database
```bash
# Connect tới MongoDB
mongo

use smartfarm
db.pump_events.find().sort({created_at: -1}).limit(5)
db.irrigation_sessions.find().sort({created_at: -1}).limit(5)
```

## 🚀 Deployment Checklist

- [ ] Test pump toggle basic scenario
- [ ] Test rapid clicks (race condition)
- [ ] Test error handling (server offline)
- [ ] Test slow network (timeout)
- [ ] Test irrigation session logging
- [ ] Test scheduled irrigation
- [ ] Verify MongoDB records created correctly
- [ ] Check console for any print() errors
- [ ] Test on real device (not just emulator)

## 📝 Files Changed

1. **chedog/lib/providers/sensor_provider.dart**
   - Added `_isTogglingPump`, `_pumpErrorMessage` state variables
   - Made `togglePump()` async với race condition prevention
   - Improved `_sendPumpToggle()` with better error handling
   - Fixed `_setPumpStateLocal()` to prevent duplicate logging
   - Added `_uploadIrrigationSession()` để post session data

2. **chedog/lib/screens/home_dashboard.dart**
   - Updated `_buildPumpButton()` để hiển thị loading spinner
   - Added error message display with dismiss button
   - Disabled button during toggle

## ⚠️ Known Limitations

1. **Background Pump Auto-Stop**: Nếu app close khi pump đang chạy, pump sẽ không auto-stop (cần backend timeout)
2. **Flow Calculation**: Vẫn sử dụng constant 12L/min (cần flow meter hardware)
3. **Device Hardcoding**: Device ID vẫn hardcoded 'esp32_garden_01' (cần config UI)

---

**Last Updated**: April 2026
**Status**: ✅ Ready for Testing
