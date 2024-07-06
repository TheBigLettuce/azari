// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package lol.bruh19.azari.gallery

import android.app.Application
import android.content.pm.ApplicationInfo
import android.os.StrictMode
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.dart.DartExecutor
import lol.bruh19.azari.gallery.enginebindings.EngineBindings
import lol.bruh19.azari.gallery.generated.GalleryApi
import lol.bruh19.azari.gallery.generated.GalleryHostApi
import lol.bruh19.azari.gallery.impls.GalleryHostApiImpl
import lol.bruh19.azari.gallery.impls.NativeViewFactory
import lol.bruh19.azari.gallery.mover.MediaLoaderAndMover

class App : Application() {
    internal lateinit var engines: FlutterEngineGroup
    val mediaLoaderAndMover = MediaLoaderAndMover(this)
    val engineBindings: EngineBindings by lazy {
        val engine = makeEngine(this, "main")
        GalleryHostApi.setUp(
            engine.dartExecutor.binaryMessenger,
            GalleryHostApiImpl(this, mediaLoaderAndMover)
        )
        EngineBindings(engine, GalleryApi(engine.dartExecutor.binaryMessenger))
    }

    override fun onCreate() {
        super.onCreate()
        val appFlags = applicationInfo.flags
        if ((appFlags and ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
            StrictMode.setThreadPolicy(
                StrictMode.ThreadPolicy.Builder().detectAll().build()
            )
            StrictMode.setVmPolicy(
                StrictMode.VmPolicy.Builder().detectAll().build()
            )
        }

        engines = FlutterEngineGroup(this)
        mediaLoaderAndMover.initMover(engineBindings::notifyGallery)
    }
}

fun makeEngine(app: App, entrypoint: String): FlutterEngine {
    val dartEntrypoint =
        DartExecutor.DartEntrypoint(
            FlutterInjector.instance().flutterLoader().findAppBundlePath(), entrypoint
        )
    val engine = app.engines.createAndRunEngine(app, dartEntrypoint)
    engine.platformViewsController.registry.registerViewFactory(
        "imageview",
        NativeViewFactory(GalleryApi(engine.dartExecutor.binaryMessenger))
    )
    FlutterEngineCache.getInstance().put(entrypoint, engine)

    return engine
}