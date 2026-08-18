package ro.speosilex.speleoloc

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "speleoloc/deep_link"
    private var methodChannel: MethodChannel? = null
    private var safBridge: SafBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        safBridge = SafBridge(this).also {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SafBridge.CHANNEL)
                .setMethodCallHandler(it)
        }
        handleIntent(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (safBridge?.onActivityResult(requestCode, resultCode, data) == true) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_VIEW) {
            val uri = intent.data?.toString()
            if (uri != null) {
                methodChannel?.invokeMethod("onDeepLink", uri)
            }
        }
    }
}
