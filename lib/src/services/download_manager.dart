// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "services.dart";

mixin class DownloadManager implements ServiceMarker {
  const DownloadManager();

  static bool get available => _instance != null;
  static DownloadManager? safe() => _instance;

  // ignore: unnecessary_late
  static late final _instance = _dbInstance.get<DownloadManager>();

  SourceStorage<String, DownloadHandle> get storage => _instance!.storage;
  ResourceSource<String, DownloadHandle> get source => _instance!.source;

  Dio get client => _instance!.client;
  String get downloadDir => _instance!.downloadDir;

  void restoreFile(DownloadFileData f) => _instance!.restoreFile(f);

  void addLocalTags(Iterable<DownloadEntryTags> downloads) =>
      _instance!.addLocalTags(downloads);

  void restartAll(Iterable<DownloadHandle> d) => _instance!.restartAll(d);
  void putAll(Iterable<DownloadEntry> downloads) =>
      _instance!.putAll(downloads);

  DownloadHandle? statusFor(String url) => _instance!.statusFor(url);
}

mixin DefaultDownloadManagerImpl on MapStorage<String, DownloadHandle>
    implements DownloadManager, ResourceSource<String, DownloadHandle> {
  FilesApi? get files;

  static final _log = Logger("Download Manager");
  static const int maximum = 6;

  // int _notificationId = 0;

  int _inWork = 0;
  int get inWork => _inWork;

  @override
  SourceStorage<String, DownloadHandle> get storage => this;

  @override
  ResourceSource<String, DownloadHandle> get source => this;

  @override
  void clear([bool silent = false]) {
    if (this is DownloadManagerHasPersistence) {
      (this as DownloadManagerHasPersistence).db.clear();
    }
    super.clear(silent);
  }

  @override
  List<DownloadHandle> removeAll(Iterable<String> idx, [bool silent = false]) {
    final idx_ = idx.toList();

    if (this is DownloadManagerHasPersistence) {
      (this as DownloadManagerHasPersistence).db.deleteAll(idx_);
    }

    final removed = <DownloadHandle>[];

    for (final key in idx_) {
      final e = map_.remove(key);
      if (e != null) {
        e.cancel();
        e.watcher?.close();
        removed.add(e);
      }
    }

    if (!silent) {
      addAll([]);
    }

    return removed;
  }

  @override
  void addLocalTags(Iterable<DownloadEntryTags> downloads) {
    final localTags = LocalTagsService.safe();
    if (localTags == null) {
      return;
    }

    for (final e in downloads) {
      localTags.addTagsPost(e.name, e.tags, true);
    }

    putAll(downloads);
  }

  @override
  void restartAll(Iterable<DownloadHandle> d) {
    if (const SettingsService().current.path.isEmpty) {
      return;
    }

    for (final e in d) {
      final ee1 = map_[e.key];
      if (ee1 != null && ee1.data.status != DownloadStatus.inProgress) {
        if (_inWork > maximum) {
          map_[e.key] = DownloadHandle(
            data: ee1.data._copyStatus(DownloadStatus.onHold),
            token: ee1.token,
            watcher: ee1.watcher,
          );
          continue;
        } else {
          map_[e.key] = DownloadHandle(
            data: ee1.data._copyStatus(DownloadStatus.inProgress),
            token: ee1.token,
            watcher: ee1.watcher,
          );

          _inWork += 1;

          _download(e.key);
        }
      }
    }

    addAll([]);
  }

  @override
  DownloadHandle? statusFor(String d) => map_[d];

  @override
  void putAll(Iterable<DownloadEntry> downloads) {
    if (const SettingsService().current.path.isEmpty) {
      return;
    }

    final toDownload = downloads
        .skipWhile((element) => map_.containsKey(element.url))
        .toList();
    if (downloads.isEmpty) {
      return;
    }

    final List<DownloadFileData> toSaveDb = [];

    for (final e in toDownload) {
      if (_inWork > maximum) {
        final hold = e._copyStatus(DownloadStatus.onHold);

        map_[e.url] = DownloadHandle(data: hold, token: CancelToken());
        toSaveDb.add(hold._toDb());
      } else {
        map_[e.url] = DownloadHandle(data: e, token: CancelToken());
        toSaveDb.add(e._toDb());

        _inWork += 1;

        _download(e.url);
      }
    }

    if (this is DownloadManagerHasPersistence) {
      (this as DownloadManagerHasPersistence).db.saveAll(toSaveDb);
    }
    addAll([]);
  }

  void _tryAddNew() {
    final newAdd = maximum - _inWork;
    if (newAdd.isNegative || newAdd == 0) {
      return;
    }

    final entries = map_.values
        .where((element) => element.data.status == DownloadStatus.onHold)
        .take(newAdd)
        .map(
          (e) => DownloadHandle(
            data: e.data._copyStatus(DownloadStatus.inProgress),
            token: CancelToken(),
            watcher: e.watcher,
          ),
        )
        .toList();

    if (entries.isEmpty) {
      return;
    }

    _inWork += entries.length;

    for (final e in entries) {
      map_[e.key] = e;
    }

    if (this is DownloadManagerHasPersistence) {
      (this as DownloadManagerHasPersistence).db.saveAll(
        entries.map((e) => e.data._toDb()).toList(),
      );
    }

    for (final e in entries) {
      _download(e.key);
    }
  }

  void _downloadProgress(
    String url,
    NotificationHandle notif,
    DownloadHandle handle, {
    required int count,
    required int total,
  }) {
    if (count == total || !map_.containsKey(url)) {
      notif.done();
      return;
    }

    notif.setTotal(total);
    notif.update(count);
    if (count != 0 && total.isFinite) {
      handle._downloadProgress = count / total;
      handle.watcher?.add(handle._downloadProgress);
    }
  }

  void _remove(String url) {
    final e = map_.remove(url);
    if (e != null) {
      e.cancel();
      e.watcher?.close();
      if (this is DownloadManagerHasPersistence) {
        (this as DownloadManagerHasPersistence).db.deleteAll([url]);
      }
    }
  }

  void _complete(String url) {
    StatisticsBooruService.addDownloaded(1);
    _remove(url);
    _inWork -= 1;
    addAll([]);
  }

  void _failed(DownloadHandle entry) {
    final newEntry = entry.data._copyStatus(DownloadStatus.failed);

    _inWork -= 1;

    if (this is DownloadManagerHasPersistence) {
      (this as DownloadManagerHasPersistence).db.saveAll([newEntry._toDb()]);
    }

    map_[entry.key] = DownloadHandle(
      data: newEntry,
      token: CancelToken(),
      watcher: entry.watcher,
    );

    addAll([]);
  }

  Future<void> _download(String url) async {
    if (files == null) {
      return Future.value();
    }

    final entry = map_[url]!;

    final dir = await ensureDownloadDirExists(
      dir: downloadDir,
      site: entry.data.site,
    );
    final filePath = path.joinAll([dir, entry.data.name]);

    if (await files!.exists(filePath)) {
      _failed(entry);
      _tryAddNew();
      return;
    }

    final progress = await const NotificationApi().show(
      id: const NotificationChannels().downloadId(),
      title: entry.data.name,
      channel: platform.NotificationChannel.downloader,
      group: platform.NotificationGroup.downloader,
      body: entry.data.site,
      payload: "downloads",
    );

    try {
      _log.info("Started download: ${entry.data}");

      await client.download(
        entry.data.url,
        filePath,
        cancelToken: entry.token,
        onReceiveProgress: progress != null
            ? (count, total) => _downloadProgress(
                url,
                progress,
                entry,
                count: count,
                total: total,
              )
            : null,
      );

      await _moveDownloadedFile(entry, filePath: filePath);

      _complete(entry.key);
      progress?.done();
    } catch (e, trace) {
      _log.warning(
        "writting downloaded file ${entry.data.name} to uri",
        e,
        trace,
      );

      progress?.done();
      _failed(entry);
    }

    _tryAddNew();
  }

  Future<void> _moveDownloadedFile(
    DownloadHandle entry, {
    required String filePath,
  }) async {
    if (files == null) {
      return Future.value();
    }

    if (entry.data.thenMoveTo != null) {
      await files!.copyMoveInternal(
        relativePath: entry.data.thenMoveTo!.path,
        volume: entry.data.thenMoveTo!.volume,
        dirName: entry.data.thenMoveTo!.dirName,
        internalPaths: [filePath],
      );
    } else {
      await files!.moveSingle(
        source: filePath,
        rootDir: const SettingsService().current.path.path,
        targetDir: entry.data.site,
      );
    }
  }

  Future<String> ensureDownloadDirExists({
    required String dir,
    required String site,
  });
}

class DownloadHandle
    with DefaultBuildCell, CellBuilderData
    implements CellBuilder {
  DownloadHandle({required this.data, required this.token, this.watcher});

  StreamController<double>? watcher;

  double _downloadProgress = 0;
  double get downloadProgress => _downloadProgress;
  set downloadProgress(double i) {
    _downloadProgress = i;

    watcher?.sink.add(i);
  }

  final DownloadEntry data;

  String get key => data.url;

  final CancelToken token;

  void cancel() => token.cancel();

  @override
  Widget buildCell(
    AppLocalizations l10n, {
    required CellType cellType,
    required bool hideName,
    Alignment imageAlign = Alignment.center,
  }) => WrapSelection(
    onPressed: null,
    child: super.buildCell(
      l10n,
      cellType: cellType,
      hideName: hideName,
      imageAlign: imageAlign,
    ),
  );

  @override
  ImageProvider<Object> thumbnail() =>
      CachedNetworkImageProvider(data.thumbUrl);

  @override
  String title(AppLocalizations l10n) => data.name;

  @override
  Key uniqueKey() => ValueKey(data.url);

  StreamSubscription<double> watchProgress(PercentageCallback f) {
    watcher ??= StreamController.broadcast();

    return watcher!.stream.listen(f);
  }
}

class DownloadEntryTags extends DownloadEntry {
  const DownloadEntryTags.d({
    required this.tags,
    required super.name,
    required super.url,
    required super.thumbUrl,
    required super.site,
    super.status,
    required super.thenMoveTo,
  }) : super.d();

  final List<String> tags;
}

class DownloadEntry {
  const DownloadEntry._({
    required this.name,
    required this.url,
    required this.thumbUrl,
    required this.site,
    required this.status,
    required this.thenMoveTo,
  });

  const DownloadEntry.d({
    required this.name,
    required this.url,
    required this.thumbUrl,
    required this.site,
    required this.thenMoveTo,
    this.status = DownloadStatus.inProgress,
  });

  final String name;
  final String url;
  final String thumbUrl;
  final String site;
  final PathVolume? thenMoveTo;

  final DownloadStatus status;

  DownloadEntry _copyStatus(DownloadStatus newStatus) => DownloadEntry._(
    name: name,
    url: url,
    thumbUrl: thumbUrl,
    site: site,
    status: newStatus,
    thenMoveTo: thenMoveTo,
  );

  DownloadFileData _toDb() => DownloadFileData(
    status: status,
    name: name,
    url: url,
    thumbUrl: thumbUrl,
    site: site,
    date: DateTime.now(),
  );

  @override
  String toString() {
    return "DownloadEntry(name: $name)";
  }
}

class LinearDownloadIndicator extends StatefulWidget {
  const LinearDownloadIndicator({super.key, required this.post});

  final PostImpl post;

  @override
  State<LinearDownloadIndicator> createState() =>
      _LinearDownloadIndicatorState();
}

class _LinearDownloadIndicatorState extends State<LinearDownloadIndicator>
    with DownloadManager {
  late final StreamSubscription<void> events;
  DownloadHandle? status;

  @override
  void initState() {
    events = storage.watch((_) {
      setState(() {
        status = statusFor(widget.post.fileDownloadUrl());
      });
    }, true);

    super.initState();
  }

  @override
  void dispose() {
    events.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return status == null || status!.data.status == DownloadStatus.failed
        ? const SizedBox.shrink()
        : _LinearProgress(handle: status!);
  }
}

class _LinearProgress extends StatefulWidget {
  const _LinearProgress({
    // super.key,
    required this.handle,
  });

  final DownloadHandle handle;

  @override
  State<_LinearProgress> createState() => __LinearProgressState();
}

class __LinearProgressState extends State<_LinearProgress> {
  late final StreamSubscription<void> subscription;

  double? progress;

  @override
  void initState() {
    super.initState();

    subscription = widget.handle.watchProgress((i) {
      setState(() {
        progress = i;
      });
    });
  }

  @override
  void dispose() {
    subscription.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Animate(
      autoPlay: true,
      effects: const [
        FadeEffect(
          duration: Durations.medium4,
          curve: Easing.standard,
          begin: 0,
          end: 1,
        ),
      ],
      child: LinearProgressIndicator(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        minHeight: 2,
        value: progress,
      ),
    );
  }
}
