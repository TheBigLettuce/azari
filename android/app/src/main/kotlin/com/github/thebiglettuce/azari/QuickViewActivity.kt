// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package com.github.thebiglettuce.azari

import android.app.NotificationManager
import android.content.Context
import android.net.ConnectivityManager
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import com.github.thebiglettuce.azari.enginebindings.ActivityContextChannel
import com.github.thebiglettuce.azari.enginebindings.AppContextChannel
import com.github.thebiglettuce.azari.generated.GalleryApi
import com.github.thebiglettuce.azari.generated.GalleryHostApi
import com.github.thebiglettuce.azari.generated.NotificationsApi
import com.github.thebiglettuce.azari.impls.GalleryHostApiImpl
import com.github.thebiglettuce.azari.mover.MediaLoaderAndMover

class QuickViewActivity : FlutterFragmentActivity() {
    private val appContextChannel: AppContextChannel by lazy {
        val app = this.applicationContext as App

        val engine = makeEngine(app, "mainQuickView")

        AppContextChannel(
            engine, GalleryApi(engine.dartExecutor.binaryMessenger),
        )
    }

    private val mediaLoaderAndMover: MediaLoaderAndMover by lazy {
        (this.applicationContext as App).mediaLoaderAndMover
    }

    private val notificationsHolder: CurrentNotificationsHolder by lazy {
        CurrentNotificationsHolder(
            getSystemService(NotificationManager::class.java)
        )
    }

    private var activityContextChannel: ActivityContextChannel? = null

    private val intents by lazy {
        ActivityResultIntents(
            this,
            { activityContextChannel!! },
            { mediaLoaderAndMover })
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        GalleryHostApi.setUp(
            appContextChannel.engine.dartExecutor.binaryMessenger,
            GalleryHostApiImpl(this, mediaLoaderAndMover)
        )

        appContextChannel.attachSecondary(
            this, mediaLoaderAndMover,
            getSystemService(
                ConnectivityManager::class.java
            ),
        )

        activityContextChannel = ActivityContextChannel(
            appContextChannel.engine.dartExecutor,
            GalleryApi(appContextChannel.engine.dartExecutor.binaryMessenger)
        )

        activityContextChannel!!.attach(this, intents, mediaLoaderAndMover)

        NotificationsApi.setUp(
            appContextChannel.engine.dartExecutor.binaryMessenger,
            NotificationsApiImpl(
                this,
                getSystemService(NotificationManager::class.java),
                notificationsHolder
            ),
        )
    }

    override fun getCachedEngineId(): String? = null
    override fun provideFlutterEngine(context: Context): FlutterEngine = appContextChannel.engine

    override fun onDestroy() {
        super.onDestroy()
        appContextChannel.detach()

        try {
            appContextChannel.engine.destroy()
        } catch (e: Exception) {
            Log.w("QuickViewActivity.onDestroy", "threw on destroying engine", e)
        }

        intents.unregisterAll()
        GalleryHostApi.setUp(appContextChannel.engine.dartExecutor.binaryMessenger, null)
        NotificationsApi.setUp(appContextChannel.engine.dartExecutor.binaryMessenger, null)
        activityContextChannel!!.detach()

        notificationsHolder.cancelAll()
    }
}