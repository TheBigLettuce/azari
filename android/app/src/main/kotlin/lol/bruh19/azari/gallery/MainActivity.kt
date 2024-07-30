// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package lol.bruh19.azari.gallery

import android.app.NotificationManager
import android.content.Context
import android.net.ConnectivityManager
import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import lol.bruh19.azari.gallery.enginebindings.ActivityContextChannel
import lol.bruh19.azari.gallery.enginebindings.AppContextChannel
import lol.bruh19.azari.gallery.generated.GalleryApi
import lol.bruh19.azari.gallery.impls.NetworkCallbackImpl
import lol.bruh19.azari.gallery.mover.MediaLoaderAndMover
import lol.bruh19.azari.gallery.generated.GalleryHostApi
import lol.bruh19.azari.gallery.impls.GalleryHostApiImpl

class MainActivity : FlutterFragmentActivity() {
    private val intents =
        ActivityResultIntents(this, { activityContextChannel }, { mediaLoaderAndMover })
    private val connectivityManager by lazy { getSystemService(ConnectivityManager::class.java) }
    val appContextChannel: AppContextChannel by lazy {
        val app = this.applicationContext as App

        val engine = getOrMakeEngine(app, "main")
        GalleryHostApi.setUp(
            engine.dartExecutor.binaryMessenger,
            GalleryHostApiImpl(this, mediaLoaderAndMover)
        )
        AppContextChannel(engine, GalleryApi(engine.dartExecutor.binaryMessenger))
    }

    private val mediaLoaderAndMover: MediaLoaderAndMover by lazy { (applicationContext as App).mediaLoaderAndMover }

    private val activityContextChannel: ActivityContextChannel by lazy {
        val engine = FlutterEngineCache.getInstance()["main"]!!

        ActivityContextChannel(engine.dartExecutor, GalleryApi(engine.dartExecutor.binaryMessenger))
    }

    private val netStatus by lazy {
        NetworkCallbackImpl(
            GalleryApi(appContextChannel.engine.dartExecutor.binaryMessenger),
            this
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        enableEdgeToEdge()

        super.onCreate(savedInstanceState)

        appContextChannel.attach(
            this.applicationContext as App,
            mediaLoaderAndMover,
            getSystemService(ConnectivityManager::class.java)
        )

        connectivityManager.registerDefaultNetworkCallback(netStatus)
        activityContextChannel.attach(this, intents, mediaLoaderAndMover)
    }

    override fun getCachedEngineId(): String = "main"
    override fun provideFlutterEngine(context: Context): FlutterEngine = appContextChannel.engine

    override fun onDestroy() {
        super.onDestroy()

        connectivityManager.unregisterNetworkCallback(netStatus)
        intents.unregisterAll()
        activityContextChannel.detach()

        (getSystemService(NOTIFICATION_SERVICE) as NotificationManager).cancelAll()
    }
}