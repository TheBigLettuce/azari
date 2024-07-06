// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package lol.bruh19.azari.gallery.enginebindings

import android.content.ContentResolver
import android.content.ContentValues
import android.content.Context
import android.net.Uri
import android.provider.MediaStore
import androidx.documentfile.provider.DocumentFile
import io.flutter.embedding.android.FlutterFragmentActivity
import okio.use
import java.io.File

fun copyFileInternal(
    contentResolver: ContentResolver,
    internalFile: String,
    volumeName: String?,
    dest: String,
    deleteAfter: Boolean,
    isImage: Boolean,
) {
    val file = File(internalFile)

    file.inputStream().use { stream ->
        val details = ContentValues().apply {
            put(
                MediaStore.MediaColumns.DISPLAY_NAME,
                file.name,
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

    if (deleteAfter) {
        file.delete()
    }
}

fun copyOrMove(
    context: FlutterFragmentActivity,
    uris: List<Uri>,
    volumeName: String?,
    isImage: Boolean,
    newDir: Boolean,
    move: Boolean,
    dest: String,
) {
    if (move) {
        var dest = dest

        if (newDir) {
            val newDest = constructRelPath(Uri.parse(dest), isImage)
            if (newDest != null) {
                dest = newDest
            } else {
                for (e in uris) {
                    copyFile(
                        context,
                        context.contentResolver,
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
            context.contentResolver.update(
                e,
                values,
                null,
                null
            )
        }
    } else {
        for (e in uris) {
            copyFile(
                context,
                context.contentResolver,
                e,
                newDir = newDir,
                isImage = isImage,
                volumeName = volumeName,
                deleteAfter = false,
                dest = dest
            )
        }
    }
}

internal fun copyFile(
    context: Context,
    contentResolver: ContentResolver,
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
                    val file = File(dest, it.getString(0))
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