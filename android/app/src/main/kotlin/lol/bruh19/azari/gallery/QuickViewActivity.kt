package lol.bruh19.azari.gallery

import android.content.Context
import android.net.ConnectivityManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache

class QuickViewActivity : FlutterFragmentActivity() {
    private val engineBindings: EngineBindings by lazy {
        EngineBindings(
            activity = this, "mainQuickView", getSystemService(
                ConnectivityManager::class.java
            )
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val app = this.applicationContext as App
        prewarmEngine(app, "mainQuickView")

        engineBindings.attach()
    }

    override fun getCachedEngineId(): String? {
        return "mainQuickView"
    }

    override fun onDestroy() {
        super.onDestroy()
        engineBindings.detach()
        engineBindings.engine.destroy()
        FlutterEngineCache.getInstance().remove("mainQuickView")
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return engineBindings.engine
    }
}