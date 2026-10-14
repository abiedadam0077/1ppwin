package app.nova.windowscloud

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var minecraftViewerFactory: MinecraftViewerFactory? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "nova/minecraft_viewer")
        val factory = MinecraftViewerFactory(channel)
        minecraftViewerFactory = factory
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "nova/minecraft_viewer",
            factory,
        )
        channel.setMethodCallHandler { call, result -> factory.handle(call, result) }
    }

    override fun onDestroy() {
        minecraftViewerFactory?.disposeAll()
        minecraftViewerFactory = null
        super.onDestroy()
    }
}
