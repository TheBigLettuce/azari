// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package lol.bruh19.azari.gallery

import android.app.NotificationManager
import android.content.Context
import android.net.ConnectivityManager
import android.os.Bundle
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import lol.bruh19.azari.gallery.enginebindings.EngineBindings
import lol.bruh19.azari.gallery.generated.GalleryApi
import lol.bruh19.azari.gallery.impls.NetworkCallbackImpl
import lol.bruh19.azari.gallery.mover.MediaLoaderAndMover

class MainActivity : FlutterFragmentActivity() {
    private val intents = ActivityResultIntents(this, { engineBindings }, { mediaLoaderAndMover })
    private val connectivityManager by lazy { getSystemService(ConnectivityManager::class.java) }
    private val engineBindings: EngineBindings by lazy { (applicationContext as App).engineBindings }
    private val mediaLoaderAndMover: MediaLoaderAndMover by lazy { (applicationContext as App).mediaLoaderAndMover }

    private val netStatus by lazy {
        NetworkCallbackImpl(
            GalleryApi(engineBindings.engine.dartExecutor.binaryMessenger),
            this
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        engineBindings.attach(this, mediaLoaderAndMover, connectivityManager, intents)
        connectivityManager.registerDefaultNetworkCallback(netStatus)
    }

    override fun getCachedEngineId(): String = "main"
    override fun provideFlutterEngine(context: Context): FlutterEngine = engineBindings.engine

    override fun onDestroy() {
        super.onDestroy()

        engineBindings.detach()
        connectivityManager.unregisterNetworkCallback(netStatus)
        intents.unregisterAll()

        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).cancelAll()
    }
}