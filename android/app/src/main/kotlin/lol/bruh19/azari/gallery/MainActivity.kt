// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package lol.bruh19.azari.gallery

import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.MediaStore
import android.util.Log
import androidx.documentfile.provider.DocumentFile
import androidx.lifecycle.lifecycleScope
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import okio.FileSystem
import okio.Path.Companion.toPath
import okio.use


data class FilesDest(
    val dest: String,
    val volumeName: String?,
    val images: List<Uri>,
    val videos: List<Uri>,
    val move: Boolean,
    val newDir: Boolean
)

data class MoveOp(val source: String, val rootUri: Uri, val dir: String)
data class ThumbOp(
    val thumb: Any,
    val saveToPinned: Boolean = false,
    val callback: ((String, Long) -> Unit)
)

class MainActivity : FlutterActivity() {
    private val engineBindings: EngineBindings by lazy {
        EngineBindings(activity = this, "main", getSystemService(ConnectivityManager::class.java))
    }

    private fun copyFile(
        e: Uri,
        volumeName: String?,
        newDir: Boolean,
        newDirIsLocal: Boolean = false,
        isImage: Boolean,
        deleteAfter: Boolean,
        dest: String
    ) {
        val mimeType = contentResolver.getType(e)!!

        contentResolver.openInputStream(e)?.use { stream ->
            contentResolver.query(
                e,
                if (!newDirIsLocal) {
                    arrayOf(
                        MediaStore.MediaColumns.DISPLAY_NAME,
                    )
                } else {
                    arrayOf(
                        MediaStore.MediaColumns.DISPLAY_NAME,
                        MediaStore.MediaColumns.DATE_MODIFIED
                    )
                },
                null,
                null,
                null
            )?.use {
                if (!it.moveToFirst()) {
                    return@use
                }

                if (newDir) {
                    if (newDirIsLocal) {
                        val file = java.io.File(dest, it.getString(0))
                        if (!file.createNewFile()) {
                            throw Exception("file exists")
                        }

                        file.outputStream().use { out ->
                            stream.transferTo(out)
                            out.flush()
                            out.fd.sync()
                        }

                        file.setLastModified(it.getLong(1))

                        return
                    }

                    DocumentFile.fromTreeUri(context, Uri.parse(dest))
                        ?.run {
                            if (this.isFile || !this.canWrite()) {
                                return@use
                            }

                            val file = this.createFile(mimeType, it.getString(0)) ?: return@use
                            contentResolver.openOutputStream(file.uri)?.use { out ->
                                stream.transferTo(out)
                                if (deleteAfter) {
                                    contentResolver.delete(e, null)
                                }
                            }

                        }

                    return
                }

                val details = ContentValues().apply {
                    put(
                        MediaStore.MediaColumns.DISPLAY_NAME,
                        it.getString(0)
                    )
                    put(
                        MediaStore.MediaColumns.RELATIVE_PATH,
                        dest
                    )
                    put(MediaStore.MediaColumns.IS_PENDING, 1)
                }

                val resultUri =
                    if (isImage) {
                        contentResolver.insert(
                            MediaStore.Images.Media.getContentUri(
                                volumeName!!
                            ), details
                        )
                    } else {
                        contentResolver.insert(
                            MediaStore.Video.Media.getContentUri(
                                volumeName!!
                            ), details
                        )
                    }

                if (resultUri == null) {
                    return@use
                }

                contentResolver.openOutputStream(resultUri)?.use { out ->
                    stream.transferTo(out)
                }

                details.clear()
                details.put(MediaStore.MediaColumns.IS_PENDING, 0)
                contentResolver.update(resultUri, details, null, null)
            }
        }
    }

    private fun constructRelPath(uri: Uri, isImage: Boolean): String? {
        val treePrimary = "/tree/primary:"
        if (uri.path!!.startsWith(treePrimary)) {
            val noTree = uri.path!!.substring(treePrimary.length)
            return if (noTree.startsWith(
                    if (isImage) {
                        "Pictures"
                    } else {
                        "Movies"
                    }
                )
            ) {
                noTree
            } else {
                null
            }
        } else {
            return null
        }
    }

    private fun copyOrMove(
        uris: List<Uri>,
        volumeName: String?,
        isImage: Boolean,
        newDir: Boolean,
        move: Boolean
    ) {
        if (move) {
            var dest = engineBindings.copyFiles!!.dest

            if (newDir) {
                val newDest = constructRelPath(Uri.parse(dest), isImage)
                if (newDest != null) {
                    dest = newDest
                } else {
                    for (e in uris) {
                        copyFile(
                            e,
                            newDir = true,
                            isImage = isImage,
                            volumeName = volumeName,
                            deleteAfter = true,
                            dest = dest
                        )
                    }
                    return
                }
            }

            val values = ContentValues()
            values.put(
                MediaStore.MediaColumns.RELATIVE_PATH,
                dest
            )

            for (e in uris) {
                contentResolver.update(
                    e,
                    values,
                    null,
                    null
                )
            }
        } else {
            for (e in uris) {
                copyFile(
                    e,
                    newDir = newDir,
                    isImage = isImage,
                    volumeName = volumeName,
                    deleteAfter = false,
                    dest = engineBindings.copyFiles!!.dest
                )
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == 1) {
            try {
                if (resultCode == Activity.RESULT_OK) {
                    engineBindings.callback?.invoke(
                        Pair(
                            data!!.data.toString(),
                            data.data!!.path!!.split(":").last()
                        )
                    )
                } else {
                    engineBindings.callback?.invoke(null)
                }
            } catch (e: java.lang.Exception) {
                Log.e("pick directory", e.toString())
            }

            engineBindings.callback = null
            if (engineBindings.callbackMux.isLocked) {
                engineBindings.callbackMux.unlock()
            }
        }

        if (requestCode == 99) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                engineBindings.manageMediaCallback!!(MediaStore.canManageMedia(context))
            } else {
                engineBindings.manageMediaCallback!!(false);
            }
            engineBindings.manageMediaCallback = null
            engineBindings.manageMediaMux.unlock()
        }

        if (requestCode == 9) {
            if (resultCode == Activity.RESULT_OK) {
                engineBindings.mover.notifyGallery()
            } else {
                Log.e("delete files", "failed")
            }
        }
        if (requestCode == 13 || requestCode == 14) {
            if (resultCode == Activity.RESULT_OK) {
                engineBindings.mover.notifyGallery()
            }
        }

        if (requestCode == 12) {
            if (resultCode == Activity.RESULT_OK) {
                CoroutineScope(lifecycleScope.coroutineContext + Dispatchers.IO).launch {
                    try {
                        FileSystem.SYSTEM.createDirectory(engineBindings.moveInternal!!.dest.toPath())

                        for (e in engineBindings.moveInternal!!.uris) {
                            copyFile(
                                e,
                                null,
                                newDir = true,
                                newDirIsLocal = true,
                                isImage = contentResolver.getType(e)!!.startsWith("image"),
                                dest = engineBindings.moveInternal!!.dest,
                                deleteAfter = true
                            )
                        }

                        engineBindings.moveInternal!!.callback(true)
                    } catch (e: Exception) {
                        engineBindings.moveInternal!!.callback(false)
                        Log.e("moveInternal_", e.toString())
                    }

                    engineBindings.moveInternal = null
                    engineBindings.moveInternalMux.unlock()
                }
            }
        }

        if (requestCode == 11) {
            if (resultCode == Activity.RESULT_OK) {
                CoroutineScope(lifecycleScope.coroutineContext + Dispatchers.IO).launch {
                    try {
                        val values = ContentValues()
                        values.put(
                            MediaStore.MediaColumns.DISPLAY_NAME,
                            engineBindings.rename!!.newName
                        )

                        contentResolver.update(
                            engineBindings.rename!!.uri,
                            values,
                            null,
                            null
                        )

                        if (engineBindings.rename!!.notify) {
                            engineBindings.mover.notifyGallery()
                        }
                    } catch (e: Exception) {
                        Log.e("rename_", e.toString())
                    }

                    engineBindings.rename = null
                    engineBindings.renameMux.unlock()
                }
            }
        }

        if (requestCode == 10) {
            if (resultCode == Activity.RESULT_OK) {
                CoroutineScope(lifecycleScope.coroutineContext + Dispatchers.IO).launch {
                    try {
                        if (engineBindings.copyFiles!!.images.isNotEmpty()) {
                            copyOrMove(
                                engineBindings.copyFiles!!.images,
                                isImage = true,
                                newDir = engineBindings.copyFiles!!.newDir,
                                volumeName = engineBindings.copyFiles!!.volumeName,
                                move = engineBindings.copyFiles!!.move
                            )
                        }

                        if (engineBindings.copyFiles!!.videos.isNotEmpty()) {
                            copyOrMove(
                                engineBindings.copyFiles!!.videos,
                                isImage = false,
                                newDir = engineBindings.copyFiles!!.newDir,
                                volumeName = engineBindings.copyFiles!!.volumeName,
                                move = engineBindings.copyFiles!!.move
                            )
                        }
                    } catch (e: java.lang.Exception) {
                        Log.e("copy files", e.toString())
                    }

                    engineBindings.copyFiles = null
                    engineBindings.mover.notifyGallery()
                    engineBindings.copyFilesMux.unlock()
                }
            } else {
                engineBindings.copyFiles = null
                engineBindings.copyFilesMux.unlock()
                Log.e("copy files", "failed")
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        engineBindings.attach()
        engineBindings.connectivityManager.registerDefaultNetworkCallback(engineBindings.netStatus)
    }

    override fun provideFlutterEngine(context: Context): FlutterEngine? {
        return engineBindings.engine
    }

    override fun onDestroy() {
        super.onDestroy()
        engineBindings.detach()
        engineBindings.connectivityManager.unregisterNetworkCallback(engineBindings.netStatus)
    }
}

class Manager(
    private val galleryApi: GalleryApi,
    private val context: FlutterActivity,
) : ConnectivityManager.NetworkCallback() {
    override fun onLost(network: Network) {
        context.runOnUiThread { galleryApi.notifyNetworkStatus(false) {} }
    }

    override fun onCapabilitiesChanged(network: Network, networkCapabilities: NetworkCapabilities) {
        val capInternet =
            networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
        val capValidated =
            networkCapabilities.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)

        if (capInternet and capValidated) {
            context.runOnUiThread {
                galleryApi.notifyNetworkStatus(true) {}
            }
        }
    }
}