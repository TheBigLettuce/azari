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
import androidx.core.content.getSystemService
import coil3.ImageLoader
import coil3.SingletonImageLoader
import coil3.gif.AnimatedImageDecoder
import coil3.memory.MemoryCache
import coil3.video.VideoFrameDecoder
import com.github.thebiglettuce.azari.generated.FlutterGalleryData
import com.github.thebiglettuce.azari.generated.GalleryVideoEvents
import com.github.thebiglettuce.azari.generated.PlatformGalleryApi
import com.github.thebiglettuce.azari.impls.GalleryEventsImpl
import com.github.thebiglettuce.azari.impls.GalleryImpl
import com.github.thebiglettuce.azari.impls.NativeViewFactory
import com.github.thebiglettuce.azari.mover.Thumbnailer
import com.google.android.material.color.DynamicColors
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineGroup
import io.flutter.embedding.engine.dart.DartExecutor
import com.github.thebiglettuce.azari.generated.NotificationChannel as NotificationChannelApi

class App : Application() {
    internal lateinit var engines: FlutterEngineGroup
    val thumbnailer = Thumbnailer(this)

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
        thumbnailer.initMover()

        createNotifChannels(this)

        SingletonImageLoader.setSafe { context ->
            ImageLoader.Builder(context)
                .components {
                    add(AnimatedImageDecoder.Factory())
                    add(VideoFrameDecoder.Factory())
                }
                .memoryCache {
                    MemoryCache.Builder().maxSizePercent(context, 0.25).build()
                }
                .build()
        }
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

fun makeEngine(
    app: App,
    entrypoint: String,
    galleryEvents: GalleryEventsImpl,
): FlutterEngine {
    val dartEntrypoint =
        DartExecutor.DartEntrypoint(
            FlutterInjector.instance().flutterLoader().findAppBundlePath(), entrypoint
        )
    val engine = app.engines.createAndRunEngine(app, dartEntrypoint)
    engine.platformViewsController.registry.registerViewFactory(
        "gallery",
        NativeViewFactory(
            FlutterGalleryData(engine.dartExecutor.binaryMessenger),
            PlatformGalleryApi(engine.dartExecutor.binaryMessenger),
            GalleryVideoEvents(engine.dartExecutor.binaryMessenger),
            galleryEvents.events,
            galleryEvents.pageChangeEvents,
            galleryEvents.playerButtonsEvents,
        )
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
