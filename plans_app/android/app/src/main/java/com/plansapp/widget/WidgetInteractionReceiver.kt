package com.plansapp.widget

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class WidgetInteractionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        val appWidgetId = intent.getIntExtra("appWidgetId", -1)
        if (appWidgetId < 0) return

        when (action) {
            "com.plansapp.action.TOGGLE" -> {
                val taskId = intent.getStringExtra("task_id") ?: return
                PlansAppWidgetProvider.handleToggle(context, appWidgetId, taskId)
            }
            "com.plansapp.action.SET_VIEW" -> {
                val view = intent.getStringExtra("view") ?: return
                PlansAppWidgetProvider.handleSetView(context, appWidgetId, view)
            }
        }
    }
}
