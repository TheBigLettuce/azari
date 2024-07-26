// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package lol.bruh19.azari.gallery

import android.app.Activity
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.MediaStore
import android.provider.Settings
import android.util.Log
import androidx.activity.result.contract.ActivityResultContract
import androidx.activity.result.contract.ActivityResultContracts
import io.flutter.embedding.android.FlutterFragmentActivity
import kotlinx.coroutines.launch
import lol.bruh19.azari.gallery.enginebindings.ActivityContextChannel
import lol.bruh19.azari.gallery.enginebindings.AppContextChannel
import lol.bruh19.azari.gallery.enginebindings.copyFile
import lol.bruh19.azari.gallery.enginebindings.copyOrMove
import lol.bruh19.azari.gallery.mover.MediaLoaderAndMover
import okio.FileSystem
import okio.Path.Companion.toPath

class ActivityResultIntents(
    context: FlutterFragmentActivity,
    private val getActivityContextChannel: () -> ActivityContextChannel,
    private val getMediaLoaderAndMover: () -> MediaLoaderAndMover,
) {
    val pickFileAndOpen = context.registerForActivityResult(ActionOpenDocument()) { data ->
        val activityContextChannel = getActivityContextChannel()

        onOpenDocument(data, activityContextChannel)
    }

    val chooseDirectory = context.registerForActivityResult(ActionOpenDocumentTree()) { data ->
        val activityContextChannel = getActivityContextChannel()

        onOpenDocument(data, activityContextChannel)
    }

    val manageMedia = context.registerForActivityResult(ManageMedia()) { data ->
        val engineBindings = getActivityContextChannel()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            engineBindings.manageMediaCallback!!(MediaStore.canManageMedia(context))
        } else {
            engineBindings.manageMediaCallback!!(false);
        }
        engineBindings.manageMediaCallback = null
        engineBindings.manageMediaMux.unlock()
    }

    val writeRequest =
        context.registerForActivityResult(ActivityResultContracts.StartIntentSenderForResult()) { data ->
            val activityContextChannel = getActivityContextChannel()
            val mover = getMediaLoaderAndMover()

            if (data.resultCode == Activity.RESULT_OK) {
                val rename = activityContextChannel.rename!!
                activityContextChannel.rename = null

                mover.scope.launch {
                    try {
                        val values = ContentValues()
                        values.put(
                            MediaStore.MediaColumns.DISPLAY_NAME,
                            rename.newName
                        )

                        context.contentResolver.update(
                            rename.uri,
                            values,
                            null,
                            null
                        )

                        if (rename.notify) {
                            activityContextChannel.notifyGallery(mover.uiScope, null)
                        }
                    } catch (e: Exception) {
                        Log.e("rename_", e.toString())
                    }

                    activityContextChannel.renameMux.unlock()
                }
            }
        }

    val writeRequestCopyMove =
        context.registerForActivityResult(ActivityResultContracts.StartIntentSenderForResult()) { data ->
            val activityContextChannel = getActivityContextChannel()
            val mover = getMediaLoaderAndMover()

            if (data.resultCode == Activity.RESULT_OK) {
                val copyFiles = activityContextChannel.copyFiles!!
                activityContextChannel.copyFiles = null

                mover.scope.launch {
                    try {
                        if (copyFiles.images.isNotEmpty()) {
                            copyOrMove(
                                context,
                                copyFiles.images,
                                isImage = true,
                                newDir = copyFiles.newDir,
                                volumeName = copyFiles.volumeName,
                                move = copyFiles.move,
                                dest = copyFiles.dest,
                            )
                        }

                        if (copyFiles.videos.isNotEmpty()) {
                            copyOrMove(
                                context,
                                copyFiles.videos,
                                isImage = false,
                                newDir = copyFiles.newDir,
                                volumeName = copyFiles.volumeName,
                                move = copyFiles.move,
                                dest = copyFiles.dest,
                            )
                        }

                        copyFiles.callback(null);
                    } catch (e: java.lang.Exception) {
                        copyFiles.callback(e.message);
                        Log.e("copy files", e.toString())
                    }

                    activityContextChannel.notifyGallery(mover.uiScope, null)
                    activityContextChannel.copyFilesMux.unlock()
                }
            } else {
                activityContextChannel.copyFiles!!.callback(data.toString());
                activityContextChannel.copyFiles = null
                activityContextChannel.copyFilesMux.unlock()
                Log.e("copy files", "failed")
            }
        }

    val writeRequestInternal =
        context.registerForActivityResult(ActivityResultContracts.StartIntentSenderForResult()) { data ->
            val activityContextChannel = getActivityContextChannel()
            val mover = getMediaLoaderAndMover()

            if (data.resultCode == Activity.RESULT_OK) {
                val moveInternal = activityContextChannel.moveInternal!!
                activityContextChannel.moveInternal = null

                mover.scope.launch {
                    try {
                        FileSystem.SYSTEM.createDirectory(moveInternal.dest.toPath())

                        for (e in moveInternal.uris) {
                            copyFile(
                                context,
                                context.contentResolver,
                                e,
                                null,
                                newDir = true,
                                newDirIsLocal = true,
                                isImage = context.contentResolver.getType(e)!!.startsWith("image"),
                                dest = moveInternal.dest,
                                deleteAfter = true
                            )
                        }

                        moveInternal.callback(true)
                    } catch (e: Exception) {
                        moveInternal.callback(false)
                        Log.e("moveInternal_", e.toString())
                    }

                    activityContextChannel.moveInternalMux.unlock()
                }
            } else {
                activityContextChannel.moveInternal = null
                activityContextChannel.moveInternalMux.unlock()
            }
        }

    val trashRequest =
        context.registerForActivityResult(ActivityResultContracts.StartIntentSenderForResult()) { data ->
            val activityContextChannel = getActivityContextChannel()
            val mover = getMediaLoaderAndMover()

            if (data.resultCode == Activity.RESULT_OK) {
                activityContextChannel.notifyGallery(mover.uiScope, null)
            }
        }

    val deleteRequest =
        context.registerForActivityResult(ActivityResultContracts.StartIntentSenderForResult()) { data ->
            val activityContextChannel = getActivityContextChannel()
            val mover = getMediaLoaderAndMover()

            if (data.resultCode == Activity.RESULT_OK) {
                activityContextChannel.notifyGallery(mover.uiScope, null)
            }
        }

    fun unregisterAll() {
        deleteRequest.unregister()
        trashRequest.unregister()
        writeRequestInternal.unregister()
        writeRequestCopyMove.unregister()
        writeRequest.unregister()
        manageMedia.unregister()
        pickFileAndOpen.unregister()
        chooseDirectory.unregister()
    }

    private fun onOpenDocument(data: Uri?, activityContextChannel: ActivityContextChannel) {
        try {
            activityContextChannel.callback?.invoke(data.run {
                if (this == null) {
                    null
                } else {
                    Pair(
                        toString(),
                        path!!.split(":").last()
                    )
                }
            })
        } catch (e: java.lang.Exception) {
            Log.e("pick directory", e.toString())
        }

        activityContextChannel.callback = null
        if (activityContextChannel.callbackMux.isLocked) {
            activityContextChannel.callbackMux.unlock()
        }
    }
}

class ManageMedia : ActivityResultContract<String, Unit>() {
    override fun createIntent(context: Context, input: String): Intent {
        val intent =
            Intent(Settings.ACTION_REQUEST_MANAGE_MEDIA)
        intent.data = Uri.parse("package:${input}")

        return intent;
    }

    override fun parseResult(resultCode: Int, intent: Intent?) = Unit
}

class ActionOpenDocument : ActivityResultContracts.OpenDocument() {
    override fun createIntent(context: Context, input: Array<String>): Intent {
        return super.createIntent(context, input)
            .addCategory(Intent.CATEGORY_OPENABLE)
    }
}

class ActionOpenDocumentTree : ActivityResultContract<Pair<Boolean, Uri?>, Uri?>() {
    override fun createIntent(context: Context, input: Pair<Boolean, Uri?>): Intent {
        val i = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)

        if (input.first) {
            i.addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION
            )
        } else {
            i.addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                        Intent.FLAG_GRANT_WRITE_URI_PERMISSION or Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                        Intent.FLAG_GRANT_PREFIX_URI_PERMISSION
            )
        }

        return i
    }

    override fun getSynchronousResult(
        context: Context,
        input: Pair<Boolean, Uri?>,
    ): SynchronousResult<Uri?>? =
        null

    override fun parseResult(resultCode: Int, intent: Intent?): Uri? =
        intent.takeIf { resultCode == Activity.RESULT_OK }?.data
}