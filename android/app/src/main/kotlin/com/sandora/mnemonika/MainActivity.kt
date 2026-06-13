package com.sandora.mnemonika

import android.os.Build
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var academyDisplayNestDepth = 0
    private var savedPreferredDisplayModeId: Int? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                METHOD_PREFER -> {
                    val args = call.arguments as? Map<*, *>
                    val maxHz = (args?.get("maxHz") as? Number)?.toFloat() ?: 120f
                    result.success(preferRefreshRateUpTo(maxHz))
                }

                METHOD_RESTORE -> {
                    restorePreferredDisplayMode()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    /**
     * Выбирает [Display.Mode] с максимальной частотой не выше [maxHz] Гц (или лучший доступный).
     * Нужен API 23+ ([WindowManager.LayoutParams.preferredDisplayModeId]).
     */
    private fun preferRefreshRateUpTo(maxHz: Float): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return false
        val display = display ?: return false
        val modes = display.supportedModes ?: return false
        if (modes.isEmpty()) return false
        val pick = modes
            .filter { it.refreshRate <= maxHz + 0.01f }
            .maxByOrNull { it.refreshRate }
            ?: modes.maxByOrNull { it.refreshRate }
            ?: return false
        val attrs = window.attributes
        if (academyDisplayNestDepth == 0) {
            savedPreferredDisplayModeId = attrs.preferredDisplayModeId
        }
        academyDisplayNestDepth++
        attrs.preferredDisplayModeId = pick.modeId
        window.attributes = attrs
        return true
    }

    private fun restorePreferredDisplayMode() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return
        if (academyDisplayNestDepth <= 0) return
        academyDisplayNestDepth--
        if (academyDisplayNestDepth > 0) return
        val attrs = window.attributes
        attrs.preferredDisplayModeId = savedPreferredDisplayModeId ?: 0
        window.attributes = attrs
        savedPreferredDisplayModeId = null
    }

    companion object {
        private const val CHANNEL = "mneem/academy_display"
        private const val METHOD_PREFER = "preferRefreshRate"
        private const val METHOD_RESTORE = "restoreRefreshRate"
    }
}
