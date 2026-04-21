# SmartFarm Local Server

Server local nhan du lieu tu ESP32, luu vao MongoDB (database co san tren may), va tra du lieu cho app Flutter.

## 1) Cai dat

```bash
cd server
npm install
```

## 2) Cau hinh

Tao file `.env` tu `.env.example`:

```bash
copy .env.example .env
```

Cap nhat thong tin MongoDB trong `.env`:

- `MONGODB_URI` (vi du: `mongodb://127.0.0.1:27017`)
- `MONGODB_DB_NAME` (vi du: `smartfarm`)
- `ESP32_TOKEN` phai giong token trong firmware ESP32

## 3) Chay server

```bash
npm run dev
```

Kiem tra:

- `GET http://localhost:3000/api/health`

## 4) API chinh

- `POST /api/sensors/ingest` (ESP32 gui du lieu)
- `GET /api/sensors/latest?deviceId=esp32_garden_01`
- `GET /api/sensors/history?type=soil_moisture&period=24h&deviceId=esp32_garden_01`
- `POST /api/pump/toggle`
- `GET /api/pump/latest?deviceId=esp32_garden_01`
- `POST /api/pump/session`
- `GET /api/pump/sessions?deviceId=esp32_garden_01&limit=50`

## 5) Payload ingest mau

```json
{
  "deviceId": "esp32_garden_01",
  "soil_raw": 1320,
  "soil_moisture": 24.5,
  "humidity": 73.2,
  "temperature": 29.1,
  "pressure": 1008.3,
  "pumpOn": false
}
```

Header bat buoc:

- `Content-Type: application/json`
- `X-ESP32-Token: <ESP32_TOKEN>`
