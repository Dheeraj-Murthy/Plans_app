package com.plansapp

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var latestIntent: Intent? = null
    private val DEEPLINK_CHANNEL = "plans/widget/deeplink"
    private var deeplinkChannel: MethodChannel? = null
    private var pendingDeeplink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        latestIntent = intent
        handleWidgetLaunch(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        latestIntent = intent
        handleWidgetLaunch(intent)
    }

    private fun handleWidgetLaunch(intent: Intent?) {
        val uri = intent?.data ?: return
        if (deeplinkChannel != null) {
            processDeeplink(uri)
        } else {
            pendingDeeplink = uri.toString()
        }
    }

    private fun processDeeplink(uri: Uri) {
        when (uri.path) {
            "/addTask" -> deeplinkChannel?.invokeMethod("openAddTask", null)
            else -> {
                val taskId = uri.lastPathSegment
                if (taskId != null) {
                    deeplinkChannel?.invokeMethod("openTask", taskId)
                }
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        deeplinkChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DEEPLINK_CHANNEL)
        deeplinkChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialIntent" -> {
                    val i = latestIntent
                    val uri = i?.data
                    if (uri != null) {
                        val path = uri.path ?: ""
                        when (path) {
                            "/addTask" -> result.success(mapOf("action" to "add_task"))
                            else -> {
                                val taskId = uri.lastPathSegment ?: ""
                                result.success(mapOf("action" to "open_task", "task_id" to taskId))
                            }
                        }
                    } else {
                        result.success(mapOf("action" to ""))
                    }
                }
                else -> result.notImplemented()
            }
        }

        pendingDeeplink?.let {
            processDeeplink(Uri.parse(it))
            pendingDeeplink = null
        }
    }
}
