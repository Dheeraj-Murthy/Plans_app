package com.plansapp.widget

import android.appwidget.AppWidgetManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent

class WidgetInteractionReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return

        when (action) {
            "com.plansapp.action.REFRESH" -> {
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val cn = ComponentName(context, PlansAppWidgetProvider::class.java)
                val ids = appWidgetManager.getAppWidgetIds(cn)
                if (ids.isNotEmpty()) {
                    PlansAppWidgetProvider.handleRefresh(context, ids)
                }
            }
            "com.plansapp.action.TOGGLE" -> {
                val appWidgetId = intent.getIntExtra("appWidgetId", -1)
                val taskId = intent.getStringExtra("task_id") ?: return
                PlansAppWidgetProvider.handleToggle(context, appWidgetId, taskId)
            }
            "com.plansapp.action.SET_VIEW" -> {
                val appWidgetId = intent.getIntExtra("appWidgetId", -1)
                val view = intent.getStringExtra("view") ?: return
                PlansAppWidgetProvider.handleSetView(context, appWidgetId, view)
            }
        }
    }
}
