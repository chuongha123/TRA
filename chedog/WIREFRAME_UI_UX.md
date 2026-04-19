# Ứng Dụng Smart Home IoT - Tài Liệu UI/UX

## Tổng Quan Dự Án

Ứng dụng Smart Home IoT cho phép người dùng điều khiển và giám sát các thiết bị thông minh trong nhà qua ESP32. Ứng dụng được thiết kế với phong cách Material Design hiện đại, tối giản với màu sắc xanh dương + trắng làm chủ đạo.

### Tính Năng Chính
- ✅ Đăng ký và đăng nhập tài khoản
- ✅ Điều khiển thiết bị từ xa
- ✅ Theo dõi trạng thái realtime
- ✅ Lập lịch tự động
- ✅ Phân tích dữ liệu năng lượng
- ✅ Thông báo và cảnh báo
- ✅ Dark mode
- ✅ Dashboard với biểu đồ

### Công Nghệ Sử Dụng
- **Framework**: Flutter 3.11+
- **State Management**: Provider
- **HTTP Client**: Dio, HTTP
- **Realtime**: WebSocket, MQTT
- **Charts**: FL Chart, Syncfusion Charts
- **Storage**: SharedPreferences
- **UI Components**: Material Design 3

---

## Màu Sắc & Theme

### Light Mode
- **Primary**: `#2196F3` (Blue)
- **Primary Dark**: `#1976D2`
- **Primary Light**: `#64B5F6`
- **Accent**: `#00BCD4` (Cyan)
- **Background**: `#F5F7FA`
- **Surface**: `#FFFFFF`
- **Text Primary**: `#212121`
- **Text Secondary**: `#757575`

### Dark Mode
- **Background**: `#121212`
- **Surface**: `#1E1E1E`
- **Card**: `#2C2C2C`
- **Text Primary**: `#FFFFFF`
- **Text Secondary**: `#B0B0B0`

### Status Colors
- **Success**: `#4CAF50` (Green)
- **Warning**: `#FF9800` (Orange)
- **Error**: `#F44336` (Red)
- **Info**: `#2196F3` (Blue)
- **Device Online**: `#00C853`
- **Device Offline**: `#D32F2F`

---

## 1. Splash Screen

### Mô Tả
Màn hình khởi động ứng dụng với animation mượt mà.

### Wireframe
```
┌─────────────────────────────┐
│                             │
│                             │
│         [GRADIENT]          │
│                             │
│      ┌──────────┐           │
│      │   🏠     │           │ ← App Icon
│      └──────────┘           │
│                             │
│   SMART HOME IOT            │ ← App Name
│                             │
│  Control Your Smart Home    │ ← Tagline
│                             │
│         (●●●●●)             │ ← Loading Indicator
│                             │
│                             │
└─────────────────────────────┘
```

### UI Elements
- **Background**: Gradient xanh dương (Primary → Primary Dark)
- **App Icon**: Container trắng bo góc 30px, bóng đổ, icon home màu primary
- **App Name**: Font size 32, bold, màu trắng, letter-spacing 1.5
- **Tagline**: Font size 16, màu trắng 70%
- **Loading**: CircularProgressIndicator màu trắng

### Animation
- Fade in + Scale animation 1.5s
- Tự động chuyển sang Login sau 3s

### Kích Thước
- App Icon: 120x120px
- Spacing giữa các elements: 10-30px

---

## 2. Login Screen

### Mô Tả
Màn hình đăng nhập với form validation đầy đủ.

### Wireframe
```
┌─────────────────────────────┐
│                             │
│      ┌──────────┐           │
│      │   🏠     │           │ ← Logo (100x100)
│      └──────────┘           │
│                             │
│    Welcome Back             │ ← Title
│   Sign in to continue       │ ← Subtitle
│                             │
│  ┌──────────────────────┐   │
│  │ 👤 Username          │   │ ← Username Field
│  └──────────────────────┘   │
│                             │
│  ┌──────────────────────┐   │
│  │ 🔒 Password     👁    │   │ ← Password Field
│  └──────────────────────┘   │
│                             │
│           Forgot Password?  │ ← Link
│                             │
│  ┌──────────────────────┐   │
│  │       LOGIN          │   │ ← Login Button
│  └──────────────────────┘   │
│                             │
│  ────────── OR ──────────   │
│                             │
│     [G]         [f]         │ ← Social Login
│                             │
│  Don't have account? SignUp │
└─────────────────────────────┘
```

### UI Elements

#### Logo Section
- Container 100x100, background primary opacity 10%, bo tròn
- Icon home màu primary size 50

#### Title Section
- **Title**: "Welcome Back" - Font 24, bold
- **Subtitle**: "Sign in to continue" - Font 16, secondary color

#### Form Fields
- **Username Field**:
  - Label: "Username"
  - Prefix icon: person_outline
  - Border radius: 12px
  - Validation: Required
  
- **Password Field**:
  - Label: "Password"
  - Prefix icon: lock_outline
  - Suffix icon: visibility toggle
  - Border radius: 12px
  - Validation: Required, min 6 chars

#### Buttons
- **Login Button**:
  - Width: Full width
  - Height: 50px
  - Background: Primary gradient
  - Text: "Login", white, size 16, bold
  - Loading state: CircularProgressIndicator

- **Social Buttons**:
  - Size: 50x50
  - Border: 1px solid border color
  - Border radius: 12px
  - Icons: Google (G), Facebook (f)

#### Links
- **Forgot Password**: Right aligned, primary color
- **Sign Up**: Bottom, TextButton, primary color

### Spacing
- Padding: 24px all around
- Field spacing: 16px
- Button spacing: 24px from fields

---

## 3. Register Screen

### Mô Tả
Màn hình đăng ký tài khoản mới.

### Wireframe
```
┌─────────────────────────────┐
│  ← Register                 │ ← AppBar
├─────────────────────────────┤
│                             │
│    Sign Up                  │ ← Title
│  Create your account        │ ← Subtitle
│                             │
│  ┌──────────────────────┐   │
│  │ 👤 Full Name         │   │
│  └──────────────────────┘   │
│                             │
│  ┌──────────────────────┐   │
│  │ ✉️  Email            │   │
│  └──────────────────────┘   │
│                             │
│  ┌──────────────────────┐   │
│  │ 👤 Username          │   │
│  └──────────────────────┘   │
│                             │
│  ┌──────────────────────┐   │
│  │ 🔒 Password     👁    │   │
│  └──────────────────────┘   │
│                             │
│  ┌──────────────────────┐   │
│  │ 🔒 Confirm Pass 👁    │   │
│  └──────────────────────┘   │
│                             │
│  ☑ I agree to Terms &       │
│     Conditions              │
│                             │
│  ┌──────────────────────┐   │
│  │   SIGN UP            │   │
│  └──────────────────────┘   │
│                             │
│ Already have account? Login │
└─────────────────────────────┘
```

### UI Elements

#### Form Fields (Tuần tự từ trên xuống)
1. **Full Name**: person_outline icon
2. **Email**: email_outlined icon, email validation
3. **Username**: account_circle_outlined icon, min 3 chars
4. **Password**: lock_outline icon, toggle visibility, min 6 chars
5. **Confirm Password**: lock_outline icon, match password

#### Checkbox
- Terms & Conditions với link màu primary

#### Button
- Sign Up button: Full width, 50px height, primary color

#### Navigation
- Back button trên AppBar
- Login link ở bottom

---

## 4. Home Dashboard

### Mô Tả
Màn hình chính hiển thị tổng quan các thiết bị và phòng.

### Wireframe
```
┌─────────────────────────────┐
│ Good Morning          🔔 ⚙️  │ ← AppBar
│ Tra                    │
├─────────────────────────────┤
│  ┌─────────────────────┐    │
│  │ Living Room    ☀️   │    │ ← Environment Card
│  │                     │    │   (Gradient background)
│  │  🌡️ 24°C           │    │
│  │                     │    │
│  │  💧 65%  🌬️ Good   │    │
│  └─────────────────────┘    │
│                             │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐       │
│  │💡│ │⏰│ │📊│ │➕│       │ ← Quick Actions
│  └──┘ └──┘ └──┘ └──┘       │
│   All Schedule Data Add     │
│                             │
│  Rooms              See All │ ← Section Header
│  ┌────┐ ┌────┐ ┌────┐      │
│  │🛋️ │ │🛏️ │ │🍳 │      │ ← Room Cards
│  │Living│Bedroom│Kitchen│   │   (Horizontal scroll)
│  │8 dev│6 dev │4 dev  │    │
│  └────┘ └────┘ └────┘      │
│                             │
│  Devices            See All │
│  ┌─────────────────────┐    │
│  │ 💡 Living Room      │    │ ← Device Cards
│  │    Light    ● ON  🔘│    │   (Vertical list)
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │ ❄️ Smart AC         │    │
│  │    Bedroom  ● ON  🔘│    │
│  └─────────────────────┘    │
│                             │
├─────────────────────────────┤
│ 🏠  📱  ⏰  📊  👤         │ ← Bottom Nav
└─────────────────────────────┘
```

### UI Elements

#### AppBar
- **Height**: 100px
- **Title**: 
  - Line 1: "Good Morning" - size 14, normal weight
  - Line 2: "Tra" - size 18, bold
- **Actions**: 
  - Notification icon (badge khi có thông báo mới)
  - Settings icon

#### Environment Card
- **Size**: Full width, height tự động
- **Background**: Primary gradient
- **Shadow**: Elevation 8, primary color 30% opacity
- **Border radius**: 16px
- **Content**:
  - Room name: "Living Room" - white 70%, size 14
  - Temperature: Icon + "24°C" - size 32, white, bold
  - Humidity: Icon + "65%" - size 14, white
  - Air quality: Icon + "Good" - size 14, white
  - Weather icon: 48px, bo góc container nền trắng 20% opacity

#### Quick Actions
- **Layout**: Row với 4 buttons, spaced evenly
- **Button**: 
  - Container 60x60, shadow, bo góc 12px
  - Icon: size 28, primary color
  - Label: Below icon, size 12, 2 lines max
- **Actions**: All Lights, Schedules, Analytics, Add Device

#### Rooms Section
- **Header**: "Rooms" title + "See All" button
- **Cards**: Horizontal scrollable list
  - Size: 140x100
  - Icon container: 40x40, primary 10% background
  - Badge: Active devices count, success color
  - Room name: size 16, medium weight
  - Device count: size 12, secondary color

#### Devices Section
- **Header**: "Devices" title + "See All" button
- **Cards**: Vertical list
  - Height: 80-100px per card
  - Device icon: 60x60, gradient nếu ON
  - Name: size 16, bold
  - Room: size 12, secondary color
  - Status: Online/Offline indicator
  - Toggle switch: Right aligned

#### Bottom Navigation
- **Items**: Home, Devices, Schedule, Analytics, Profile
- **Icons**: Outlined khi inactive, filled khi active
- **Selected color**: Primary
- **Type**: Fixed

### Spacing
- Screen padding: 16px
- Section spacing: 24px
- Card spacing: 12px

---

## 5. Device Detail Screen

### Mô Tả
Màn hình chi tiết thiết bị với điều khiển đầy đủ.

### Wireframe
```
┌─────────────────────────────┐
│ ← Living Room Light  ✏️ 🗑️ │ ← AppBar
├─────────────────────────────┤
│                             │
│      ┌──────────┐           │
│      │   💡     │           │ ← Device Icon
│      └──────────┘           │   (Gradient nếu ON)
│    Living Room              │
│    ● Online                 │
│                             │
│  ┌─────────────────────┐    │
│  │ Power         [ON]  │    │ ← Power Control
│  │ Device is ON        │    │   (Card)
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ Brightness      75% │    │ ← Brightness Slider
│  │ [====●─────]        │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ Temperature    24°C │    │ ← Temperature Slider
│  │ [====●─────]        │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ Device Information  │    │ ← Info Card
│  │ ─────────────────── │    │
│  │ Device ID: ESP32-001│    │
│  │ Type: Smart Light   │    │
│  │ Location: Living Room│   │
│  │ Last Update: 2m ago │    │
│  │ Firmware: v1.2.3    │    │
│  └─────────────────────┘    │
│                             │
│  Quick Actions              │
│  ┌────┐ ┌────┐ ┌────┐      │
│  │ ⏰ │ │ 📜 │ │ ⚙️ │      │ ← Action Grid
│  │Sched│History│Setting│    │
│  └────┘ └────┘ └────┘      │
│                             │
│  ┌─────────────────────┐    │
│  │ Energy Usage        │    │ ← Chart Card
│  │ Today: 2.4 kWh      │    │
│  │ [Chart Placeholder] │    │
│  └─────────────────────┘    │
└─────────────────────────────┘
```

### UI Elements

#### Device Header
- **Icon Container**: 120x120, gradient/gray, circle, shadow
- **Icon**: 60px, white/gray based on status
- **Room name**: size 16, secondary color
- **Status**: Dot + "Online"/"Offline", success/error color

#### Power Control Card
- **Layout**: Row với title + switch
- **Title**: "Power" - size 16, bold
- **Status**: "Device is ON/OFF" - size 14, secondary
- **Switch**: Right aligned, primary color khi ON

#### Sliders (Brightness & Temperature)
- **Label Row**: Title + Value, space between
- **Value**: Primary color, bold
- **Slider**: 
  - Icons ở 2 đầu (low/high)
  - Track color: Primary
  - Thumb: Circle, primary
  - Disabled khi device OFF

#### Device Info Card
- **Title**: "Device Information" - size 16, bold
- **Info rows**: Label + Value, space between
  - Label: size 14, secondary
  - Value: size 14, bold
- **Divider**: Between rows

#### Quick Actions Grid
- **Layout**: 3 columns
- **Action Card**: 
  - Square, full width
  - Icon: 32px, primary
  - Label: size 12, center, 2 lines max
  - InkWell with ripple

#### Energy Usage Card
- **Title**: "Energy Usage" - size 16, bold
- **Today stat**: "Today: 2.4 kWh" - size 14
- **Chart**: Height 150px, gradient background
  - Placeholder hoặc FL Chart

### Actions
- **Edit**: Top right, navigate to edit form
- **Delete**: Top right, show confirm dialog
- **Back**: Top left arrow

---

## 6. Schedule Screen

### Mô Tả
Màn hình quản lý lịch trình tự động.

### Wireframe
```
┌─────────────────────────────┐
│ ← Schedules & Automation  ➕│ ← AppBar with Add
├─────────────────────────────┤
│                             │
│  ┌─────────────────────┐    │
│  │ ☀️ Morning Light    │    │ ← Schedule Card 1
│  │ Turn on living room │    │
│  │ lights              │    │
│  │ ⏰ 07:00 AM         │    │
│  │ 📅 Every day   [ON] │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ 🌙 Night Mode       │    │ ← Schedule Card 2
│  │ Turn off all lights │    │
│  │ ⏰ 11:00 PM         │    │
│  │ 📅 Mon-Fri     [ON] │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ ❄️ AC Schedule      │    │ ← Schedule Card 3
│  │ Set AC to 24°C      │    │
│  │ ⏰ 06:00 PM         │    │
│  │ 📅 Every day  [OFF] │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ 🛏️ Weekend Wake Up │    │ ← Schedule Card 4
│  │ Turn on bedroom     │    │
│  │ lights              │    │
│  │ ⏰ 09:00 AM         │    │
│  │ 📅 Sat, Sun    [ON] │    │
│  └─────────────────────┘    │
│                             │
└─────────────────────────────┘
        [➕]                    ← FAB
```

### UI Elements

#### Schedule Card
- **Leading**: Icon container
  - Size: 48x48
  - Background: Primary 10%
  - Icon: 24px, primary color
  - Border radius: 12px

- **Content**:
  - **Title**: size 16, bold
  - **Description**: size 14, secondary, 2 lines max
  - **Time**: Icon + time text, size 12, bold
  - **Days**: Icon + days text, size 12, secondary

- **Trailing**: Switch
  - Value: enabled/disabled
  - Color: Primary

- **Tap Action**: Navigate to edit

#### FAB (Floating Action Button)
- **Position**: Bottom right
- **Icon**: Add icon
- **Color**: Primary
- **Action**: Show add schedule dialog

#### Add/Edit Dialog
- **Title**: "Add Schedule" / "Edit Schedule"
- **Fields**:
  - Schedule name
  - Device selector
  - Action type (On/Off/Set Value)
  - Time picker
  - Days selector (Daily/Weekly/Once)
  - Repeat options
- **Actions**: Cancel + Save buttons

### Spacing
- List padding: 16px
- Card spacing: 12px
- Card padding: 16px

---

## 7. Analytics Screen

### Mô Tả
Màn hình phân tích dữ liệu năng lượng và thống kê.

### Wireframe
```
┌─────────────────────────────┐
│ ← Analytics & Statistics    │ ← AppBar
├─────────────────────────────┤
│                             │
│  ┌──┬──┬──┬──┐              │
│  │Day│Week│Month│Year│      │ ← Period Selector
│  └──┴──┴──┴──┘              │
│                             │
│  ┌──────────┐ ┌──────────┐  │
│  │⚡ Total  │ │💰 Total  │  │ ← Overview Cards
│  │  Energy  │ │   Cost   │  │
│  │ 125.4kWh │ │ $24.50   │  │
│  │  +12%    │ │  +8%     │  │
│  └──────────┘ └──────────┘  │
│                             │
│  ┌─────────────────────┐    │
│  │ Energy Consumption  │    │ ← Chart Card
│  │                     │    │
│  │ [Area Chart]        │    │
│  │                     │    │
│  │                     │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ Device Usage        │    │ ← Device Stats
│  │ ─────────────────── │    │
│  │ 💡 Living Light     │    │
│  │ 24.5 kWh [■■■■■──] │    │
│  │                     │    │
│  │ ❄️ Smart AC         │    │
│  │ 42.8 kWh [■■■■■■■■]│    │
│  │                     │    │
│  │ 🌀 Ceiling Fan      │    │
│  │ 12.3 kWh [■■─────] │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ Cost Analysis       │    │ ← Cost Card
│  │ ─────────────────── │    │
│  │ Avg Daily: $4.20    │    │
│  │ Est Monthly: $126   │    │
│  │ Last Month: $118.50 │    │
│  │ Savings: +$7.50     │    │
│  └─────────────────────┘    │
└─────────────────────────────┘
```

### UI Elements

#### Period Selector
- **Layout**: Row với 4 buttons
- **Style**: 
  - Selected: Primary background, white text
  - Unselected: Transparent, inherit text color
  - Height: 40px
  - Border radius: 12px

#### Overview Cards
- **Layout**: 2 columns, equal width
- **Content**:
  - Icon container: 32x32, color 10% background
  - Title: size 12, secondary
  - Value: size 20, bold
  - Unit: size 12, secondary
  - Change: Badge với +/- và %, success/error color

#### Energy Chart Card
- **Title**: "Energy Consumption" - size 16, bold
- **Chart**: 
  - Type: Area chart (FL Chart)
  - Height: 200px
  - Gradient: Primary color
  - X-axis: Time periods
  - Y-axis: kWh values

#### Device Usage List
- **Title**: "Device Usage" - size 16, bold
- **Items**:
  - Icon: 20px, primary
  - Name: size 16, left
  - Usage: size 16, bold, right
  - Progress bar: Height 8px, rounded, primary color

#### Cost Analysis Card
- **Title**: "Cost Analysis" - size 16, bold
- **Rows**: Label + Value pairs
  - Label: size 14, secondary, left
  - Value: size 14, bold, right
  - Divider between rows

### Spacing
- Screen padding: 16px
- Section spacing: 24px
- Card padding: 20px
- Item spacing: 12px

---

## 8. Notification Screen

### Mô Tả
Màn hình hiển thị thông báo và cảnh báo.

### Wireframe
```
┌─────────────────────────────┐
│ ← Notifications  Mark all   │ ← AppBar
├─────────────────────────────┤
│                             │
│  ┌─────────────────────┐    │
│  │ ⚠️  High Energy      ●│   │ ← Warning (Unread)
│  │     Usage            │    │
│  │ Your AC running 6hrs │    │
│  │ 📱 Smart AC          │    │
│  │ ⏰ 10 minutes ago    │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ ℹ️  Device Online    ●│   │ ← Info (Unread)
│  │                      │    │
│  │ Living room light is │    │
│  │ now online           │    │
│  │ 📱 Living Room Light │    │
│  │ ⏰ 1 hour ago        │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ ✓  Schedule Done     │    │ ← Success (Read)
│  │                      │    │
│  │ Morning Light sched  │    │
│  │ executed successfully│    │
│  │ ⏰ 2 hours ago       │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ ⚠️  Device Offline   │    │ ← Error (Read)
│  │                      │    │
│  │ Smart door lock not  │    │
│  │ responding           │    │
│  │ 📱 Smart Door Lock   │    │
│  │ ⏰ 3 hours ago       │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │ ℹ️  Motion Detected  │    │ ← Info (Read)
│  │                      │    │
│  │ Motion in living room│    │
│  │ 📱 Motion Sensor     │    │
│  │ ⏰ Yesterday         │    │
│  └─────────────────────┘    │
└─────────────────────────────┘
```

### UI Elements

#### Notification Card
- **Leading Icon Container**:
  - Size: 48x48, padding 12px
  - Border radius: 12px
  - Background: Type color 10%
  - Icons:
    - Warning: `warning_amber_rounded` - Orange
    - Error: `error_outline` - Red
    - Success: `check_circle_outline` - Green
    - Info: `info_outline` - Blue

- **Content**:
  - **Title**: size 16, bold if unread
  - **Message**: size 14, secondary, 2-3 lines max
  - **Device**: Icon + name, size 12, bold
  - **Time**: Icon + relative time, size 12, secondary

- **Trailing**:
  - Unread dot: 8px circle, primary color
  - Right chevron icon (optional)

- **Background**:
  - Unread: Primary 5% tint
  - Read: Normal card color

#### Actions
- **Mark all read**: Top right text button
- **Tap card**: Mark as read + navigate to detail

### Card States
1. **Warning** - Orange icon, important alerts
2. **Error** - Red icon, critical issues
3. **Success** - Green icon, confirmations
4. **Info** - Blue icon, general info

### Spacing
- List padding: 16px
- Card spacing: 12px
- Card padding: 16px

---

## 9. Profile Screen

### Mô Tả
Màn hình thông tin người dùng và cài đặt.

### Wireframe
```
┌─────────────────────────────┐
│ ← Profile                   │ ← AppBar
├─────────────────────────────┤
│                             │
│      ┌──────────┐           │
│      │    JD    │           │ ← Avatar
│      └──────────┘           │
│                             │
│      Tra               │ ← Name
│   Tra@email.com        │ ← Email
│                             │
│    12        │      8       │ ← Stats
│  Devices     │  Schedules   │
│                             │
│  Account                    │ ← Section
│  ┌─────────────────────┐    │
│  │ 👤 Edit Profile   › │    │
│  │ 🔒 Change Password › │    │
│  │ ✉️ Email Settings › │    │
│  └─────────────────────┘    │
│                             │
│  Preferences                │
│  ┌─────────────────────┐    │
│  │ 🌙 Dark Mode   [ON] │    │
│  │ 🔔 Notifications  › │    │
│  │ 🌐 Language English›│    │
│  └─────────────────────┘    │
│                             │
│  About                      │
│  ┌─────────────────────┐    │
│  │ ❓ Help & Support  ›│    │
│  │ 📄 Terms & Condition›│    │
│  │ 🔒 Privacy Policy  ›│    │
│  │ ℹ️ App Ver. 1.0.0  ›│    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │      LOGOUT         │    │ ← Logout Button
│  └─────────────────────┘    │
└─────────────────────────────┘
```

### UI Elements

#### User Header
- **Avatar**: 
  - Size: 100x100, circle
  - Background: Primary gradient
  - Text: Initials, size 36, white, bold
  - Shadow: Elevation 8

- **Name**: size 20, bold, center
- **Email**: size 16, secondary, center

- **Stats Row**:
  - 2 columns with divider
  - Value: size 20, bold, primary
  - Label: size 14, secondary

#### Menu Sections
- **Section Title**: 
  - Size: 16, bold
  - Padding: 8px left, 12px bottom

- **Menu Card**: 
  - Grouped list items
  - No spacing between items

- **Menu Item**:
  - Leading: Icon, 24px
  - Title: size 16, medium
  - Trailing: 
    - Switch (for toggle items)
    - Value text (for info items)
    - Chevron right (for navigation)
  - Height: 56px min
  - Tap: Ripple effect

#### Sections
1. **Account**:
   - Edit Profile
   - Change Password
   - Email Settings

2. **Preferences**:
   - Dark Mode (toggle)
   - Notifications
   - Language (shows current)

3. **About**:
   - Help & Support
   - Terms & Conditions
   - Privacy Policy
   - App Version (shows version)

#### Logout Button
- **Style**: 
  - Full width, height 50px
  - Background: Error color (Red)
  - Text: White, size 16, bold
  - Border radius: 12px

- **Action**: Show confirm dialog

### Spacing
- Screen padding: 24px
- Header spacing: 16-32px
- Section spacing: 24px
- Card items: No spacing (grouped)

---

## 10. Responsive Design

### Mobile (320px - 768px)
- Single column layout
- Full width cards
- Bottom navigation visible
- Compact spacing

### Tablet (768px - 1024px)
- 2 column grid cho rooms và devices
- Larger cards
- Side navigation option
- Increased padding

### Web Dashboard (1024px+)
- 3-4 column grid
- Side navigation permanent
- Multi-panel layout
- Data tables thay vì cards
- Advanced charts với interactions

---

## 11. Animations & Transitions

### Screen Transitions
- **Default**: Slide from right (300ms)
- **Modal**: Slide from bottom (250ms)
- **Fade**: 200ms cho dialogs

### Card Animations
- **Hover**: Scale 1.02, elevation increase
- **Tap**: Ripple effect, slight scale down
- **Loading**: Shimmer effect

### Device Toggle
- **Switch**: Smooth animation 300ms
- **Icon**: Rotate + fade 250ms
- **Background**: Gradient transition 300ms

### Chart Animations
- **Line**: Draw animation 800ms
- **Bar**: Height grow 600ms
- **Value**: Count up 500ms

---

## 12. Dark Mode Implementation

### Automatic Switching
- System theme detection
- Manual toggle in profile
- Persistent storage
- Smooth transition 200ms

### Color Adaptations
- All colors have dark variants
- Images: Tint adjustment
- Icons: Automatic color inversion
- Charts: Dark-friendly palettes

---

## 13. ESP32 Integration

### Connection Flow
```
App → WebSocket/MQTT → ESP32
     ← Status Updates ←
```

### Real-time Updates
- Device status via WebSocket
- Sensor data polling (5s interval)
- Connection status monitoring
- Offline queue for commands

### Device Control Protocol
```json
{
  "deviceId": "ESP32-001",
  "action": "toggle",
  "value": true,
  "timestamp": "2024-01-01T00:00:00Z"
}
```

---

## 14. API Endpoints (Mẫu)

### Authentication
- `POST /auth/register` - Đăng ký
- `POST /auth/login` - Đăng nhập
- `GET /auth/me` - Thông tin user

### Devices
- `GET /devices` - Danh sách thiết bị
- `GET /devices/:id` - Chi tiết thiết bị
- `POST /devices` - Thêm thiết bị
- `PATCH /devices/:id` - Cập nhật
- `DELETE /devices/:id` - Xóa
- `POST /devices/:id/toggle` - Bật/tắt

### Schedules
- `GET /schedules` - Danh sách lịch
- `POST /schedules` - Tạo lịch
- `PATCH /schedules/:id` - Sửa lịch
- `DELETE /schedules/:id` - Xóa

### Analytics
- `GET /analytics/energy` - Dữ liệu năng lượng
- `GET /analytics/usage` - Thống kê sử dụng

### Notifications
- `GET /notifications` - Danh sách
- `PATCH /notifications/:id/read` - Đánh dấu đã đọc

---

## 15. Kết Luận

Dự án Smart Home IoT đã được thiết kế hoàn chỉnh với:
- ✅ 9 màn hình chính
- ✅ Material Design 3
- ✅ Dark mode support
- ✅ Responsive layout
- ✅ Real-time updates
- ✅ ESP32 integration ready
- ✅ Rich animations
- ✅ Complete documentation

### Next Steps
1. Implement backend API
2. Setup ESP32 firmware
3. Add chart libraries
4. Implement real WebSocket/MQTT
5. Add unit tests
6. Performance optimization
7. Deploy to stores

---

**Tạo bởi**: Smart Home IoT Team  
**Ngày**: 2024  
**Phiên bản**: 1.0.0
