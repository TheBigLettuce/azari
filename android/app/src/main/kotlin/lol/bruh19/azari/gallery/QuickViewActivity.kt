// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package lol.bruh19.azari.gallery

import android.content.Context
import android.net.ConnectivityManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import lol.bruh19.azari.gallery.enginebindings.EngineBindings
import lol.bruh19.azari.gallery.generated.GalleryApi
import lol.bruh19.azari.gallery.generated.GalleryHostApi
import lol.bruh19.azari.gallery.impls.GalleryHostApiImpl
import lol.bruh19.azari.gallery.mover.MediaLoaderAndMover

class QuickViewActivity : FlutterFragmentActivity() {
    private val engineBindings: EngineBindings by lazy {
        val app = this.applicationContext as App

        val engine = makeEngine(app, "mainQuickView")

        EngineBindings(
            engine, GalleryApi(engine.dartExecutor.binaryMessenger),
        )
    }

    private val mediaLoaderAndMover: MediaLoaderAndMover by lazy {
        (this.applicationContext as App).mediaLoaderAndMover
    }

    private val intents by lazy {
        ActivityResultIntents(
            this,
            { engineBindings },
            { mediaLoaderAndMover })
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        GalleryHostApi.setUp(
            engineBindings.engine.dartExecutor.binaryMessenger,
            GalleryHostApiImpl(this, mediaLoaderAndMover)
        )

        engineBindings.attach(
            this, mediaLoaderAndMover,
            getSystemService(
                ConnectivityManager::class.java
            ),
            intents,
        )
    }

    override fun getCachedEngineId(): String = "mainQuickView"
    override fun provideFlutterEngine(context: Context): FlutterEngine = engineBindings.engine

    override fun onDestroy() {
        super.onDestroy()
        engineBindings.detach()
        engineBindings.engine.destroy()
        FlutterEngineCache.getInstance().remove("mainQuickView")
        intents.unregisterAll()
        GalleryHostApi.setUp(engineBindings.engine.dartExecutor.binaryMessenger, null)
    }
}