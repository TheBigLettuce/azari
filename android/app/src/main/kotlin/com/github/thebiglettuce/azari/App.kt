// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package com.github.thebiglettuce.azari

import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.os.StrictMode
import android.util.Log
import androidx.core.content.getSystemService
import com.github.piasy.biv.BigImageViewer
import com.github.piasy.biv.loader.glide.GlideImageLoader
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.dart.DartExecutor
import com.github.thebiglettuce.azari.generated.GalleryApi
import com.github.thebiglettuce.azari.generated.Notification
import com.github.thebiglettuce.azari.generated.NotificationGroup
import com.github.thebiglettuce.azari.generated.NotificationsApi
import com.github.thebiglettuce.azari.generated.NotificationChannel as NotificationChannelApi
import com.github.thebiglettuce.azari.impls.NativeViewFactory
import com.github.thebiglettuce.azari.mover.MediaLoaderAndMover

class App : Application() {
    var appContextChannelRegistered = false
    internal lateinit var engines: FlutterEngineGroup
    val mediaLoaderAndMover = MediaLoaderAndMover(this)

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

        BigImageViewer.initialize(GlideImageLoader.with(applicationContext))

        engines = FlutterEngineGroup(this)
        mediaLoaderAndMover.initMover()

        createNotifChannels(this)
    }
}

private fun createNotifChannels(context: Context) {
    context.getSystemService<NotificationManager>()!!.apply {
        createNotificationChannel(
            NotificationChannel(
                NotificationChannelApi.MISC.id(),
                context.getString(R.string.misc_channel),
                NotificationManager.IMPORTANCE_LOW,
            )
        )

        createNotificationChannel(
            NotificationChannel(
                NotificationChannelApi.DOWNLOADER.id(),
                context.getString(R.string.downloader_channel),
                NotificationManager.IMPORTANCE_LOW,
            )
        )
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

    return engine
}


class LocaleBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_LOCALE_CHANGED) {
            createNotifChannels(context)
        }
    }
}
