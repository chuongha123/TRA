const { MongoClient } = require('mongodb');

let client;
let database;

async function initDb() {
  if (!client) {
    const uri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017';
    const dbName = process.env.MONGODB_DB_NAME || 'smartfarm';

    client = new MongoClient(uri);
    await client.connect();
    database = client.db(dbName);
  }

  const sensorReadings = database.collection('sensor_readings');
  const pumpEvents = database.collection('pump_events');
  const irrigationSessions = database.collection('irrigation_sessions');
  const alerts = database.collection('alerts');

  await Promise.all([
    sensorReadings.createIndex({ created_at: -1 }),
    sensorReadings.createIndex({ device_id: 1, created_at: -1 }),
    pumpEvents.createIndex({ device_id: 1, created_at: -1 }),
    irrigationSessions.createIndex({ device_id: 1, end_time: -1 }),
    alerts.createIndex({ device_id: 1, timestamp: -1 }),
    alerts.createIndex({ is_read: 1, device_id: 1, timestamp: -1 }),
  ]);

  return getDb();
}

function getDb() {
  if (!database) {
    throw new Error('Database has not been initialized.');
  }

  return {
    db: database,
    sensorReadings: database.collection('sensor_readings'),
    pumpEvents: database.collection('pump_events'),
    irrigationSessions: database.collection('irrigation_sessions'),
    alerts: database.collection('alerts'),
  };
}

module.exports = {
  initDb,
  getDb,
};
