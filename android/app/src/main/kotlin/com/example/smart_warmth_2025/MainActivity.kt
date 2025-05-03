/*
package com.example.smart_warmth_2025

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity()
*/

package com.example.smart_warmth_2025
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.tuazienda.smart_warmth_2025/app_settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "openAppPermissionSettings") {
                val permissionType = call.argument<String>("permissionType") ?: ""
                openAppPermissionSettings(permissionType)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }

    private fun openAppPermissionSettings(permissionType: String) {
        val intent = when (permissionType) {
            "camera" -> Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
                putExtra(":settings:fragment_args_key", "permission_settings")
            }
            "location" -> Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
                putExtra(":settings:fragment_args_key", "permission_settings")
            }
            "bluetoothScan", "bluetoothConnect" -> Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
                putExtra(":settings:fragment_args_key", "permission_settings")
            }
            else -> Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
            }
        }

        startActivity(intent)
    }
}