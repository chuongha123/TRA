require('dotenv').config();

const express = require('express');
const cors = require('cors');
const { ObjectId } = require('mongodb');
const { initDb, getDb } = require('./db');

const app = express();
const port = Number(process.env.PORT || 3000);
const esp32Token = process.env.ESP32_TOKEN || 'esp32-secret';

app.use(express.json({ limit: '256kb' }));

if ((process.env.ENABLE_CORS || 'true').toLowerCase() === 'true') {
  app.use(cors());
}

function parsePeriodToHours(period) {
  switch ((period || '24h').toLowerCase()) {
    case '6h':
      return 6;
    case '24h':
      return 24;
    case '7d':
      return 24 * 7;
    case '30d':
      return 24 * 30;
    default:
      return 24;
  }
}

function parseClientTime(value) {
  if (value == null) {
    return null;
  }

  if (typeof value === 'number' && Number.isFinite(value)) {
    const ms = value > 1000000000000 ? value : value * 1000;
    const parsed = new Date(ms);
    return Number.isNaN(parsed.getTime()) ? null : parsed;
  }

  if (typeof value === 'string') {
    const trimmed = value.trim();
    if (!trimmed) {
      return null;
    }

    const numeric = Number(trimmed);
    if (Number.isFinite(numeric)) {
      const ms = numeric > 1000000000000 ? numeric : numeric * 1000;
      const parsedNumeric = new Date(ms);
      if (!Number.isNaN(parsedNumeric.getTime())) {
        return parsedNumeric;
      }
    }

    const parsedString = new Date(trimmed);
    return Number.isNaN(parsedString.getTime()) ? null : parsedString;
  }

  return null;
}

app.get('/api/health', async (req, res) => {
  try {
    const db = getDb();
    await db.db.command({ ping: 1 });
    res.json({ ok: true, message: 'Server and database are ready' });
  } catch (error) {
    res.status(500).json({ ok: false, error: String(error.message || error) });
  }
});

app.post('/api/sensors/ingest', async (req, res) => {
  try {
    const token = req.header('x-esp32-token');
    if (token !== esp32Token) {
      return res.status(401).json({ ok: false, error: 'Invalid ESP32 token' });
    }

    const {
      deviceId,
      soil_raw,
      soil_moisture,
      humidity,
      temperature,
      pressure,
      pumpOn,
      water_raw,
    } = req.body || {};

    if (!deviceId) {
      return res.status(400).json({ ok: false, error: 'deviceId is required' });
    }

    const db = getDb();
    await db.sensorReadings.insertOne({
      device_id: deviceId,
      soil_raw: soil_raw ?? null,
      soil_moisture: soil_moisture ?? null,
      humidity: humidity ?? null,
      temperature: temperature ?? null,
      pressure: pressure ?? null,
      pump_on: !!pumpOn,
      water_raw: water_raw ?? null,
      created_at: new Date(),
    });

    return res.status(201).json({ ok: true });
  } catch (error) {
    return res.status(500).json({ ok: false, error: String(error.message || error) });
  }
});

app.get('/api/sensors/latest', async (req, res) => {
  try {
    const deviceId = String(req.query.deviceId || 'esp32_garden_01');
    const db = getDb();

    const r = await db.sensorReadings.findOne(
      { device_id: deviceId },
      {
        sort: { created_at: -1, _id: -1 },
      }
    );

    if (!r) {
      return res.json({
        deviceId,
        soil_moisture: 0,
        humidity: 0,
        temperature: 0,
        pressure: 0,
        pumpOn: false,
        timestamp: null,
      });
    }

    return res.json({
      id: String(r._id),
      deviceId: r.device_id,
      soil_raw: r.soil_raw,
      soil_moisture: Number(r.soil_moisture ?? 0),
      humidity: Number(r.humidity ?? 0),
      temperature: Number(r.temperature ?? 0),
      pressure: Number(r.pressure ?? 0),
      pumpOn: !!r.pump_on,
      water_raw: r.water_raw != null ? Number(r.water_raw) : null,
      timestamp: r.created_at,
    });
  } catch (error) {
    return res.status(500).json({ ok: false, error: String(error.message || error) });
  }
});

app.get('/api/sensors/history', async (req, res) => {
  try {
    const type = String(req.query.type || 'soil_moisture');
    const period = String(req.query.period || '24h');
    const deviceId = String(req.query.deviceId || 'esp32_garden_01');

    const allowedTypes = new Set(['soil_moisture', 'humidity', 'temperature', 'pressure', 'water_raw']);
    if (!allowedTypes.has(type)) {
      return res.status(400).json({ ok: false, error: 'Invalid type' });
    }

    const hours = parsePeriodToHours(period);
    const fromTime = new Date(Date.now() - hours * 60 * 60 * 1000);
    const db = getDb();

    const rows = await db.sensorReadings
      .find(
        {
          device_id: deviceId,
          created_at: { $gte: fromTime },
          [type]: { $ne: null },
        },
        {
          projection: {
            [type]: 1,
            created_at: 1,
          },
        }
      )
      .sort({ created_at: 1, _id: 1 })
      .toArray();

    return res.json(
      rows.map((r) => ({
        time: r.created_at,
        value: Number(r[type]),
      }))
    );
  } catch (error) {
    return res.status(500).json({ ok: false, error: String(error.message || error) });
  }
});

app.post('/api/pump/toggle', async (req, res) => {
  try {
    const { deviceId = 'esp32_garden_01', isOn, triggeredBy = 'manual' } = req.body || {};

    if (typeof isOn !== 'boolean') {
      return res.status(400).json({ ok: false, error: 'isOn must be boolean' });
    }

    const db = getDb();
    await db.pumpEvents.insertOne({
      device_id: deviceId,
      is_on: !!isOn,
      triggered_by: triggeredBy,
      source: 'app',
      created_at: new Date(),
    });

    return res.json({ ok: true, deviceId, isOn });
  } catch (error) {
    return res.status(500).json({ ok: false, error: String(error.message || error) });
  }
});

app.get('/api/pump/latest', async (req, res) => {
  try {
    const deviceId = String(req.query.deviceId || 'esp32_garden_01');
    const db = getDb();

    const e = await db.pumpEvents.findOne(
      { device_id: deviceId },
      {
        sort: { created_at: -1, _id: -1 },
      }
    );

    if (!e) {
      return res.json({ deviceId, isOn: false, triggeredBy: null, source: null, timestamp: null });
    }

    return res.json({
      deviceId,
      isOn: !!e.is_on,
      triggeredBy: e.triggered_by,
      source: e.source,
      timestamp: e.created_at,
    });
  } catch (error) {
    return res.status(500).json({ ok: false, error: String(error.message || error) });
  }
});

// Nhan session tuoi hoan chinh tu ESP32 hoac app
app.post('/api/pump/session', async (req, res) => {
  try {
    const token = req.header('x-esp32-token');
    const source = token === esp32Token ? 'esp32' : 'app';

    const {
      deviceId = 'esp32_garden_01',
      durationSeconds,
      triggeredBy = 'auto',
      startTime,
      endTime,
    } = req.body || {};

    if (!Number.isFinite(Number(durationSeconds)) || Number(durationSeconds) <= 0) {
      return res.status(400).json({ ok: false, error: 'durationSeconds must be a positive number' });
    }

    const dur = Math.round(Number(durationSeconds));
    const parsedEndTime = parseClientTime(endTime) || new Date();
    const parsedStartTime = parseClientTime(startTime) || new Date(parsedEndTime.getTime() - dur * 1000);
    const db = getDb();

    await db.irrigationSessions.insertOne({
      device_id: deviceId,
      start_time: parsedStartTime,
      end_time: parsedEndTime,
      duration_seconds: dur,
      triggered_by: triggeredBy,
      source,
    });

    return res.status(201).json({ ok: true });
  } catch (error) {
    return res.status(500).json({ ok: false, error: String(error.message || error) });
  }
});

// Lay lich su cac lan tuoi cho app
app.get('/api/pump/sessions', async (req, res) => {
  try {
    const deviceId = String(req.query.deviceId || 'esp32_garden_01');
    const rawLimit = Number(req.query.limit || 50);
    const limit = Number.isFinite(rawLimit)
      ? Math.max(1, Math.min(Math.trunc(rawLimit), 200))
      : 50;
    const db = getDb();

    const rows = await db.irrigationSessions
      .find(
        { device_id: deviceId },
        {
          projection: {
            device_id: 1,
            start_time: 1,
            end_time: 1,
            duration_seconds: 1,
            triggered_by: 1,
            source: 1,
          },
        }
      )
      .sort({ end_time: -1, _id: -1 })
      .limit(limit)
      .toArray();

    return res.json(
      rows.map((r) => ({
        id: String(r._id),
        deviceId: r.device_id,
        startTime: r.start_time,
        endTime: r.end_time,
        durationSeconds: r.duration_seconds,
        triggeredBy: r.triggered_by,
        source: r.source,
      }))
    );
  } catch (error) {
    return res.status(500).json({ ok: false, error: String(error.message || error) });
  }
});

// Xoa 1 session tuoi
app.delete('/api/pump/sessions/:id', async (req, res) => {
  try {
    const { id } = req.params;
    if (!ObjectId.isValid(id)) {
      return res.status(400).json({ ok: false, error: 'Invalid session id' });
    }

    const db = getDb();
    const result = await db.irrigationSessions.deleteOne({ _id: new ObjectId(id) });

    if (!result.deletedCount) {
      return res.status(404).json({ ok: false, error: 'Session not found' });
    }

    return res.json({ ok: true });
  } catch (error) {
    return res.status(500).json({ ok: false, error: String(error.message || error) });
  }
});

// Xoa toan bo session tuoi cua 1 thiet bi
app.post('/api/pump/sessions/delete-all', async (req, res) => {
  try {
    const { deviceId = 'esp32_garden_01' } = req.body || {};
    const db = getDb();
    const result = await db.irrigationSessions.deleteMany({ device_id: deviceId });

    return res.json({ ok: true, deletedCount: result.deletedCount });
  } catch (error) {
    return res.status(500).json({ ok: false, error: String(error.message || error) });
  }
});

// Luu canh bao vao DB
app.post('/api/alerts', async (req, res) => {
  try {
    const {
      deviceId = 'esp32_garden_01',
      type,
      title,
      message,
      zone,
      value = null,
      threshold = null,
      rainSum = null,
      forecastDateKey = null,
      sourceKey = null,
      isRead = false,
      timestamp,
    } = req.body || {};

    if (!type || !title || !message) {
      return res.status(400).json({ ok: false, error: 'type, title, message are required' });
    }

    const parsedTimestamp = parseClientTime(timestamp) || new Date();
    const db = getDb();

    const doc = {
      device_id: deviceId,
      type,
      title,
      message,
      zone: zone || 'Vườn rau A',
      value,
      threshold,
      rain_sum: rainSum,
      forecast_date_key: forecastDateKey,
      source_key: sourceKey,
      is_read: !!isRead,
      timestamp: parsedTimestamp,
      created_at: new Date(),
      read_at: isRead ? new Date() : null,
    };

    const result = await db.alerts.insertOne(doc);

    return res.status(201).json({
      ok: true,
      id: String(result.insertedId),
      deviceId: doc.device_id,
      type: doc.type,
      title: doc.title,
      message: doc.message,
      zone: doc.zone,
      value: doc.value,
      threshold: doc.threshold,
      rainSum: doc.rain_sum,
      forecastDateKey: doc.forecast_date_key,
      sourceKey: doc.source_key,
      isRead: doc.is_read,
      timestamp: doc.timestamp,
    });
  } catch (error) {
    return res.status(500).json({ ok: false, error: String(error.message || error) });
  }
});

// Lay lich su canh bao
app.get('/api/alerts', async (req, res) => {
  try {
    const deviceId = String(req.query.deviceId || 'esp32_garden_01');
    const rawLimit = Number(req.query.limit || 100);
    const limit = Number.isFinite(rawLimit)
      ? Math.max(1, Math.min(Math.trunc(rawLimit), 500))
      : 100;
    const db = getDb();

    const rows = await db.alerts
      .find(
        { device_id: deviceId },
        {
          projection: {
            device_id: 1,
            type: 1,
            title: 1,
            message: 1,
            zone: 1,
            value: 1,
            threshold: 1,
            rain_sum: 1,
            forecast_date_key: 1,
            source_key: 1,
            is_read: 1,
            timestamp: 1,
          },
        }
      )
      .sort({ timestamp: -1, _id: -1 })
      .limit(limit)
      .toArray();

    return res.json(
      rows.map((r) => ({
        id: String(r._id),
        deviceId: r.device_id,
        type: r.type,
        title: r.title,
        message: r.message,
        zone: r.zone,
        value: r.value,
        threshold: r.threshold,
        rainSum: r.rain_sum,
        forecastDateKey: r.forecast_date_key,
        sourceKey: r.source_key,
        isRead: !!r.is_read,
        timestamp: r.timestamp,
      }))
    );
  } catch (error) {
    return res.status(500).json({ ok: false, error: String(error.message || error) });
  }
});

// Danh dau 1 canh bao da doc
app.patch('/api/alerts/:id/read', async (req, res) => {
  try {
    const { id } = req.params;
    if (!ObjectId.isValid(id)) {
      return res.status(400).json({ ok: false, error: 'Invalid alert id' });
    }

    const db = getDb();
    const result = await db.alerts.updateOne(
      { _id: new ObjectId(id) },
      { $set: { is_read: true, read_at: new Date() } }
    );

    if (!result.matchedCount) {
      return res.status(404).json({ ok: false, error: 'Alert not found' });
    }

    return res.json({ ok: true });
  } catch (error) {
    return res.status(500).json({ ok: false, error: String(error.message || error) });
  }
});

// Danh dau tat ca canh bao da doc
app.post('/api/alerts/read-all', async (req, res) => {
  try {
    const { deviceId = 'esp32_garden_01' } = req.body || {};
    const db = getDb();
    const result = await db.alerts.updateMany(
      { device_id: deviceId, is_read: { $ne: true } },
      { $set: { is_read: true, read_at: new Date() } }
    );

    return res.json({ ok: true, modifiedCount: result.modifiedCount });
  } catch (error) {
    return res.status(500).json({ ok: false, error: String(error.message || error) });
  }
});

// Xoa 1 canh bao
app.delete('/api/alerts/:id', async (req, res) => {
  try {
    const { id } = req.params;
    if (!ObjectId.isValid(id)) {
      return res.status(400).json({ ok: false, error: 'Invalid alert id' });
    }

    const db = getDb();
    const result = await db.alerts.deleteOne({ _id: new ObjectId(id) });

    if (!result.deletedCount) {
      return res.status(404).json({ ok: false, error: 'Alert not found' });
    }

    return res.json({ ok: true });
  } catch (error) {
    return res.status(500).json({ ok: false, error: String(error.message || error) });
  }
});

// Xoa tat ca canh bao theo thiet bi
app.post('/api/alerts/delete-all', async (req, res) => {
  try {
    const { deviceId = 'esp32_garden_01' } = req.body || {};
    const db = getDb();
    const result = await db.alerts.deleteMany({ device_id: deviceId });

    return res.json({ ok: true, deletedCount: result.deletedCount });
  } catch (error) {
    return res.status(500).json({ ok: false, error: String(error.message || error) });
  }
});

// User Login API
app.post('/api/login', async (req, res) => {
  try {
    const { username, password } = req.body || {};
    console.log(`[HTTP POST /api/login] Attempt with username: "${username}"`);
    
    if (!username || !password) {
      console.log(' -> Rejected: Missing username or password');
      return res.status(400).json({ ok: false, error: 'Username and password are required' });
    }

    const db = getDb();
    const user = await db.db.collection('users').findOne({ 
      username: username.trim(),
      password: password
    });

    if (user) {
      console.log(' -> Successful login!');
      return res.json({ ok: true, message: 'Login successful' });
    } else {
      console.log(' -> Failed login: Incorrect username or password');
      return res.status(401).json({ ok: false, error: 'Tài khoản hoặc mật khẩu không chính xác' });
    }
  } catch (error) {
    console.error(' -> Error during login:', error);
    return res.status(500).json({ ok: false, error: String(error.message || error) });
  }
});

// GET system settings
app.get('/api/settings', async (req, res) => {
  try {
    const db = getDb();
    let s = await db.db.collection('settings').findOne({ key: 'system_config' });
    if (!s) {
      s = {
        key: 'system_config',
        systemMode: 'auto',
        soilMoistureThreshold: 30.0,
        waterLevelThreshold: 100.0,
      };
      await db.db.collection('settings').insertOne(s);
    }
    return res.json({
      systemMode: s.systemMode,
      soilMoistureThreshold: String(s.soilMoistureThreshold),
      waterLevelThreshold: String(s.waterLevelThreshold),
    });
  } catch (error) {
    return res.status(500).json({ ok: false, error: String(error.message || error) });
  }
});

// POST system settings
app.post('/api/settings', async (req, res) => {
  try {
    const { systemMode, soilMoistureThreshold, waterLevelThreshold } = req.body || {};
    const db = getDb();

    const update = {};
    if (systemMode !== undefined) update.systemMode = systemMode;
    if (soilMoistureThreshold !== undefined) update.soilMoistureThreshold = Number(soilMoistureThreshold);
    if (waterLevelThreshold !== undefined) update.waterLevelThreshold = Number(waterLevelThreshold);

    await db.db.collection('settings').updateOne(
      { key: 'system_config' },
      { $set: update },
      { upsert: true }
    );

    return res.json({ ok: true });
  } catch (error) {
    return res.status(500).json({ ok: false, error: String(error.message || error) });
  }
});

async function seedUser() {
  try {
    const db = getDb();
    const user = await db.db.collection('users').findOne({ username: 'thanhtra' });
    if (!user) {
      await db.db.collection('users').insertOne({
        username: 'thanhtra',
        password: 'nongnghiepthongminh@',
        created_at: new Date()
      });
      console.log('Default user seeded: thanhtra');
    }
  } catch (error) {
    console.error('Error seeding user:', error);
  }
}

async function start() {
  try {
    await initDb();
    await seedUser();
    app.listen(port, () => {
      console.log(`Local API listening on http://localhost:${port}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

start();
