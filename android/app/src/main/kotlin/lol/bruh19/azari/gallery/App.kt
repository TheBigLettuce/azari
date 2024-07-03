// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package lol.bruh19.azari.gallery

import android.app.Application
import android.content.pm.ApplicationInfo
import android.os.StrictMode
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec

class App : Application() {
    lateinit var engines: FlutterEngineGroup

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

//        prewarmEngine(this, "main")
//        prewarmEngine(engines, this, "mainPickfile")
    }
}

fun prewarmEngine(app: App, entrypoint: String) {
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
}