// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package lol.bruh19.azari.gallery.mover

import android.content.Context
import android.util.Log
import kotlinx.coroutines.sync.Mutex
import java.io.ByteArrayOutputStream
import java.io.File

internal class CacheLocker(private val context: Context) {
    private val mux = Mutex()

    suspend fun put(image: ByteArrayOutputStream, id: Long, saveToPinned: Boolean): String? {
        mux.lock()

        var ret: String? = null

        val dir = if (saveToPinned) pinnedDirectoryFile() else directoryFile()
        val file = dir.resolve(id.toString())
        try {
            if (!file.exists()) {
                file.writeBytes(image.toByteArray())
            }
            ret = file.absolutePath
        } catch (e: Exception) {
            Log.e("CacheLocker.put", e.toString())
        }

        mux.unlock()

        return ret
    }

    suspend fun removeAll(ids: List<Long>, fromPinned: Boolean) {
        mux.lock()

        try {
            val dir = if (fromPinned) pinnedDirectoryFile() else directoryFile()

            for (id in ids) {
                dir.resolve(id.toString()).delete()
            }
        } catch (e: Exception) {
            Log.e("CacheLocker.remove", e.toString())
        }

        mux.unlock()
    }

    fun exist(id: Long): Boolean {
        return directoryFile().resolve(id.toString()).exists()
    }

    suspend fun clear(fromPinned: Boolean) {
        mux.lock()

        (if (fromPinned) pinnedDirectoryFile() else directoryFile()).deleteRecursively()

        mux.unlock()
    }

    private fun directoryFile(): File {
        val dir = context.filesDir.resolve(DIRECTORY)
        dir.mkdir()

        return dir
    }

    private fun pinnedDirectoryFile(): File {
        val dir = context.filesDir.resolve(PINNED_DIRECTORY)
        dir.mkdir()

        return dir
    }

    fun count(fromPinned: Boolean): Long {
        return (if (fromPinned) pinnedDirectoryFile() else directoryFile()).walk().sumOf { file ->
            return@sumOf file.length()
        }
    }

    companion object {
        private const val DIRECTORY = "thumbnailsCache"
        private const val PINNED_DIRECTORY = "pinnedThumbs"
    }
}