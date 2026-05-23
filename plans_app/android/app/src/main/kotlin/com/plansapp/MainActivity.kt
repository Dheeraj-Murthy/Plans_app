package com.plansapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var latestIntent: Intent? = null
    private val DEEPLINK_CHANNEL = "plans/widget/deeplink"
    private var deeplinkChannel: MethodChannel? = null
    private val widgetToggleReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            deeplinkChannel?.invokeMethod("taskToggled", null)
        }
    }

    override fun onResume() {
        super.onResume()
        ContextCompat.registerReceiver(
            this,
            widgetToggleReceiver,
            IntentFilter(TASK_TOGGLED_ACTION),
            ContextCompat.RECEIVER_NOT_EXPORTED,
        )
    }

    override fun onPause() {
        super.onPause()
        try { unregisterReceiver(widgetToggleReceiver) } catch (_: Exception) {}
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        latestIntent = intent
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        latestIntent = intent
        processWidgetIntent(intent)
    }

    private fun processWidgetIntent(intent: Intent) {
        val channel = deeplinkChannel ?: return
        val action = intent.getStringExtra("action")
        val taskId = intent.getStringExtra("task_id")
        if (action == "add_task") {
            channel.invokeMethod("openAddTask", null)
        }
        if (taskId != null) {
            channel.invokeMethod("openTask", taskId)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        deeplinkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEEPLINK_CHANNEL)
        deeplinkChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialIntent" -> {
                    val i = latestIntent
                    val action = i?.getStringExtra("action")
                    val taskId = i?.getStringExtra("task_id")
                    val view = i?.getStringExtra("current_view")
                    if (action == "add_task") {
                        result.success(mapOf("action" to "add_task"))
                    } else if (taskId != null) {
                        result.success(mapOf("action" to "open_task", "task_id" to taskId, "view" to (view ?: "")))
                    } else {
                        result.success(mapOf("action" to ""))
                    }
                }
                "checkPendingWidgetSync" -> {
                    val prefs = getSharedPreferences("HomeWidgetPreferences", Context.MODE_PRIVATE)
                    val pending = prefs.getBoolean("pending_widget_sync", false)
                    if (pending) {
                        prefs.edit().putBoolean("pending_widget_sync", false).apply()
                    }
                    result.success(pending)
                }
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        private const val TASK_TOGGLED_ACTION = "com.plansapp.action.TASK_TOGGLED"
    }
}
