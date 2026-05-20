package com.plansapp.widget

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.util.Log
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import com.plansapp.R
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

private const val PREFS_NAME = "HomeWidgetPreferences"
private const val TAG = "PlansWidget"

class PlansAppWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        for (widgetId in appWidgetIds) {
            val views = buildWidgetViews(context, widgetData, widgetId)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    companion object {
        private const val ACTION_TOGGLE = "com.plansapp.action.TOGGLE"
        private const val ACTION_SET_VIEW = "com.plansapp.action.SET_VIEW"
        private const val EXTRA_TASK_ID = "task_id"
        private const val EXTRA_VIEW = "view"
        private const val EXTRA_APP_WIDGET_ID = "appWidgetId"

        private const val VIEW_PICKER = "picker"
        private const val VIEW_INBOX = "inbox"
        private const val VIEW_TODAY = "today"
        private const val VIEW_COMPLETED = "completed"
        private const val VIEW_PROJECT_PREFIX = "project:"

        private const val MAX_VISIBLE_TASKS = 6
        private const val MAX_VISIBLE_OPTIONS = 6

        fun buildWidgetViews(
            context: Context,
            widgetData: SharedPreferences,
            widgetId: Int,
        ): RemoteViews {
            val view = widgetData.getString("widget_view_$widgetId", VIEW_INBOX) ?: VIEW_INBOX
            return try {
                if (view == VIEW_PICKER) {
                    buildViewPickerViews(context, widgetData, widgetId)
                } else {
                    buildTaskListViews(context, widgetData, widgetId, view)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Failed to build widget views, showing empty", e)
                RemoteViews(context.packageName, R.layout.widget_task_list).apply {
                    setTextViewText(R.id.tv_header_title, getViewDisplayName(widgetData, view))
                }
            }
        }

        private fun buildTaskListViews(
            context: Context,
            widgetData: SharedPreferences,
            widgetId: Int,
            view: String,
        ): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_task_list)

            val selectedName = getViewDisplayName(widgetData, view)
            views.setTextViewText(R.id.tv_header_title, selectedName)

            val headerIntent = Intent(context, WidgetInteractionReceiver::class.java).apply {
                action = ACTION_SET_VIEW
                putExtra(EXTRA_VIEW, VIEW_PICKER)
                putExtra(EXTRA_APP_WIDGET_ID, widgetId)
            }
            val headerPi = PendingIntent.getBroadcast(
                context, widgetId, headerIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            views.setOnClickPendingIntent(R.id.tv_header_title, headerPi)

            val addLaunchIntent = HomeWidgetLaunchIntent.getActivity(
                context,
                com.plansapp.MainActivity::class.java,
                Uri.parse("plans://addTask"),
            )
            views.setOnClickPendingIntent(R.id.btn_add, addLaunchIntent)

            val tasksJson = widgetData.getString("widget_tasks_$view", "[]") ?: "[]"
            val tasks = JSONArray(tasksJson)
            val taskCount = tasks.length()
            val visibleCount = minOf(taskCount, MAX_VISIBLE_TASKS)

            for (i in 0 until MAX_VISIBLE_TASKS) {
                val slotIdx = i + 1
                val itemId = context.resources.getIdentifier("ll_item_$slotIdx", "id", context.packageName)
                val checkId = context.resources.getIdentifier("iv_check_$slotIdx", "id", context.packageName)
                val titleId = context.resources.getIdentifier("tv_title_$slotIdx", "id", context.packageName)
                val dueId = context.resources.getIdentifier("tv_due_$slotIdx", "id", context.packageName)

                if (i < visibleCount) {
                    val taskObj = tasks.optJSONObject(i) ?: continue
                    val taskId = taskObj.getString("id")
                    val title = taskObj.getString("title")
                    val isCompleted = taskObj.optBoolean("is_completed", false)
                    val priority = taskObj.optInt("priority", 1)
                    val dueDate = if (taskObj.has("due_date") && !taskObj.isNull("due_date")) {
                        taskObj.optLong("due_date", -1)
                    } else -1L

                    views.setViewVisibility(itemId, android.view.View.VISIBLE)

                    val checkRes = if (isCompleted) R.drawable.widget_checkbox_checked
                    else when (priority) {
                        3 -> R.drawable.widget_checkbox_border_red
                        2 -> R.drawable.widget_checkbox_border_yellow
                        else -> R.drawable.widget_checkbox_border_gray
                    }
                    views.setImageViewResource(checkId, checkRes)

                    val toggleIntent = Intent(context, WidgetInteractionReceiver::class.java).apply {
                        action = ACTION_TOGGLE
                        putExtra(EXTRA_TASK_ID, taskId)
                        putExtra(EXTRA_APP_WIDGET_ID, widgetId)
                    }
                    val togglePi = PendingIntent.getBroadcast(
                        context, taskId.hashCode(), toggleIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    )
                    views.setOnClickPendingIntent(checkId, togglePi)

                    views.setTextViewText(titleId, title)
                    val titleLaunchIntent = HomeWidgetLaunchIntent.getActivity(
                        context,
                        com.plansapp.MainActivity::class.java,
                        Uri.parse("plans://task/$taskId"),
                    )
                    views.setOnClickPendingIntent(titleId, titleLaunchIntent)

                    if (dueDate > 0) {
                        views.setTextViewText(dueId, formatDueDate(dueDate))
                        views.setViewVisibility(dueId, android.view.View.VISIBLE)
                    } else {
                        views.setViewVisibility(dueId, android.view.View.GONE)
                    }
                } else {
                    views.setViewVisibility(itemId, android.view.View.GONE)
                }
            }

            val moreCount = taskCount - MAX_VISIBLE_TASKS
            if (moreCount > 0) {
                views.setTextViewText(R.id.tv_more, "and $moreCount more...")
                views.setViewVisibility(R.id.tv_more, android.view.View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.tv_more, android.view.View.GONE)
            }

            return views
        }

        private fun buildViewPickerViews(
            context: Context,
            widgetData: SharedPreferences,
            widgetId: Int,
        ): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.widget_view_picker)

            val builtInViews = listOf(
                Triple("Inbox", VIEW_INBOX, R.id.tv_option_1),
                Triple("Today", VIEW_TODAY, R.id.tv_option_2),
                Triple("Completed", VIEW_COMPLETED, R.id.tv_option_3),
            )

            for ((name, viewKey, viewId) in builtInViews) {
                views.setTextViewText(viewId, name)
                views.setViewVisibility(viewId, android.view.View.VISIBLE)
                val intent = Intent(context, WidgetInteractionReceiver::class.java).apply {
                    action = ACTION_SET_VIEW
                    putExtra(EXTRA_VIEW, viewKey)
                    putExtra(EXTRA_APP_WIDGET_ID, widgetId)
                }
                val pi = PendingIntent.getBroadcast(
                    context, viewKey.hashCode() + widgetId, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(viewId, pi)
            }

            val projectsJson = widgetData.getString("widget_projects", "[]") ?: "[]"
            val projects = JSONArray(projectsJson)
            val maxProjects = MAX_VISIBLE_OPTIONS - builtInViews.size
            val projectCount = minOf(projects.length(), maxProjects)

            for (i in 0 until projectCount) {
                val slotIdx = builtInViews.size + i + 1
                val viewId = context.resources.getIdentifier("tv_option_$slotIdx", "id", context.packageName)
                val projectObj = projects.optJSONObject(i) ?: continue
                val projectName = projectObj.getString("name")
                val projectId = projectObj.getString("id")

                views.setTextViewText(viewId, projectName)
                views.setViewVisibility(viewId, android.view.View.VISIBLE)
                val intent = Intent(context, WidgetInteractionReceiver::class.java).apply {
                    action = ACTION_SET_VIEW
                    putExtra(EXTRA_VIEW, "${VIEW_PROJECT_PREFIX}$projectId")
                    putExtra(EXTRA_APP_WIDGET_ID, widgetId)
                }
                val pi = PendingIntent.getBroadcast(
                    context, projectId.hashCode() + widgetId, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(viewId, pi)
            }

            for (i in (builtInViews.size + projectCount + 1)..MAX_VISIBLE_OPTIONS) {
                val viewId = context.resources.getIdentifier("tv_option_$i", "id", context.packageName)
                views.setViewVisibility(viewId, android.view.View.GONE)
            }

            return views
        }

        private fun getViewDisplayName(widgetData: SharedPreferences, view: String): String {
            return when (view) {
                VIEW_INBOX -> "Inbox"
                VIEW_TODAY -> "Today"
                VIEW_COMPLETED -> "Completed"
                VIEW_PICKER -> ""
                else -> {
                    if (view.startsWith(VIEW_PROJECT_PREFIX)) {
                        val projectId = view.removePrefix(VIEW_PROJECT_PREFIX)
                        val projectsJson = widgetData.getString("widget_projects", "[]") ?: "[]"
                        val projects = JSONArray(projectsJson)
                        for (i in 0 until projects.length()) {
                            val p = projects.optJSONObject(i) ?: continue
                            if (p.optString("id", "") == projectId) {
                                return p.getString("name")
                            }
                        }
                    }
                    "Inbox"
                }
            }
        }

        private fun formatDueDate(epochMillis: Long): String {
            val cal = Calendar.getInstance().apply { timeInMillis = epochMillis }
            val now = Calendar.getInstance()
            val tomorrow = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, 1) }
            return when {
                cal.get(Calendar.DAY_OF_YEAR) == now.get(Calendar.DAY_OF_YEAR) &&
                    cal.get(Calendar.YEAR) == now.get(Calendar.YEAR) ->
                    SimpleDateFormat("'Today' h:mm a", Locale.getDefault()).format(cal.time)
                cal.get(Calendar.DAY_OF_YEAR) == tomorrow.get(Calendar.DAY_OF_YEAR) &&
                    cal.get(Calendar.YEAR) == tomorrow.get(Calendar.YEAR) -> "Tomorrow"
                else -> SimpleDateFormat("MMM d", Locale.getDefault()).format(cal.time)
            }
        }

        fun handleToggle(
            context: Context,
            appWidgetId: Int,
            taskId: String,
        ) {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val view = prefs.getString("widget_view_$appWidgetId", VIEW_INBOX) ?: VIEW_INBOX
                val tasksJson = prefs.getString("widget_tasks_$view", "[]") ?: "[]"
                val tasks = JSONArray(tasksJson)

                for (i in 0 until tasks.length()) {
                    val obj = tasks.optJSONObject(i) ?: continue
                    if (obj.getString("id") == taskId) {
                        obj.put("is_completed", !obj.optBoolean("is_completed", false))
                        break
                    }
                }

                prefs.edit().putString("widget_tasks_$view", tasks.toString()).apply()
            } catch (e: Exception) {
                Log.e(TAG, "handleToggle failed", e)
            }

            WidgetDbHelper.getInstance(context).toggleTask(taskId)

            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val appWidgetManager = AppWidgetManager.getInstance(context)
                val views = buildWidgetViews(context, prefs, appWidgetId)
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                Log.e(TAG, "handleToggle widget update failed", e)
            }
        }

        fun handleSetView(
            context: Context,
            appWidgetId: Int,
            view: String,
        ) {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit().putString("widget_view_$appWidgetId", view).apply()

                val appWidgetManager = AppWidgetManager.getInstance(context)
                val views = if (view == VIEW_PICKER) {
                    buildViewPickerViews(context, prefs, appWidgetId)
                } else {
                    buildTaskListViews(context, prefs, appWidgetId, view)
                }
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                Log.e(TAG, "handleSetView failed", e)
            }
        }
    }
}
