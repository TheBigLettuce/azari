// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package com.github.thebiglettuce.azari

import android.Manifest
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import com.github.thebiglettuce.azari.generated.Notification
import com.github.thebiglettuce.azari.generated.NotificationChannel
import com.github.thebiglettuce.azari.generated.NotificationGroup
import com.github.thebiglettuce.azari.generated.NotificationsApi

class CurrentNotificationsHolder(private val manager: NotificationManager) {
    private val pendingNotifications: MutableMap<Int, Unit> = mutableMapOf()

    fun add(id: Int) {
        pendingNotifications[id] = Unit
    }

    fun remove(id: Int) {
        pendingNotifications.remove(id)
    }

    fun cancelAll() {
        for (n in pendingNotifications.keys) {
            manager.cancel(n)
        }

        removeGroupNotifIfNeeded(NotificationGroup.MISC)
        removeGroupNotifIfNeeded(NotificationGroup.DOWNLOADER)

        pendingNotifications.clear()
    }

    private fun removeGroupNotifIfNeeded(group: NotificationGroup) {
        val groupNotifId = group.groupNotifId()

        var haveNotificationsAfterDelete = false
        for (an in manager.activeNotifications) {
            if (!pendingNotifications.containsKey(an.id) && an.id != groupNotifId) {
                haveNotificationsAfterDelete = true
                break
            }
        }

        if (!haveNotificationsAfterDelete) {
            manager.cancel(groupNotifId)
        }
    }
}

class NotificationsApiImpl(
    private val context: Context,
    private val manager: NotificationManager,
    private val currentNotifications: CurrentNotificationsHolder,
) :
    NotificationsApi {
    override fun post(
        channel: NotificationChannel,
        notif: Notification,
        callback: (Result<Unit>) -> Unit,
    ) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
                callback(Result.success(Unit))
                return
            }
        }

        var n = android.app.Notification.Builder(context, channel.id())
            .setProgress(
                notif.maxProgress.toInt(),
                notif.currentProgress.toInt(),
                notif.indeterminate
            )
            .setOngoing(true)
            .setGroup(notif.group.id())
            .setContentTitle(notif.title)
            .setVisibility(android.app.Notification.VISIBILITY_PRIVATE)
            .setSmallIcon(R.drawable.ic_notification)
            .setCategory(android.app.Notification.CATEGORY_PROGRESS)

        val activeNotifications = manager.activeNotifications
        var createGroup = true
        for (an in activeNotifications) {
            if (notif.group.id() == an.groupKey) {
                createGroup = false
                break
            }
        }

        if (createGroup) {
            manager.notify(
                notif.group.groupNotifId(),
                android.app.Notification.Builder(context, channel.id())
                    .setContentTitle("")
                    .setSmallIcon(R.drawable.ic_notification)
                    .setGroup(notif.group.id())
                    .setGroupSummary(true)
                    .build(),
            )
        }

        if (notif.body != null) {
            n = n.setContentText(notif.body)
        }

        manager.notify(
            notif.id.toInt(),
            n.build()
        )

        currentNotifications.add(notif.id.toInt())
        callback(Result.success(Unit))
    }

    override fun cancel(
        id: Long,
        callback: (Result<Unit>) -> Unit,
    ) {
        val n = manager.activeNotifications.find { it.id == id.toInt() }
        currentNotifications.remove(id.toInt())
        if (n == null) {
            callback(Result.success(Unit))
            return
        }

        val groupNotifId = groupIdToNotifId(n.notification.group)

        manager.cancel(id.toInt())

        var deleteGroup = true
        for (an in manager.activeNotifications) {
            if (an.id != n.id && an.id != groupNotifId && n.groupKey == an.groupKey) {
                deleteGroup = false
                break
            }
        }

        if (deleteGroup) {
            manager.cancel(groupNotifId)
        }

        callback(Result.success(Unit))
    }
}

fun NotificationGroup.id(): String {
    return when (this) {
        NotificationGroup.MISC -> "misc"
        NotificationGroup.DOWNLOADER -> "downloader"
    }
}

fun groupIdToNotifId(id: String): Int {
    return when (id) {
        "misc" -> NotificationGroup.MISC.groupNotifId()
        "downloader" -> NotificationGroup.DOWNLOADER.groupNotifId()
        else -> throw Exception("unknown group id: $id")
    }
}

fun NotificationGroup.groupNotifId(): Int {
    return when (this) {
        NotificationGroup.MISC -> -10000
        NotificationGroup.DOWNLOADER -> -10001
    }
}

fun NotificationChannel.id(): String {
    return when (this) {
        NotificationChannel.MISC -> "misc"
        NotificationChannel.DOWNLOADER -> "downloader"
    }
}
