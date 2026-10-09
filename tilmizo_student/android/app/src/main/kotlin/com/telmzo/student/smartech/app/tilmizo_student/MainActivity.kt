package com.telmzo.student.smartech.app.tilmizo_student

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Opens this app's notification settings for the permission card.
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "telmizo/notification_settings",
        ).setMethodCallHandler { call, result ->
            if (call.method == "open") {
                result.success(openNotificationSettings())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun openNotificationSettings(): Boolean {
        val notificationSettings =
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
            } else {
                null
            }
        val appDetails =
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", packageName, null))
        for (intent in listOfNotNull(notificationSettings, appDetails)) {
            try {
                startActivity(intent)
                return true
            } catch (_: Exception) {
                // Try the next settings screen.
            }
        }
        return false
    }
}
