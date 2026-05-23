package com.plansapp

import android.content.Context
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray

class MainActivity : FlutterActivity() {
    private var latestIntent: Intent? = null
    private val DEEPLINK_CHANNEL = "plans/widget/deeplink"
    private var deeplinkChannel: MethodChannel? = null

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
                    val ids = mutableListOf<String>()
                    val existing = prefs.getString("pending_toggle_ids", null)
                    if (existing != null && existing != "[]") {
                        val arr = JSONArray(existing)
                        for (i in 0 until arr.length()) {
                            ids.add(arr.getString(i))
                        }
                        prefs.edit().remove("pending_toggle_ids").apply()
                    }
                    result.success(ids)
                }
                else -> result.notImplemented()
            }
        }
    }
}
