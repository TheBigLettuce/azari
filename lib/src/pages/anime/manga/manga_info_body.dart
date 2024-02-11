// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/manga/manga_api.dart';
import 'package:gallery/src/pages/anime/info_base/body/anime_genres.dart';
import 'package:gallery/src/pages/anime/info_base/body/body_padding.dart';
import 'package:gallery/src/pages/anime/info_base/body/body_segment_label.dart';
import 'package:gallery/src/pages/anime/info_base/body/synopsis_background.dart';
import 'package:gallery/src/pages/anime/manga/manga_relations.dart';
import 'package:gallery/src/pages/anime/search/search_anime.dart';
import 'package:gallery/src/pages/booru/bookmark_button.dart';
import 'package:gallery/src/pages/more/settings/settings_label.dart';
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
  final List<(List<MangaChapter>, String)> list = [];

  Future<List<(List<MangaChapter>, String)>>? _future;
  Future<List<(List<MangaChapter>, String)>>? _future2;

  bool reachedEnd = false;
  int page = 0;

  List<Widget> makeSlivers(
      BuildContext context, List<(List<MangaChapter>, String)> l) {
    final ret = <Widget>[];

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
            children: e.$1
                .map((e) => ListTile(
                    enabled: e.pages != 0,
                    onTap: e.pages == 0
                        ? null
                        : () {
                            final f = widget.api.imagesForChapter(e.id);
                            final overlayColor =
                                Theme.of(context).colorScheme.background;

                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) {
                                return FutureBuilder(
                                  future: f,
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      final chapters = snapshot.data!;

                                      return ImageView<MangaImage>(
                                        ignoreLoadingBuilder: true,
                                        ignoreEndDrawer: true,
                                        updateTagScrollPos: (_, __) {},
                                        cellCount: chapters.length,
                                        scrollUntill: (_) {},
                                        startingCell: 0,
                                        onExit: () {},
                                        getCell: (i) => chapters[i],
                                        onNearEnd: null,
                                        focusMain: () {},
                                        systemOverlayRestoreColor:
                                            widget.overlayColor ?? overlayColor,
                                      );
                                    } else {
                                      return Scaffold(
                                        appBar: snapshot.hasError
                                            ? AppBar(
                                                leading: const BackButton(),
                                              )
                                            : null,
                                        body: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ));
                          },
                    contentPadding: EdgeInsets.zero,
                    subtitle: Text("${e.title} (${e.translator})"),
                    title: Text(e.chapter.toString())))
                .toList()),
      );
    }

    if (!reachedEnd) {
      ret.add(SliverToBoxAdapter(
        child: Center(
          child: FilledButton(
            onPressed: _future2 != null
                ? null
                : () {
                    _future2 = widget.api
                        .chapters(widget.entry,
                            page: page, order: MangaChapterOrder.asc)
                        .then((value) {
                      list.addAll(value);
                      page += 1;
                      if (value.isEmpty) {
                        reachedEnd = true;
                      }

                      _future2 = null;

                      setState(() {});

                      return value;
                    });

                    setState(() {});
                  },
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.4,
            child: Column(
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
        } else {
          return _future != null
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : FilledButton(
                  onPressed: () {
                    _future = widget.api
                        .chapters(widget.entry,
                            page: page, order: MangaChapterOrder.asc)
                        .then((value) {
                      list.addAll(value);
                      page += 1;

                      return value;
                    });

                    setState(() {});
                  },
                  child: const Text("Load chapters"), // TODO: change
                );
        }
      },
    );
  }
}

// class VolumePanel extends StatelessWidget {
//   final List<MangaChapter> chapters;
//   final String volume;

//   const VolumePanel({
//     super.key,
//     required this.chapters,
//     required this.volume,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.only(left: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Padding(
//             padding: const EdgeInsets.only(bottom: 12, top: 16),
//             child: Text(
//               "Volume $volume",
//               style: SettingsLabel.defaultStyle(context),
//             ),
//           ),
//           Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: chapters
//                 .map((e) => BookmarkListTile(
//                     subtitle: "${e.title} (${e.translator})", title: e.chapter))
//                 .toList(),
//           ),
//         ],
//       ),
//     );
//   }
// }
