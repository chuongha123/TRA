package com.example.Tra

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.Calendar
import kotlin.concurrent.thread

object AlarmScheduler {
  private const val PREFS_NAME = "irrigation_alarm_prefs"
  private const val KEY_API_BASE_URL = "api_base_url"
  private const val KEY_DEVICE_ID = "device_id"
  private const val KEY_SCHEDULES_JSON = "schedules_json"
  private const val KEY_REGISTERED_IDS = "registered_schedule_ids"

  const val ACTION_SCHEDULE_ON = "com.example.Tra.ACTION_SCHEDULE_ON"
  const val ACTION_SCHEDULE_OFF = "com.example.Tra.ACTION_SCHEDULE_OFF"
  const val EXTRA_SCHEDULE_ID = "scheduleId"

  private data class ScheduleEntry(
    val id: String,
    val hour: Int,
    val minute: Int,
    val durationMinutes: Int,
    val days: List<Boolean>,
    val isEnabled: Boolean,
  )

  fun initialize(context: Context, apiBaseUrl: String, deviceId: String) {
    saveConfig(context, apiBaseUrl, deviceId)
  }

  fun syncSchedules(
    context: Context,
    apiBaseUrl: String,
    deviceId: String,
    schedules: List<Map<String, Any?>>,
  ) {
    saveConfig(context, apiBaseUrl, deviceId)
    saveSchedules(context, schedules)
    rescheduleAll(context)
  }

  fun onBootCompleted(context: Context) {
    rescheduleAll(context)
  }

  fun onOnAlarmTriggered(context: Context, scheduleId: String) {
    sendPumpToggle(context, isOn = true)

    val matched = loadSchedules(context).firstOrNull { it.id == scheduleId }
    val durationMinutes = matched?.durationMinutes?.coerceIn(1, 240) ?: 1
    schedulePumpOff(context, scheduleId, durationMinutes)

    if (matched != null && matched.isEnabled) {
      scheduleNextOnAlarm(context, matched, System.currentTimeMillis())
    }
  }

  fun onOffAlarmTriggered(context: Context) {
    sendPumpToggle(context, isOn = false)
  }

  private fun saveConfig(context: Context, apiBaseUrl: String, deviceId: String) {
    context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
      .edit()
      .putString(KEY_API_BASE_URL, apiBaseUrl)
      .putString(KEY_DEVICE_ID, deviceId)
      .apply()
  }

  private fun saveSchedules(context: Context, schedules: List<Map<String, Any?>>) {
    val jsonArray = JSONArray()
    schedules.forEach { schedule ->
      jsonArray.put(mapToJsonObject(schedule))
    }

    context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
      .edit()
      .putString(KEY_SCHEDULES_JSON, jsonArray.toString())
      .apply()
  }

  private fun loadSchedules(context: Context): List<ScheduleEntry> {
    val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    val raw = prefs.getString(KEY_SCHEDULES_JSON, null) ?: return emptyList()

    return try {
      val array = JSONArray(raw)
      buildList {
        for (i in 0 until array.length()) {
          val obj = array.optJSONObject(i) ?: continue
          val id = obj.optString("id", "")
          if (id.isBlank()) continue

          val daysRaw = obj.optJSONArray("days")
          val days = List(7) { index ->
            when {
              daysRaw == null || index >= daysRaw.length() -> false
              else -> daysRaw.optBoolean(index, false)
            }
          }

          add(
            ScheduleEntry(
              id = id,
              hour = obj.optInt("hour", 0).coerceIn(0, 23),
              minute = obj.optInt("minute", 0).coerceIn(0, 59),
              durationMinutes = obj.optInt("durationMinutes", 1),
              days = days,
              isEnabled = obj.optBoolean("isEnabled", false),
            ),
          )
        }
      }
    } catch (_: Throwable) {
      emptyList()
    }
  }

  private fun rescheduleAll(context: Context) {
    cancelAll(context)

    val schedules = loadSchedules(context)
      .filter { it.isEnabled }
      .filter { it.days.any { day -> day } }

    val ids = mutableSetOf<String>()
    schedules.forEach { schedule ->
      if (scheduleNextOnAlarm(context, schedule, System.currentTimeMillis())) {
        ids.add(schedule.id)
      }
    }

    context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
      .edit()
      .putStringSet(KEY_REGISTERED_IDS, ids)
      .apply()
  }

  private fun cancelAll(context: Context) {
    val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    val ids = prefs.getStringSet(KEY_REGISTERED_IDS, emptySet()) ?: emptySet()

    ids.forEach { id ->
      cancelPendingIntent(context, ACTION_SCHEDULE_ON, id)
      cancelPendingIntent(context, ACTION_SCHEDULE_OFF, id)
    }

    prefs.edit().remove(KEY_REGISTERED_IDS).apply()
  }

  private fun scheduleNextOnAlarm(
    context: Context,
    schedule: ScheduleEntry,
    fromEpochMs: Long,
  ): Boolean {
    val nextEpochMs = computeNextOccurrenceEpochMs(schedule, fromEpochMs) ?: return false
    val pendingIntent = buildPendingIntent(context, ACTION_SCHEDULE_ON, schedule.id, update = true)
    scheduleExactAlarm(context, nextEpochMs, pendingIntent)
    return true
  }

  private fun schedulePumpOff(context: Context, scheduleId: String, durationMinutes: Int) {
    val nextEpochMs = System.currentTimeMillis() + durationMinutes.coerceIn(1, 240) * 60_000L
    val pendingIntent = buildPendingIntent(context, ACTION_SCHEDULE_OFF, scheduleId, update = true)
    scheduleExactAlarm(context, nextEpochMs, pendingIntent)
  }

  private fun scheduleExactAlarm(
    context: Context,
    triggerAtMillis: Long,
    pendingIntent: PendingIntent,
  ) {
    val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    when {
      Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && !alarmManager.canScheduleExactAlarms() -> {
        alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
      }
      Build.VERSION.SDK_INT >= Build.VERSION_CODES.M -> {
        alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
      }
      else -> {
        alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAtMillis, pendingIntent)
      }
    }
  }

  private fun cancelPendingIntent(context: Context, action: String, scheduleId: String) {
    val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    val pendingIntent = buildPendingIntent(context, action, scheduleId, update = false)
    alarmManager.cancel(pendingIntent)
    pendingIntent.cancel()
  }

  private fun buildPendingIntent(
    context: Context,
    action: String,
    scheduleId: String,
    update: Boolean,
  ): PendingIntent {
    val intent = Intent(context, IrrigationAlarmReceiver::class.java).apply {
      this.action = action
      putExtra(EXTRA_SCHEDULE_ID, scheduleId)
    }

    val requestCode = ("$action#$scheduleId").hashCode()
    val flags = if (update) {
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    } else {
      PendingIntent.FLAG_NO_CREATE or PendingIntent.FLAG_IMMUTABLE
    }

    return PendingIntent.getBroadcast(context, requestCode, intent, flags)
      ?: PendingIntent.getBroadcast(
        context,
        requestCode,
        intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
      )
  }

  private fun computeNextOccurrenceEpochMs(
    schedule: ScheduleEntry,
    fromEpochMs: Long,
  ): Long? {
    val nowCalendar = Calendar.getInstance().apply {
      timeInMillis = fromEpochMs
      set(Calendar.SECOND, 0)
      set(Calendar.MILLISECOND, 0)
    }

    for (offset in 0..7) {
      val candidate = Calendar.getInstance().apply {
        timeInMillis = nowCalendar.timeInMillis
        add(Calendar.DAY_OF_YEAR, offset)
        set(Calendar.HOUR_OF_DAY, schedule.hour)
        set(Calendar.MINUTE, schedule.minute)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
      }

      val weekdayIndex = (candidate.get(Calendar.DAY_OF_WEEK) + 5) % 7
      if (!schedule.days.getOrElse(weekdayIndex) { false }) {
        continue
      }

      if (candidate.timeInMillis > fromEpochMs + 5_000L) {
        return candidate.timeInMillis
      }
    }

    return null
  }

  private fun sendPumpToggle(context: Context, isOn: Boolean) {
    val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    val apiBaseUrl = prefs.getString(KEY_API_BASE_URL, null) ?: return
    val deviceId = prefs.getString(KEY_DEVICE_ID, null) ?: return

    thread(start = true) {
      var connection: HttpURLConnection? = null
      try {
        val url = URL("$apiBaseUrl/pump/toggle")
        connection = (url.openConnection() as HttpURLConnection).apply {
          requestMethod = "POST"
          connectTimeout = 8000
          readTimeout = 8000
          doOutput = true
          setRequestProperty("Content-Type", "application/json")
        }

        val body = JSONObject().apply {
          put("deviceId", deviceId)
          put("isOn", isOn)
          put("triggeredBy", "schedule")
        }

        connection.outputStream.use { output ->
          output.write(body.toString().toByteArray(Charsets.UTF_8))
        }

        connection.inputStream.close()
      } catch (_: Throwable) {
        // Keep receiver resilient; next scheduled run will retry naturally.
      } finally {
        connection?.disconnect()
      }
    }
  }

  private fun mapToJsonObject(map: Map<String, Any?>): JSONObject {
    val obj = JSONObject()
    map.forEach { (key, value) ->
      obj.put(key, toJsonValue(value))
    }
    return obj
  }

  private fun toJsonValue(value: Any?): Any? {
    return when (value) {
      null -> JSONObject.NULL
      is Map<*, *> -> {
        val nested = JSONObject()
        value.forEach { (k, v) ->
          if (k != null) nested.put(k.toString(), toJsonValue(v))
        }
        nested
      }
      is List<*> -> {
        val arr = JSONArray()
        value.forEach { arr.put(toJsonValue(it)) }
        arr
      }
      else -> value
    }
  }
}
