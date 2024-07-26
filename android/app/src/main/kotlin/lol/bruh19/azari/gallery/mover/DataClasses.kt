// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package lol.bruh19.azari.gallery.mover

import android.net.Uri
import kotlinx.coroutines.CoroutineScope
import lol.bruh19.azari.gallery.generated.Directory
import lol.bruh19.azari.gallery.generated.DirectoryFile

typealias SendMedia = suspend (
    scope: CoroutineScope,
    uiScope: CoroutineScope,
    dir: String,
    time: Long,
    content: List<DirectoryFile>,
    notFound: List<Long>,
    empty: Boolean,
    inRefresh: Boolean
) -> Unit

typealias SendDirectories = suspend (
    scope: CoroutineScope,
    uiScope: CoroutineScope,
    dirs: Map<String, Directory>, inRefresh: Boolean,
    empty: Boolean,
) -> Boolean

data class FilesDest(
    val dest: String,
    val volumeName: String?,
    val images: List<Uri>,
    val videos: List<Uri>,
    val move: Boolean,
    val newDir: Boolean,
    val callback: (String?) -> Unit,
)

data class NetworkThumbOp(val url: String, val id: Long)
data class RenameOp(val uri: Uri, val newName: String, val notify: Boolean)
data class MoveInternalOp(val dest: String, val uris: List<Uri>, val callback: (Boolean) -> Unit)
data class MoveOp(val source: String, val rootUri: Uri, val dir: String)
data class ThumbOp(
    val thumb: Any,
    val saveToPinned: Boolean = false,
    val callback: ((String, Long) -> Unit)
)