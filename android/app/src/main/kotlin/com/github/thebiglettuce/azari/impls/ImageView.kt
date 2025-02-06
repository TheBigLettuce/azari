// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

package com.github.thebiglettuce.azari.impls

import android.content.Context
import android.net.Uri
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.annotation.OptIn
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.isVisible
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.findViewTreeLifecycleOwner
import androidx.media3.common.C
import androidx.media3.common.MediaItem
import androidx.media3.common.MediaMetadata
import androidx.media3.common.Metadata
import androidx.media3.common.Player
import androidx.media3.common.Timeline
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.ListAdapter
import androidx.recyclerview.widget.RecyclerView.LayoutParams
import androidx.recyclerview.widget.RecyclerView.ViewHolder
import androidx.viewpager2.widget.ViewPager2
import coil3.load
import com.github.panpf.zoomimage.CoilZoomImageView
import com.github.panpf.zoomimage.ZoomImageView
import com.github.thebiglettuce.azari.R
import com.github.thebiglettuce.azari.generated.DirectoryFile
import com.github.thebiglettuce.azari.generated.FlutterGalleryData
import com.github.thebiglettuce.azari.generated.GalleryMetadata
import com.github.thebiglettuce.azari.generated.GalleryVideoEvents
import com.github.thebiglettuce.azari.generated.PlatformGalleryApi
import com.github.thebiglettuce.azari.generated.PlatformGalleryEvents
import com.github.thebiglettuce.azari.generated.VideoPlaybackState
import io.flutter.Log
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.Job
import kotlinx.coroutines.channels.ReceiveChannel
import kotlinx.coroutines.channels.produce
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.launch
import kotlinx.coroutines.selects.select
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import androidx.core.net.toUri

// Based on Lineage OS's Glimpse

class NativeViewFactory(
    private val data: FlutterGalleryData,
    private val galleryApi: PlatformGalleryApi,
    private val videoEvents: GalleryVideoEvents,
    private val metadataChangeEvents: StateFlow<Long>,
    private val pageChangeEvents: SharedFlow<Long>,
    private val playerButtonsEvents: SharedFlow<PlayerButtonEvents>,
) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return GalleryImpl(
            context,
            data,
            videoEvents,
            metadataChangeEvents,
            pageChangeEvents,
            playerButtonsEvents,
            galleryApi,
            args as Map<String, Any>
        )
    }
}

@kotlin.OptIn(ExperimentalCoroutinesApi::class)
internal class GalleryImpl(
    val context: Context,
    private val data: FlutterGalleryData,
    private val videoEvents: GalleryVideoEvents,
    private val metadataChangeEvents: StateFlow<Long>,
    private val pageChangeEvents: SharedFlow<Long>,
    private val playerButtonsEvents: SharedFlow<PlayerButtonEvents>,
    galleryApi: PlatformGalleryApi,
    params: Map<String, Any>,
) : PlatformView {

    private val playerEvents = @UnstableApi
    object : Player.Listener {
        override fun onVolumeChanged(volume: Float) {
            super.onVolumeChanged(volume)

            videoEvents.volumeEvent(volume.toDouble()) {

            }
        }

        override fun onPositionDiscontinuity(
            oldPosition: Player.PositionInfo,
            newPosition: Player.PositionInfo,
            reason: Int,
        ) {
            super.onPositionDiscontinuity(oldPosition, newPosition, reason)

            videoEvents.progressEvent(exoPlayer!!.currentPosition) {

            }
        }

        override fun onTimelineChanged(timeline: Timeline, reason: Int) {
            super.onTimelineChanged(timeline, reason)


            val duration = exoPlayer!!.duration
            if (duration >= 0L) {
                videoEvents.durationEvent(duration) {

                }
            }
        }

        override fun onIsPlayingChanged(isPlaying: Boolean) {
            super.onIsPlayingChanged(isPlaying)

            if (isPlaying) {
                watchPositionUpdates()
            } else {
                suspendPositionUpdates()
            }

            videoEvents.playbackStateEvent(
                when (isPlaying) {
                    true -> VideoPlaybackState.PLAYING
                    false -> VideoPlaybackState.STOPPED
                }
            ) {

            }
        }

        override fun onRepeatModeChanged(repeatMode: Int) {
            super.onRepeatModeChanged(repeatMode)

            videoEvents.loopingEvent(Player.REPEAT_MODE_ONE == repeatMode) {

            }
        }
    }

    private val exoPlayerLazy: Lazy<ExoPlayer> = lazy {
        ExoPlayer.Builder(context).build().apply {
            repeatMode = ExoPlayer.REPEAT_MODE_ONE
            volume = 0F
            addListener(playerEvents)

            data.initialVolume {
                exoPlayer?.volume = it.getOrNull()!!.toFloat()
            }
        }
    }

    private val pageChangesFlow = MutableLiveData(0)
    private val dataChangesFlow = MutableStateFlow<DirectoryFile?>(null)
    private var metadata: MutableStateFlow<GalleryMetadata?> = MutableStateFlow(null)
    private var pageViewer: ViewPager2? = ViewPager2(context)
    private val adapter =
        MediaPlayerAdapter(data, galleryApi, pageChangesFlow, dataChangesFlow, exoPlayerLazy)


    private val exoPlayer
        get() = if (exoPlayerLazy.isInitialized()) {
            exoPlayerLazy.value
        } else {
            null
        }

    private var lastVideoUriPlayed: Uri? = null

    private val pageChangeCallback = object : ViewPager2.OnPageChangeCallback() {
        override fun onPageSelected(position: Int) {
            super.onPageSelected(position)
            CoroutineScope(Dispatchers.Main).launch {
                data.setCurrentIndex(position.toLong()) {}
            }

            pageChangesFlow.value = position
        }
    }

    private val job: Job = CoroutineScope(Dispatchers.IO).launch {
        metadataChangeEvents.collect {
            CoroutineScope(Dispatchers.Main).launch {
                data.metadata { newMetadata ->
                    val metadataWasNull = metadata.value == null

                    metadata.value = newMetadata.getOrNull()!!
                    adapter.setMetadata(metadata.value!!)
                    if (metadataWasNull) {
                        val id = params["id"]!!

                        pageViewer?.setCurrentItem(
                            (if (id is Int) id else (id as Long).toInt()),
                            false
                        )
                    }
                }
            }
        }
    }

    private val pageChangeJob: Job = CoroutineScope(Dispatchers.IO).launch {
        pageChangeEvents.collect {
            CoroutineScope(Dispatchers.Main).launch {
                pageViewer?.setCurrentItem(it.toInt(), false)
            }
        }
    }

    private val playerButtonEventsJob = CoroutineScope(Dispatchers.IO).launch {
        playerButtonsEvents.collect {
            CoroutineScope(Dispatchers.Main).launch {
                when (it) {
                    is PlayerButtonEvents.Duration -> exoPlayer?.apply {
                        seekTo(currentPosition + it.d)
                    }

                    is PlayerButtonEvents.Play -> exoPlayer?.apply {
                        if (isPlaying && !isLoading) {
                            exoPlayer?.pause()
                        } else {
                            exoPlayer?.play()
                        }
                    }

                    is PlayerButtonEvents.Volume -> exoPlayer?.apply {
                        volume = if (it.v != null) {
                            it.v.toFloat()
                        } else {
                            if (volume != 0F) {
                                0F
                            } else {
                                1F
                            }
                        }
                    }

                    is PlayerButtonEvents.Looping -> exoPlayer?.apply {
                        repeatMode = if (repeatMode == Player.REPEAT_MODE_ONE) {
                            Player.REPEAT_MODE_OFF
                        } else {
                            Player.REPEAT_MODE_ONE
                        }
                    }
                }
            }
        }
    }

    private val dataChangeUpdatesJob = CoroutineScope(Dispatchers.IO).launch {
        dataChangesFlow.collect {
            CoroutineScope(Dispatchers.Main).launch {
                dataChangesFlow.value?.let {
                    updateExoPlayer(it)
                }
            }
        }
    }

    private var positionUpdater: ReceiveChannel<Long>? = null

    private fun updateExoPlayer(file: DirectoryFile) {
        if (file.isVideo) {
            val originalUri = file.originalUri.toUri()

            with(exoPlayerLazy.value) {
                if (originalUri != lastVideoUriPlayed) {
                    lastVideoUriPlayed = originalUri
                    setMediaItem(MediaItem.fromUri(originalUri))
                    seekTo(C.TIME_UNSET)
                    prepare()
                    playWhenReady = true
                }
            }
        } else {
            exoPlayer?.stop()

            lastVideoUriPlayed = null
        }
    }

    fun watchPositionUpdates() {
        positionUpdater?.cancel()
        positionUpdater = CoroutineScope(Dispatchers.IO).produce {
            while (true) {
                CoroutineScope(Dispatchers.Main).launch {
                    videoEvents.progressEvent(exoPlayer!!.currentPosition) {

                    }
                }
                delay(1.seconds)
            }
        }
    }

    fun suspendPositionUpdates() {
        positionUpdater?.cancel()
        positionUpdater = null
    }

    init {
        pageViewer?.adapter = adapter

        pageViewer?.apply {
            offscreenPageLimit = 2
            registerOnPageChangeCallback(pageChangeCallback)
        }
    }

    override fun getView(): View? = pageViewer

    override fun dispose() {
        job.cancel()
        pageChangeJob.cancel()
        playerButtonEventsJob.cancel()
        dataChangeUpdatesJob.cancel()

        suspendPositionUpdates()

        pageViewer?.unregisterOnPageChangeCallback(pageChangeCallback)
        pageViewer?.invalidate()
        pageViewer = null
        exoPlayer?.removeListener(playerEvents)
        exoPlayer?.release()
    }
}

class MediaPlayerAdapter(
    private val data: FlutterGalleryData,
    private val galleryApi: PlatformGalleryApi,
    private val pageChangeFlow: LiveData<Int>,
    private val dataChangesFlow: MutableStateFlow<DirectoryFile?>,
    private val exoPlayer: Lazy<ExoPlayer>,
) :
    ListAdapter<DirectoryFile, MediaPlayerAdapter.MediaPictureViewHolder>(DATA_TYPE_COMPARATOR) {
    private var metadata: GalleryMetadata? = null

    fun setMetadata(metadata: GalleryMetadata) {
        this.metadata = metadata
        notifyDataSetChanged()
    }

    override fun getItemCount(): Int {
        return metadata?.count?.toInt() ?: 0
    }

    override fun onBindViewHolder(holder: MediaPictureViewHolder, position: Int) {
        data.atIndex(position.toLong()) {
            holder.bind(it.getOrNull()!!)
        }
    }

    override fun onViewAttachedToWindow(holder: MediaPictureViewHolder) {
        super.onViewAttachedToWindow(holder)
        holder.onViewAttachedToWindow()
    }

    override fun onViewDetachedFromWindow(holder: MediaPictureViewHolder) {
        super.onViewDetachedFromWindow(holder)
        holder.onViewDetachedFromWindow()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): MediaPictureViewHolder {
        return MediaPictureViewHolder(
            LayoutInflater.from(parent.context).inflate(R.layout.view_layout, parent, false),
            galleryApi,
            pageChangeFlow,
            dataChangesFlow,
            exoPlayer,
        )
    }

    class MediaPictureViewHolder(
        private val view: View,
        private val galleryApi: PlatformGalleryApi,
        private val pageChangeFlow: LiveData<Int>,
        private val dataChangesFlow: MutableStateFlow<DirectoryFile?>,
        private val exoPlayer: Lazy<ExoPlayer>,
    ) : ViewHolder(view) {
        private var isCurrentlyDisplayedView = false
        private val pageDataFlow = MutableStateFlow<DirectoryFile?>(null)

        private val onClickCallback = View.OnClickListener {
            CoroutineScope(Dispatchers.Main).launch {
                galleryApi.galleryTapDownEvent {
                }
            }
        }

        private val imageView = view.findViewById<ZoomImageView>(R.id.imageView).apply {
            setOnClickListener(onClickCallback)
        }
        private val playerView = view.findViewById<PlayerView>(R.id.playerView).apply {
            setOnClickListener(onClickCallback)
        }

        @OptIn(UnstableApi::class)
        private val mediaPositionObserver: (Int) -> Unit = { currentPosition: Int ->
            CoroutineScope(Dispatchers.Main).launch {
                isCurrentlyDisplayedView = currentPosition == bindingAdapterPosition

                val file = when (pageDataFlow.value == null) {
                    true -> pageDataFlow.first { it != null }!!
                    false -> pageDataFlow.value!!
                }

                if (isCurrentlyDisplayedView) {
                    dataChangesFlow.value = file
                }

                val isNowVideoPlayer =
                    isCurrentlyDisplayedView && file.isVideo

                imageView.isVisible = !isNowVideoPlayer
                playerView.isVisible = isNowVideoPlayer

                val player = when (isNowVideoPlayer) {
                    true -> exoPlayer.value
                    false -> null
                }

                playerView.player = player
            }
        }


        fun bind(file: DirectoryFile) {
            this.pageDataFlow.value = file

            imageView.load(file.originalUri) {
                memoryCacheKey("full_${file.id}")
                placeholderMemoryCacheKey("thumbnail_${file.id}")
            }
        }

        @OptIn(UnstableApi::class)
        fun onViewAttachedToWindow() {
            view.findViewTreeLifecycleOwner()?.let {
                pageChangeFlow.observe(it, mediaPositionObserver)
            }
        }

        @OptIn(UnstableApi::class)
        fun onViewDetachedFromWindow() {
            pageChangeFlow.removeObserver(mediaPositionObserver)
        }

        private fun updateDisplayedMedia() {
            if (isCurrentlyDisplayedView) {
                dataChangesFlow.value = pageDataFlow.value
            }
        }
    }

    companion object {
        val DATA_TYPE_COMPARATOR = object : DiffUtil.ItemCallback<DirectoryFile>() {
            override fun areItemsTheSame(oldItem: DirectoryFile, newItem: DirectoryFile) =
                oldItem.id == newItem.id

            override fun areContentsTheSame(oldItem: DirectoryFile, newItem: DirectoryFile) =
                oldItem.id == newItem.id &&
                        oldItem.lastModified == newItem.lastModified
        }
    }
}

class GalleryEventsImpl() : PlatformGalleryEvents {
    val events: MutableStateFlow<Long> = MutableStateFlow(0)
    val pageChangeEvents: MutableSharedFlow<Long> = MutableSharedFlow()
    val playerButtonsEvents: MutableSharedFlow<PlayerButtonEvents> = MutableSharedFlow()

    override fun metadataChanged() {
        events.value += 1
    }

    override fun seekToIndex(i: Long) {
        CoroutineScope(Dispatchers.IO).launch {
            pageChangeEvents.emit(i)
        }
    }

    override fun volumeButtonPressed(volume: Double?) {
        CoroutineScope(Dispatchers.IO).launch {
            playerButtonsEvents.emit(PlayerButtonEvents.Volume(volume))
        }
    }

    override fun playButtonPressed() {
        CoroutineScope(Dispatchers.IO).launch {
            playerButtonsEvents.emit(PlayerButtonEvents.Play)
        }
    }

    override fun loopingButtonPressed() {
        CoroutineScope(Dispatchers.IO).launch {
            playerButtonsEvents.emit(PlayerButtonEvents.Looping)
        }
    }

    override fun durationChanged(d: Long) {
        CoroutineScope(Dispatchers.IO).launch {
            playerButtonsEvents.emit(PlayerButtonEvents.Duration(d))
        }
    }

}

sealed interface PlayerButtonEvents {
    data object Play : PlayerButtonEvents
    data object Looping : PlayerButtonEvents
    data class Volume(val v: Double?) : PlayerButtonEvents
    data class Duration(val d: Long) : PlayerButtonEvents
}
