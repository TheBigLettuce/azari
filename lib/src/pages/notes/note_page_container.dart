// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/loaders/paging_isar_loader.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';
import 'package:gallery/src/interfaces/grid/selection_glue.dart';
import 'package:gallery/src/interfaces/note_interface.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/grid/layouts/note_layout.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton.dart';
import 'package:gallery/src/widgets/skeletons/grid_skeleton_state.dart';
import 'package:isar/isar.dart';

import '../image_view.dart';

class NotePageContainer<T extends Cell> {
  final state = GridSkeletonState<T>();
  final PagingIsarLoader<T> notes;
  final List<T> Function(String text) filterFnc;
  final NoteInterface<T> noteInterface;
  final List<GridAction<T>> addActions;
  final List<String> Function(T cell) getText;

  Iterable<Widget> filter(BuildContext context, SearchController controller) {
    return filterFnc(controller.text).map((e1) => ListTile(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) {
                final overlayColor =
                    Theme.of(context).colorScheme.background.withOpacity(0.5);

                return ImageView<T>(
                    updateTagScrollPos: (_, __) {},
                    cellCount: 1,
                    scrollUntill: (_) {},
                    startingCell: 0,
                    onExit: () {},
                    ignoreEndDrawer: true,
                    onEmptyNotes: () {
                      WidgetsBinding.instance
                          .scheduleFrameCallback((timeStamp) {
                        Navigator.pop(context);
                      });
                    },
                    noteInterface: noteInterface,
                    getCell: (idx) => e1,
                    onNearEnd: null,
                    focusMain: () => state.mainFocus,
                    systemOverlayRestoreColor: overlayColor);
              },
            ));
          },
          title: Container(
            height: 100,
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            child: Image(
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                image: e1.thumbnail()!),
          ),
        ).animate().fadeIn());
  }

  Widget widget(BuildContext context, double? bottomPadding) {
    SelectionGlue<J> generate<J extends Cell>() => SelectionGlue.empty(context);

    return GlueProvider<T>(
      generate: generate,
      glue: SelectionGlue.empty(context),
      child: GridSkeleton<T>(
          state,
          (context) => CallbackGrid<T>(
                key: state.gridKey,
                getCell: notes.get,
                initalScrollPosition: 0,
                scaffoldKey: state.scaffoldKey,
                ignoreImageViewEndDrawer: true,
                onBack: () {
                  Navigator.pop(context);
                },
                systemNavigationInsets:
                    MediaQuery.systemGestureInsetsOf(context) +
                        EdgeInsets.only(bottom: bottomPadding ?? 0),
                hasReachedEnd: notes.reachedEnd,
                selectionGlue: SelectionGlue.empty(context),
                mainFocus: state.mainFocus,
                refresh: notes.refresh,
                noteInterface: noteInterface,
                addIconsImage: (_) => addActions,
                initalCellCount: notes.count(),
                loadNext: notes.next,
                description: GridDescription<T>([],
                    keybindsDescription: "Notes page",
                    showAppBar: false,
                    layout: NoteLayout<T>(GridColumn.three, getText)),
              ),
          canPop: true),
    );
  }

  void dispose() {
    state.dispose();
    notes.dispose(force: true);
  }

  NotePageContainer(List<CollectionSchema> schemas, this.noteInterface,
      {required Iterable<T> Function(int) loadNext,
      required this.filterFnc,
      this.addActions = const [],
      required this.getText})
      : notes = PagingIsarLoader<T>(schemas, loadNext);
}
