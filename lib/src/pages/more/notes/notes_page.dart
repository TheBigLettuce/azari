// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gallery/src/db/initalize_db.dart';
import 'package:gallery/src/db/schemas/booru/note_booru.dart';
import 'package:gallery/src/db/schemas/gallery/note_gallery.dart';
import 'package:gallery/src/pages/gallery/callback_description_nested.dart';
import 'package:gallery/src/pages/gallery/directories.dart';
import 'package:gallery/src/widgets/copy_move_preview.dart';
import 'package:gallery/src/widgets/empty_widget.dart';
import 'package:gallery/src/widgets/grid/grid_frame.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_settings.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../../db/schemas/gallery/system_gallery_directory.dart';
import '../../../db/schemas/gallery/system_gallery_directory_file.dart';
import '../../../widgets/grid/wrap_grid_page.dart';
import 'note_page_container.dart';
import 'tab_with_count.dart';

const kNoteLoadCount = 30;

class NotesPage extends StatefulWidget {
  final CallbackDescriptionNested? callback;
  final double? bottomPadding;

  const NotesPage({super.key, this.callback, this.bottomPadding});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage>
    with SingleTickerProviderStateMixin {
  final searchController = SearchController();
  late final TabController tabController;

  final state = SkeletonState();

  late final StreamSubscription<void> booruNotesWatcher;
  late final StreamSubscription<void> galleryNotesWatcher;

  late final NotePageContainer<NoteBooru> booruContainer =
      NotePageContainer<NoteBooru>(
          [NoteBooruSchema],
          NoteBooru.interfaceSelf(() {
            booruContainer.state.gridKey.currentState?.refresh(() =>
                booruContainer.notes.loadUntil(booruContainer.notes.count()));
          }),
          loadNext: (count) => Dbs.g.blacklisted.noteBoorus
              .where()
              .offset(count)
              .limit(kNoteLoadCount)
              .findAllSync(),
          filterFnc: (text) {
            return Dbs.g.blacklisted.noteBoorus
                .filter()
                .textElementContains(text, caseSensitive: false)
                .limit(15)
                .findAllSync();
          },
          getText: (cell) => cell.currentText());
  late final NotePageContainer<NoteGallery> galleryContainer =
      NotePageContainer<NoteGallery>(
          [NoteGallerySchema],
          NoteGallery.interfaceSelf(() {
            galleryContainer.state.gridKey.currentState?.refresh(() =>
                galleryContainer.notes
                    .loadUntil(galleryContainer.notes.count()));
          }),
          loadNext: (count) => Dbs.g.main.noteGallerys
              .where()
              .offset(count)
              .limit(kNoteLoadCount)
              .findAllSync(),
          filterFnc: (text) {
            return Dbs.g.main.noteGallerys
                .filter()
                .textElementContains(text, caseSensitive: false)
                .limit(15)
                .findAllSync();
          },
          addActions: widget.callback != null
              ? [
                  GridAction(
                    Icons.check,
                    (selected) {
                      final note = selected.first;

                      widget.callback!(SystemGalleryDirectoryFile(
                          id: note.id,
                          bucketId: "",
                          name: "",
                          isVideo: note.isVideo,
                          isGif: note.isGif,
                          size: 0,
                          height: note.height,
                          notesFlat: "",
                          width: note.width,
                          isOriginal: false,
                          lastModified: 0,
                          originalUri: note.originalUri,
                          isDuplicate: false,
                          isFavorite: false,
                          tagsFlat: ''));
                    },
                    false,
                  )
                ]
              : [
                  GridAction(
                    Icons.forward,
                    (selected) {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return WrapGridPage<SystemGalleryDirectory>(
                            scaffoldKey: GlobalKey(),
                            child: GalleryDirectories(
                              procPop: (p) {},
                              nestedCallback: CallbackDescriptionNested(
                                  "Choose file", (chosen) async {
                                final s = selected.first;
                                final colors =
                                    await PaletteGenerator.fromImageProvider(
                                        chosen.thumbnail()!);

                                NoteGallery.add(chosen.id,
                                    text: s.text,
                                    height: chosen.height,
                                    width: chosen.width,
                                    backgroundColor:
                                        colors.dominantColor?.color,
                                    textColor:
                                        colors.dominantColor?.bodyTextColor,
                                    isVideo: chosen.isVideo,
                                    isGif: chosen.isGif,
                                    originalUri: chosen.originalUri);
                                NoteGallery.removeAll(s.id);

                                galleryContainer.state.gridKey.currentState
                                    ?.refresh();
                              }, returnBack: true),
                            ));
                      }));
                    },
                    false,
                  )
                ],
          getText: (cell) => cell.currentText());

  @override
  void initState() {
    tabController = TabController(length: 2, vsync: this);

    booruNotesWatcher = Dbs.g.blacklisted.noteBoorus.watchLazy().listen((_) {
      setState(() {});
    });
    galleryNotesWatcher = Dbs.g.main.noteGallerys.watchLazy().listen((_) {
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    booruContainer.dispose();
    galleryContainer.dispose();

    searchController.dispose();
    tabController.dispose();

    booruNotesWatcher.cancel();
    galleryNotesWatcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SkeletonSettings(
      "Notes",
      state,
      appBar: AppBar(
        actions: [
          SearchAnchor(
            searchController: searchController,
            builder: (context, controller) {
              return IconButton(
                  onPressed: () {
                    controller.openView();
                  },
                  icon: const Icon(Icons.search_rounded));
            },
            viewBuilder: (widgets) {
              final w = widgets.toList();

              if (w.isEmpty) {
                return const EmptyWidget();
              }

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 12),
                    child: Text(
                      AppLocalizations.of(context)!.showingResults(w.length),
                      style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                  Expanded(child: ListView(children: w))
                ],
              );
            },
            viewHintText:
                AppLocalizations.of(context)!.searchHint, // TOOD: change
            suggestionsBuilder: (context, controller) {
              if (controller.text.isEmpty) {
                return [];
              }

              return tabController.index == 1 || widget.callback != null
                  ? galleryContainer.filter(context, controller)
                  : booruContainer.filter(context, controller);
            },
          )
        ],
        title: Text(AppLocalizations.of(context)!.notesPage),
        bottom: widget.callback != null
            ? CopyMovePreview.hintWidget(context, widget.callback!.description)
            : TabBar(controller: tabController, tabs: [
                TabWithCount(AppLocalizations.of(context)!.booruLabel,
                    Dbs.g.blacklisted.noteBoorus.countSync()),
                TabWithCount(AppLocalizations.of(context)!.galleryLabel,
                    Dbs.g.main.noteGallerys.countSync())
              ]),
      ),
      child: widget.callback != null
          ? galleryContainer.widget(context, widget.bottomPadding)
          : TabBarView(controller: tabController, children: [
              booruContainer.widget(context, widget.bottomPadding),
              galleryContainer.widget(context, widget.bottomPadding)
            ]),
    );
  }
}
