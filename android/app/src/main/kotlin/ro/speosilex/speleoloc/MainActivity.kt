package ro.speosilex.speleoloc

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "speleoloc/deep_link"
    private var methodChannel: MethodChannel? = null
    private var safBridge: SafBridge? = null

    // A link that started this process is kept here until Dart asks for it:
    // configureFlutterEngine runs before the Dart entrypoint, and the engine
    // drops platform messages sent while no isolate is listening yet.
    private var initialLink: String? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        // A recreated activity still carries the launch intent; its link was
        // already delivered by the first instance.
        initialLink = if (savedInstanceState == null) linkOf(intent) else null
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).also {
            it.setMethodCallHandler { call, result ->
                if (call.method == "getInitialLink") {
                    result.success(initialLink)
                    initialLink = null
                } else {
                    result.notImplemented()
                }
            }
        }
        safBridge = SafBridge(this).also {
            MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SafBridge.CHANNEL)
                .setMethodCallHandler(it)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (safBridge?.onActivityResult(requestCode, resultCode, data) == true) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // The app is running, so Dart is already listening.
        linkOf(intent)?.let { methodChannel?.invokeMethod("onDeepLink", it) }
    }

    private fun linkOf(intent: Intent?): String? =
        if (intent?.action == Intent.ACTION_VIEW) intent.data?.toString() else null
}
