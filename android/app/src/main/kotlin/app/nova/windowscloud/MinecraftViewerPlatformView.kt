package app.nova.windowscloud

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.view.View
import android.webkit.HttpAuthHandler
import android.webkit.JavascriptInterface
import android.webkit.SslErrorHandler
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.webkit.WebSettings
import org.json.JSONObject
import java.util.Locale
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class MinecraftViewerFactory(
    private val channel: MethodChannel,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    private val views = mutableMapOf<Int, MinecraftViewerPlatformView>()

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val parameters = args as? Map<String, Any?> ?: emptyMap()
        val viewer = MinecraftViewerPlatformView(context, viewId, parameters, channel) {
            views.remove(viewId)
        }
        views[viewId] = viewer
        return viewer
    }

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        val arguments = call.arguments as? Map<*, *>
        if (arguments == null) {
            result.error("invalid_arguments", "A viewer ID and operation arguments are required.", null)
            return
        }
        val viewId = (arguments["viewId"] as? Number)?.toInt()
        val viewer = viewId?.let(views::get)
        if (viewer == null) {
            result.error("viewer_missing", "Minecraft viewer is no longer available.", null)
            return
        }

        when (call.method) {
            "sendKey" -> {
                val key = arguments["key"] as? String
                val down = arguments["down"] as? Boolean
                if (key == null || down == null) {
                    result.error("invalid_arguments", "A key and down-state are required.", null)
                } else {
                    viewer.sendKey(key, down)
                    result.success(null)
                }
            }
            "movePointer" -> {
                val dx = (arguments["dx"] as? Number)?.toDouble()
                val dy = (arguments["dy"] as? Number)?.toDouble()
                if (dx == null || dy == null || !dx.isFinite() || !dy.isFinite()) {
                    result.error("invalid_arguments", "Finite pointer deltas are required.", null)
                } else {
                    viewer.movePointer(dx, dy)
                    result.success(null)
                }
            }
            "clickPointer" -> {
                val button = arguments["button"] as? String
                val down = arguments["down"] as? Boolean
                if (button == null || down == null) {
                    result.error("invalid_arguments", "A pointer button and down-state are required.", null)
                } else {
                    viewer.clickPointer(button, down)
                    result.success(null)
                }
            }
            "typeText" -> {
                val text = arguments["text"] as? String
                if (text == null || text.length > 2000) {
                    result.error("invalid_arguments", "Text is missing or too long.", null)
                } else {
                    viewer.typeText(text)
                    result.success(null)
                }
            }
            else -> result.notImplemented()
        }
    }

    fun disposeAll() {
        views.values.toList().forEach { it.dispose() }
        views.clear()
    }
}

@SuppressLint("SetJavaScriptEnabled")
class MinecraftViewerPlatformView(
    context: Context,
    private val viewId: Int,
    parameters: Map<String, Any?>,
    private val channel: MethodChannel,
    private val onDispose: () -> Unit,
) : PlatformView {
    private val webView = WebView(context)
    private val handler = Handler(Looper.getMainLooper())
    private val initialUri = Uri.parse(parameters["url"] as? String ?: "")
    private val allowedHost = initialUri.host?.lowercase(Locale.ROOT).orEmpty()
    private val trustedTunnel = initialUri.scheme == "https" &&
        Regex("^[a-z0-9-]+[.]trycloudflare[.]com$").matches(allowedHost) &&
        (initialUri.port == -1 || initialUri.port == 443) &&
        initialUri.query.isNullOrEmpty() &&
        initialUri.fragment.isNullOrEmpty() &&
        initialUri.encodedAuthority?.contains('@') != true
    private val username = (parameters["username"] as? String)?.takeIf { it.isNotBlank() } ?: "nova"
    private val password = parameters["password"] as? String ?: ""
    private var disposed = false

    init {
        webView.setBackgroundColor(Color.rgb(7, 16, 29))
        webView.isFocusable = true
        webView.isFocusableInTouchMode = true
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            setSupportZoom(false)
            builtInZoomControls = false
            displayZoomControls = false
            allowFileAccess = false
            allowContentAccess = false
            javaScriptCanOpenWindowsAutomatically = false
            setSupportMultipleWindows(false)
            mixedContentMode = WebSettings.MIXED_CONTENT_NEVER_ALLOW
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) safeBrowsingEnabled = true
        }
        webView.addJavascriptInterface(ViewerBridge(), "NovaBridge")
        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest): Boolean {
                val uri = request.url
                val allowed = uri.scheme == "https" &&
                    (uri.port == -1 || uri.port == 443) &&
                    uri.encodedAuthority?.contains('@') != true &&
                    uri.host?.equals(allowedHost, ignoreCase = true) == true
                if (!allowed) emitStatus("navigation_blocked")
                return !allowed
            }

            override fun onPageFinished(view: WebView, url: String) {
                super.onPageFinished(view, url)
                emitStatus("page_loaded")
            }

            override fun onReceivedHttpAuthRequest(
                view: WebView,
                authHandler: HttpAuthHandler,
                host: String,
                realm: String,
            ) {
                if (!disposed && host.equals(allowedHost, ignoreCase = true) && password.isNotEmpty()) {
                    authHandler.proceed(username, password)
                } else {
                    authHandler.cancel()
                    emitStatus("authentication_failed")
                }
            }

            override fun onReceivedSslError(view: WebView, sslHandler: SslErrorHandler, error: android.net.http.SslError) {
                sslHandler.cancel()
                emitStatus("tls_error")
            }
        }

        if (!trustedTunnel || password.isBlank()) {
            emitStatus("unsupported")
        } else {
            webView.loadUrl(initialUri.toString())
        }
    }

    override fun getView(): View = webView

    fun sendKey(key: String, down: Boolean) {
        val allowed = setOf("w", "a", "s", "d", "e", "q", "t", "space", "escape", "shift", "ctrl", "f3", "enter", "backspace", "1", "2", "3")
        if (key !in allowed) return
        val script = "window.novaController&&window.novaController.key(${JSONObject.quote(key)},$down)"
        webView.evaluateJavascript(script, null)
    }

    fun movePointer(dx: Double, dy: Double) {
        val safeDx = dx.coerceIn(-400.0, 400.0)
        val safeDy = dy.coerceIn(-400.0, 400.0)
        val x = String.format(Locale.US, "%.3f", safeDx)
        val y = String.format(Locale.US, "%.3f", safeDy)
        webView.evaluateJavascript("window.novaController&&window.novaController.move($x,$y)", null)
    }

    fun clickPointer(button: String, down: Boolean) {
        if (button != "left" && button != "right") return
        webView.evaluateJavascript("window.novaController&&window.novaController.click(${JSONObject.quote(button)},$down)", null)
    }

    fun typeText(text: String) {
        webView.evaluateJavascript("window.novaController&&window.novaController.typeText(${JSONObject.quote(text)})", null)
    }

    private fun emitStatus(status: String) {
        val allowed = setOf("connecting", "connected", "disconnected", "credentials_required", "page_loaded", "navigation_blocked", "authentication_failed", "tls_error", "unsupported")
        if (status !in allowed) return
        handler.post {
            if (!disposed) {
                channel.invokeMethod("viewerStatus", mapOf("viewId" to viewId, "status" to status))
            }
        }
    }

    private inner class ViewerBridge {
        @JavascriptInterface
        fun onStatus(status: String?) {
            if (status != null) emitStatus(status)
        }
    }

    override fun dispose() {
        if (disposed) return
        disposed = true
        try {
            webView.stopLoading()
            webView.removeJavascriptInterface("NovaBridge")
            webView.loadUrl("about:blank")
            webView.destroy()
        } catch (_: Throwable) {
            // The Android WebView may already be detached during Activity teardown.
        }
        onDispose()
    }
}
