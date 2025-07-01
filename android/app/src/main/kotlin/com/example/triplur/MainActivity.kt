package com.triplur.co.uk // Make sure this matches your actual package name

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.triplur/dialer"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "openDialer") {
                val number = call.argument<String>("number")
                if (!number.isNullOrEmpty()) {
                    val intent = Intent(Intent.ACTION_DIAL)
                    intent.data = Uri.parse("tel:$number")
                    startActivity(intent)
                    result.success(null)
                } else {
                    result.error("INVALID_NUMBER", "Phone number was null or empty", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
