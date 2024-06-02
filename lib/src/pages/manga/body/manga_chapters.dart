// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/manga/manga_api.dart";
import "package:gallery/src/pages/manga/body/chapter_tile.dart";
import "package:gallery/src/pages/more/settings/settings_label.dart";
import "package:gallery/src/widgets/empty_widget.dart";

part "chapter_body.dart";

class MangaChapters extends StatefulWidget {
  const MangaChapters({
    super.key,
    required this.entry,
    required this.api,
    required this.scrollController,
    required this.db,
  });

  final MangaEntry entry;
  final MangaAPI api;
  final ScrollController scrollController;

  final DbConn db;

  @override
  State<MangaChapters> createState() => _MangaChaptersState();
}

class _MangaChaptersState extends State<MangaChapters> {
  ReadMangaChaptersService get readChapters => widget.db.readMangaChapters;
  SavedMangaChaptersService get savedChapters => widget.db.savedMangaChapters;
  ChaptersSettingsService get chapterSettings => widget.db.chaptersSettings;

  late final StreamSubscription<ChaptersSettingsData?> watcher;
  late ChaptersSettingsData settings = chapterSettings.current;

  final List<(List<MangaChapter>, String)> list = [];

  Future<List<(List<MangaChapter>, String)>>? _future;
  Future<List<(List<MangaChapter>, String)>>? _future2;

  bool reachedEnd = false;
  int page = 0;

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    watcher = chapterSettings.watch((c) {
      settings = c!;

      reloadChapters();

      setState(() {});
    });

    if (savedChapters.count(
          widget.entry.id.toString(),
          widget.entry.site,
        ) !=
        0) {
      _future = () async {
        final chpt = savedChapters.get(
          widget.entry.id.toString(),
          widget.entry.site,
          settings,
          readChapters,
        );

        if (chpt == null) {
          return list;
        }

        page = chpt.$2;
        list.addAll(chpt.$1.splitVolumes(widget.entry.id.toString(), settings));

        return list;
      }()
          .whenComplete(() {
        _future = null;

        setState(() {});
      });
    } else {
      _loadChapters(false);
    }
  }

  void reloadChapters() {
    final chpt = savedChapters.get(
      widget.entry.id.toString(),
      widget.entry.site,
      settings,
      readChapters,
    );

    if (chpt != null) {
      list.clear();
      list.addAll(chpt.$1.splitVolumes(widget.entry.id.toString(), settings));

      page = chpt.$2;
    }
  }

  void _onFinishRead() {
    _future2 = () async {
      reloadChapters();

      return list;
    }()
        .whenComplete(() {
      _future2 = null;

      setState(() {});
    });

    setState(() {});
  }

  void _loadNextChapters() {
    _future2 = widget.api
        .chapters(widget.entry.id, page: page, order: MangaChapterOrder.asc)
        .then((value) {
      list.addAll(value.splitVolumes(widget.entry.id.toString(), settings));

      page += 1;
      if (value.isEmpty) {
        reachedEnd = true;
      } else {
        savedChapters.add(
          widget.entry.id.toString(),
          widget.entry.site,
          value,
          page,
        );
      }

      _future2 = null;

      setState(() {});

      return list;
    });

    setState(() {});
  }

  void _loadChapters([bool sets = true]) {
    _future = widget.api
        .chapters(widget.entry.id, page: page, order: MangaChapterOrder.asc)
        .then((value) {
      list.addAll(value.splitVolumes(widget.entry.id.toString(), settings));
      page += 1;

      if (value.isNotEmpty) {
        savedChapters.add(
          widget.entry.id.toString(),
          widget.entry.site,
          value,
          page,
        );
      } else {
        reachedEnd = true;
      }

      return list;
    }).whenComplete(() {
      _future = null;

      setState(() {});
    });

    if (sets) {
      setState(() {});
    }
  }

  Widget chapterWidget(BuildContext context, AppLocalizations l8n) =>
      PopupMenuButton(
        position: PopupMenuPosition.under,
        shape: const BeveledRectangleBorder(),
        clipBehavior: Clip.antiAlias,
        itemBuilder: (context) {
          return [
            PopupMenuItem<void>(
              onTap: () {
                chapterSettings.current
                    .copy(hideRead: !settings.hideRead)
                    .save();
              },
              child: settings.hideRead
                  ? Text(l8n.mangaShowRead)
                  : Text(l8n.mangaHideRead),
            ),
            PopupMenuItem<void>(
              onTap: () {
                savedChapters.clear(
                  widget.entry.id.toString(),
                  widget.entry.site,
                );

                list.clear();
                page = 0;
                reachedEnd = false;

                setState(() {});
              },
              child: Text(
                l8n.mangaClearCachedMangaChapters,
              ),
            ),
          ];
        },
        child: TextButton(
          onPressed: null,
          style: ButtonStyle(
            foregroundColor:
                WidgetStatePropertyAll(Theme.of(context).colorScheme.primary),
          ),
          child: Text(l8n.settingsLabel),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l8n = AppLocalizations.of(context)!;

    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData && list.isNotEmpty) {
          return _ChapterBody(
            scrollController: widget.scrollController,
            list: list,
            settingsButton: chapterWidget(context, l8n),
            api: widget.api,
            entry: widget.entry,
            onFinishRead: _onFinishRead,
            onNextLoad: _loadNextChapters,
            reachedEnd: !reachedEnd
                ? SliverToBoxAdapter(
                    child: Center(
                      child: FilledButton(
                        onPressed: _future2 != null ? null : _loadNextChapters,
                        child: _future2 != null
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(l8n.mangaLoadNextChapters),
                      ),
                    ),
                  )
                : null,
            db: readChapters,
          );
        } else if (reachedEnd && list.isEmpty) {
          return const SliverToBoxAdapter(
            child: EmptyWidget(
              mini: true,
              gridSeed: 0,
            ),
          );
        } else {
          return SliverToBoxAdapter(
            child: _future != null
                ? const Center(
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : FilledButton(
                    onPressed: _loadChapters,
                    child: Text(l8n.mangaLoadChapters),
                  ),
          );
        }
      },
    );
  }
}
