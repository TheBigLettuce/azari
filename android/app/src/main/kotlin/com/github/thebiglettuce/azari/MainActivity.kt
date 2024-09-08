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
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import com.github.thebiglettuce.azari.enginebindings.ActivityContextChannel
import com.github.thebiglettuce.azari.enginebindings.AppContextChannel
import com.github.thebiglettuce.azari.generated.GalleryApi
import com.github.thebiglettuce.azari.impls.NetworkCallbackImpl
import com.github.thebiglettuce.azari.mover.MediaLoaderAndMover
import com.github.thebiglettuce.azari.generated.GalleryHostApi
import com.github.thebiglettuce.azari.generated.NotificationsApi
import com.github.thebiglettuce.azari.impls.GalleryHostApiImpl

class MainActivity : FlutterFragmentActivity() {
    private val intents =
        ActivityResultIntents(this, { activityContextChannel!! }, { mediaLoaderAndMover })
    private val connectivityManager by lazy { getSystemService(ConnectivityManager::class.java) }
    private val appContextChannel: AppContextChannel by lazy {
        val app = this.applicationContext as App

        val engine = makeEngine(app, "main")
        GalleryHostApi.setUp(
            engine.dartExecutor.binaryMessenger,
            GalleryHostApiImpl(this, mediaLoaderAndMover)
        )
        AppContextChannel(engine, GalleryApi(engine.dartExecutor.binaryMessenger))
    }

    private val mediaLoaderAndMover: MediaLoaderAndMover by lazy { (applicationContext as App).mediaLoaderAndMover }
    private val notificationsHolder: CurrentNotificationsHolder by lazy {
        CurrentNotificationsHolder(
            getSystemService(NotificationManager::class.java)
        )
    }

    private var activityContextChannel: ActivityContextChannel? = null

    private val netStatus by lazy {
        NetworkCallbackImpl(
            GalleryApi(appContextChannel.engine.dartExecutor.binaryMessenger),
            this
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()

        super.onCreate(savedInstanceState)

        Log.w("onCreate", "called")

        appContextChannel.attach(
            this.applicationContext as App,
            mediaLoaderAndMover,
            getSystemService(ConnectivityManager::class.java)
        )

        connectivityManager.registerDefaultNetworkCallback(netStatus)

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
            Log.w("MainActivity.onDestroy", "threw on destroying engine", e)
        }

        connectivityManager.unregisterNetworkCallback(netStatus)
        intents.unregisterAll()
        activityContextChannel!!.detach()

        NotificationsApi.setUp(appContextChannel.engine.dartExecutor.binaryMessenger, null)

        notificationsHolder.cancelAll()
    }
}