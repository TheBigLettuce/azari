// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/gallery/server_directories.dart';
import 'package:gallery/src/gallery/images.dart';
import 'package:gallery/src/widgets/booru/autocomplete_tag.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:gallery/src/widgets/search_launch_grid.dart';
import 'package:gallery/src/db/isar.dart' as db;
import 'package:isar/isar.dart';

import '../gallery/server_api/server.dart';
import '../schemas/directory.dart';
import '../schemas/directory_file.dart';

mixin SearchFilterGridImages on State<Images>
    implements
        SearchMixin<GridSkeletonState<DirectoryFile, DirectoryFileShrinked>> {
  @override
  final TextEditingController searchTextController = TextEditingController();
  @override
  final FocusNode searchFocus = FocusNode();

  late final void Function() focusMain;

  late final GlobalKey<CallbackGridState<DirectoryFile, DirectoryFileShrinked>>
      gridKey;

  @override
  void searchHook(state) {
    focusMain = () => state.mainFocus.requestFocus();
    gridKey = state.gridKey;
  }

  @override
  void disposeSearch() {
    searchTextController.dispose();
    searchFocus.dispose();
  }

  @override
  Widget searchWidget(BuildContext context) => FocusNotifier(
      focusMain: focusMain,
      notifier: searchFocus,
      child: Builder(
        builder: (context) => TextField(
          focusNode: searchFocus,
          controller: searchTextController,
          decoration: autocompleteBarDecoration(context, () {
            searchTextController.clear();
            gridKey.currentState?.mutationInterface?.restore();
          }, null,
              showSearch: true,
              roundBorders: false,
              hint: "Filter"), // TODO: change
          onChanged: (value) {
            var interface = gridKey.currentState?.mutationInterface;
            if (interface != null) {
              value = value.trim();
              if (value.isEmpty) {
                interface.restore();
                widget.api.resetFilter();
                return;
              }

              var res = widget.api.filter(value);

              interface.setSource(res.count, res.cell);
            }
          },
        ),
      ));
}

mixin SearchFilterGridDirectory on State<ServerDirectories>
    implements SearchMixin<GridSkeletonState<Directory, Directory>> {
  @override
  final TextEditingController searchTextController = TextEditingController();
  @override
  final FocusNode searchFocus = FocusNode();

  final api = ServerAPI(db.openServerApiIsar());
  late final void Function() focusMain;

  List<Directory>? filterResults;

  late final GlobalKey<CallbackGridState<Directory, Directory>> gridKey;

  @override
  void searchHook(state) {
    focusMain = () => state.mainFocus.requestFocus();
    gridKey = state.gridKey;
  }

  @override
  void disposeSearch() {
    searchTextController.dispose();
    searchFocus.dispose();
  }

  @override
  Widget searchWidget(BuildContext context) => FocusNotifier(
      focusMain: focusMain,
      notifier: searchFocus,
      child: Builder(
        builder: (context) => TextField(
          focusNode: searchFocus,
          controller: searchTextController,
          decoration: autocompleteBarDecoration(context, () {
            searchTextController.clear();
            gridKey.currentState?.mutationInterface?.restore();
          }, null,
              showSearch: true,
              roundBorders: false,
              hint: "Filter"), // TODO: change
          onChanged: (value) {
            var interface = gridKey.currentState?.mutationInterface;
            if (interface != null) {
              value = value.trim();
              if (value.isEmpty) {
                interface.restore();
                filterResults = null;
                return;
              }

              filterResults = api.serverIsar.directorys
                  .filter()
                  .dirNameContains(value, caseSensitive: false)
                  .findAllSync();

              interface.setSource(filterResults!.length, (i) {
                return filterResults![i];
              });
            }
          },
        ),
      ));
}
