package com.example.Tra

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class IrrigationAlarmReceiver : BroadcastReceiver() {
  override fun onReceive(context: Context, intent: Intent?) {
    val action = intent?.action ?: return
    val scheduleId = intent.getStringExtra(AlarmScheduler.EXTRA_SCHEDULE_ID) ?: return

    when (action) {
      AlarmScheduler.ACTION_SCHEDULE_ON -> AlarmScheduler.onOnAlarmTriggered(context, scheduleId)
      AlarmScheduler.ACTION_SCHEDULE_OFF -> AlarmScheduler.onOffAlarmTriggered(context)
    }
  }
}
