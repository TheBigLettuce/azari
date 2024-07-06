// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package lol.bruh19.azari.gallery.impls

import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import io.flutter.embedding.android.FlutterFragmentActivity
import lol.bruh19.azari.gallery.generated.GalleryApi

class NetworkCallbackImpl(
    private val galleryApi: GalleryApi,
    private val context: FlutterFragmentActivity,
) : ConnectivityManager.NetworkCallback() {
//    override fun onLost(network: Network) {
//        context.runOnUiThread { galleryApi.notifyNetworkStatus(false) {} }
//    }

    override fun onCapabilitiesChanged(network: Network, networkCapabilities: NetworkCapabilities) {
        val capInternet =
            networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
        val capValidated =
            networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)

        context.runOnUiThread {
            galleryApi.notifyNetworkStatus(capInternet and capValidated) {}
        }
    }
}