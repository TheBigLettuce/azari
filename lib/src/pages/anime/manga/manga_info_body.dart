// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/manga/chapters_settings.dart';
import 'package:gallery/src/db/schemas/manga/read_manga_chapter.dart';
import 'package:gallery/src/db/schemas/manga/saved_manga_chapters.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';
import 'package:gallery/src/pages/anime/info_base/body/anime_genres.dart';
import 'package:gallery/src/pages/anime/info_base/body/body_padding.dart';
import 'package:gallery/src/pages/anime/info_base/body/body_segment_label.dart';
import 'package:gallery/src/pages/anime/info_base/body/synopsis_background.dart';
import 'package:gallery/src/pages/anime/manga/manga_relations.dart';
import 'package:gallery/src/pages/anime/search/search_anime.dart';
import 'package:gallery/src/pages/booru/bookmark_button.dart';
import 'package:gallery/src/pages/more/settings/settings_label.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/image_view/image_view.dart';

class MangaInfoBody extends StatelessWidget {
  final MangaEntry entry;
  final MangaAPI api;
  final EdgeInsets viewPadding;
  final Color? overlayColor;

  const MangaInfoBody({
    super.key,
    required this.entry,
    required this.viewPadding,
    required this.api,
    required this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return BodyPadding(
      viewPadding: viewPadding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimeGenres<MangaGenre>(
              genres: entry.genres.map((e) => (e, false)).toList(),
              title: (e) => e.name,
              onPressed: (e) {
                SearchAnimePage.launchMangaApi(
                  context,
                  api,
                  safeMode: entry.safety,
                  initalGenreId: e.id,
                );
              },
            ),
            const Padding(padding: EdgeInsets.only(top: 8)),
            SynopsisBackground(
              background: "",
              synopsis: entry.description,
              search: (_) {},
              constraints: BoxConstraints(
                  minWidth: MediaQuery.sizeOf(context).width - 16 - 16,
                  maxWidth: MediaQuery.sizeOf(context).width - 16 - 16),
            ),
            MangaChapters(
              entry: entry,
              api: api,
              overlayColor: overlayColor,
            ),
            MangaRelations(
              entry: entry,
              api: api,
            ),
          ],
        ),
      ),
    );
  }
}

class MangaChapters extends StatefulWidget {
  final MangaEntry entry;
  final MangaAPI api;
  final Color? overlayColor;

  const MangaChapters({
    super.key,
    required this.entry,
    required this.api,
    required this.overlayColor,
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

  List<Widget> makeSlivers(
      BuildContext context, List<(List<MangaChapter>, String)> l) {
    final ret = <Widget>[
      SliverToBoxAdapter(
        child: Align(
          alignment: Alignment.centerRight,
          child: PopupMenuButton(
            position: PopupMenuPosition.under,
            shape: const BeveledRectangleBorder(),
            clipBehavior: Clip.antiAlias,
            // splashRadius: 15,
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  onTap: () {
                    ChapterSettings.setHideRead(!settings.hideRead);
                  },
                  child:
                      settings.hideRead ? Text("Show read") : Text("Hide read"),
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
                  child: Text("Clear"),
                ),
              ];
            },
            child: const TextButton(
              onPressed: null,
              child: Text("Settings"), // TODO: change
            ),
          ),
        ),
      )
    ];

    for (final e in l) {
      ret.add(SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12, top: 16),
          child: Text(
            "Volume ${e.$2}",
            style: SettingsLabel.defaultStyle(context),
          ),
        ),
      ));
      ret.add(
        SliverList.list(
            children: e.$1.map((e) {
          return _Tile(
            key: ValueKey(e.id),
            finishRead: () {
              if (settings.hideRead) {
                _future2 = () async {
                  reloadChapters();

                  _future2 = null;

                  setState(() {});

                  return list;
                }();

                setState(() {});
              }
            },
            chapter: e,
            entry: widget.entry,
            api: widget.api,
            overlayColor: widget.overlayColor,
          );
        }).toList()),
      );
    }

    if (!reachedEnd) {
      ret.add(SliverToBoxAdapter(
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
                : const Text("Load next"), // TODO: change
          ),
        ),
      ));
    }

    return ret;
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

  void _loadChapters() {
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

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData && list.isNotEmpty) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const BodySegmentLabel(text: "Chapters"), // TODO: change
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: CustomScrollView(
                      primary: false,
                      scrollDirection: Axis.vertical,
                      slivers: makeSlivers(context, list),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (reachedEnd && list.isEmpty) {
          return const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              BodySegmentLabel(text: "Chapters"), // TODO: change
              EmptyWidget(
                mini: true,
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
                  child: const Text("Load chapters"), // TODO: change
                );
        }
      },
    );
  }
}

class _Tile extends StatefulWidget {
  final MangaChapter chapter;
  final MangaEntry entry;
  final MangaAPI api;
  final Color? overlayColor;
  final void Function() finishRead;

  const _Tile({
    super.key,
    required this.chapter,
    required this.entry,
    required this.api,
    required this.overlayColor,
    required this.finishRead,
  });

  @override
  State<_Tile> createState() => __TileState();
}

class __TileState extends State<_Tile> {
  int? progress;

  @override
  void initState() {
    super.initState();

    progress = ReadMangaChapter.progress(
      siteMangaId: widget.entry.id.toString(),
      chapterId: widget.chapter.id.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: widget.chapter.pages != 0,
      onTap: widget.chapter.pages == 0
          ? null
          : () {
              final f =
                  widget.api.imagesForChapter(MangaStringId(widget.chapter.id));
              final overlayColor = Theme.of(context).colorScheme.background;

              ReadMangaChapter.launchReader(
                context,
                f,
                widget.overlayColor ?? overlayColor,
                api: widget.api,
                onNextPage: (currentPage) {
                  setState(() {
                    progress = currentPage + 1;
                  });

                  if (currentPage + 1 == widget.chapter.pages) {
                    widget.finishRead();
                  }
                },
                mangaId: widget.entry.id,
                chapterId: widget.chapter.id,
              );
            },
      contentPadding: EdgeInsets.zero,
      subtitle: Text("${widget.chapter.title} (${widget.chapter.translator})"),
      title: Text.rich(
        TextSpan(
          text: widget.chapter.chapter.toString(),
          children: [
            if (progress != null)
              TextSpan(
                text: progress == widget.chapter.pages
                    ? "  done" // TODO: change
                    : "  $progress / ${widget.chapter.pages}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
