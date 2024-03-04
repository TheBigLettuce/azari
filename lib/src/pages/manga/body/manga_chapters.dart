// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/schemas/manga/chapters_settings.dart';
import 'package:gallery/src/db/schemas/manga/read_manga_chapter.dart';
import 'package:gallery/src/db/schemas/manga/saved_manga_chapters.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';
import 'package:gallery/src/pages/anime/info_base/body/body_segment_label.dart';
import 'package:gallery/src/pages/manga/body/chapter_tile.dart';
import 'package:gallery/src/pages/more/settings/settings_label.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

part 'chapter_body.dart';

class MangaChapters extends StatefulWidget {
  final MangaEntry entry;
  final MangaAPI api;
  final Color? overlayColor;
  final ScrollController scrollController;

  const MangaChapters({
    super.key,
    required this.entry,
    required this.api,
    required this.overlayColor,
    required this.scrollController,
  });

  @override
  State<MangaChapters> createState() => _MangaChaptersState();
}

class _MangaChaptersState extends State<MangaChapters> {
  late final StreamSubscription<ChapterSettings?> watcher;
  ChapterSettings settings = ChapterSettings.current;

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

    watcher = ChapterSettings.watch((c) {
      settings = c!;

      reloadChapters();

      setState(() {});
    });

    if (SavedMangaChapters.count(
            widget.entry.id.toString(), widget.entry.site) !=
        0) {
      _future = () async {
        final chpt = SavedMangaChapters.get(
            widget.entry.id.toString(), widget.entry.site, settings);

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
    final chpt = SavedMangaChapters.get(
      widget.entry.id.toString(),
      widget.entry.site,
      settings,
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
        SavedMangaChapters.add(
            widget.entry.id.toString(), widget.entry.site, value, page);
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
        SavedMangaChapters.add(
            widget.entry.id.toString(), widget.entry.site, value, page);
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

  @override
  Widget build(BuildContext context) {
    Widget chapterWidget() => Row(
          textBaseline: TextBaseline.alphabetic,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            BodySegmentLabel(
                text: AppLocalizations.of(context)!.mangaChaptersLabel),
            PopupMenuButton(
              position: PopupMenuPosition.under,
              shape: const BeveledRectangleBorder(),
              clipBehavior: Clip.antiAlias,
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    onTap: () {
                      ChapterSettings.setHideRead(!settings.hideRead);
                    },
                    child: settings.hideRead
                        ? Text(AppLocalizations.of(context)!.mangaShowRead)
                        : Text(AppLocalizations.of(context)!.mangaHideRead),
                  ),
                  PopupMenuItem(
                    onTap: () {
                      SavedMangaChapters.clear(
                        widget.entry.id.toString(),
                        widget.entry.site,
                      );

                      list.clear();
                      page = 0;
                      reachedEnd = false;

                      setState(() {});
                    },
                    child: Text(AppLocalizations.of(context)!
                        .mangaClearCachedMangaChapters),
                  ),
                ];
              },
              child: TextButton(
                onPressed: null,
                style: ButtonStyle(
                  foregroundColor: MaterialStatePropertyAll(
                      Theme.of(context).colorScheme.primary),
                ),
                child: Text(AppLocalizations.of(context)!.settingsLabel),
              ),
            ),
          ],
        );

    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData && list.isNotEmpty) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                chapterWidget(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 0),
                    child: _ChapterBody(
                      scrollController: widget.scrollController,
                      list: list,
                      api: widget.api,
                      entry: widget.entry,
                      onFinishRead: _onFinishRead,
                      onNextLoad: _loadNextChapters,
                      overlayColor: widget.overlayColor,
                      reachedEnd: !reachedEnd
                          ? SliverToBoxAdapter(
                              child: Center(
                                child: FilledButton(
                                  onPressed: _future2 != null
                                      ? null
                                      : _loadNextChapters,
                                  child: _future2 != null
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(AppLocalizations.of(context)!
                                          .mangaLoadNextChapters),
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (reachedEnd && list.isEmpty) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              chapterWidget(),
              const EmptyWidget(
                mini: true,
                gridSeed: 0,
              )
            ],
          );
        } else {
          return _future != null
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : FilledButton(
                  onPressed: _loadChapters,
                  child: Text(AppLocalizations.of(context)!.mangaLoadChapters),
                );
        }
      },
    );
  }
}
