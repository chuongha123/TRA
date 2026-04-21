package com.example.Tra

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "com.example.Tra/background_alarm"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"initialize" -> {
						val apiBaseUrl = call.argument<String>("apiBaseUrl")
						val deviceId = call.argument<String>("deviceId")
						if (apiBaseUrl.isNullOrBlank() || deviceId.isNullOrBlank()) {
							result.error("INVALID_ARGS", "apiBaseUrl and deviceId are required", null)
							return@setMethodCallHandler
						}

						AlarmScheduler.initialize(applicationContext, apiBaseUrl, deviceId)
						result.success(null)
					}

					"syncSchedules" -> {
						val apiBaseUrl = call.argument<String>("apiBaseUrl")
						val deviceId = call.argument<String>("deviceId")
						val schedules = call.argument<List<Map<String, Any?>>>("schedules") ?: emptyList()

						if (apiBaseUrl.isNullOrBlank() || deviceId.isNullOrBlank()) {
							result.error("INVALID_ARGS", "apiBaseUrl and deviceId are required", null)
							return@setMethodCallHandler
						}

						AlarmScheduler.syncSchedules(applicationContext, apiBaseUrl, deviceId, schedules)
						result.success(null)
					}

					else -> result.notImplemented()
				}
			}
	}
}
