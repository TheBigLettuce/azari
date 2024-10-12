// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/anime/anime_api.dart";
import "package:azari/src/net/anime/anime_entry.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/pages/anime/anime.dart";
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/widgets/gesture_dead_zones.dart";
import "package:azari/src/widgets/glue_provider.dart";
import "package:azari/src/widgets/grid_frame/configuration/cell/cell.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_aspect_ratio.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_column.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/grid_frame/layouts/grid_layout.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_configuration.dart";
import "package:azari/src/widgets/grid_frame/wrappers/wrap_grid_page.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

// part "search_panels/directory_names.dart";
// part "search_panels/chips_panel_body.dart";
// part "search_panels/files_list.dart";
// part "search_panels/search_in_booru_button.dart";
// part "search_panels/local_tags.dart";
part "search_panels/most_rated.dart";
// part "search_panels/search_in_directories_buttons.dart";

class AnimeSearchPage extends StatefulWidget {
  const AnimeSearchPage({
    super.key,
    required this.db,
    required this.api,
    // required this.source,
    // required this.onDirectoryPressed,
    // required this.directoryComplete,
    // required this.joinedDirectories,
  });

  final AnimeAPI api;
  // final ResourceSource<int, GalleryDirectory> source;

  // final void Function(GalleryDirectory) onDirectoryPressed;
  // final void Function(
  //   String str,
  //   List<GalleryDirectory> list, {
  //   required String tag,
  //   required FilteringMode? filteringMode,
  // }) joinedDirectories;

  // final Future<List<BooruTag>> Function(String str) directoryComplete;

  final DbConn db;

  @override
  State<AnimeSearchPage> createState() => _AnimeSearchPageState();
}

class _AnimeSearchPageState extends State<AnimeSearchPage> {
  final searchController = TextEditingController();
  final focusNode = FocusNode();

  final _filteringEvents = StreamController<String>.broadcast();

  late final Map<String, bool> blurMap;

  @override
  void initState() {
    super.initState();

    blurMap = widget.db.directoryMetadata.toBlurAll.fold({}, (map, e) {
      map[e.categoryName] = e.blur;

      return map;
    });
  }

  @override
  void dispose() {
    _filteringEvents.close();

    focusNode.dispose();
    searchController.dispose();

    super.dispose();
  }

  void _search(String str) {
    _filteringEvents.add(str.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _SearchPagePopScope(
      searchController: searchController,
      sink: _filteringEvents.sink,
      searchFocus: focusNode,
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: searchController,
            focusNode: focusNode,
            onTapOutside: (event) => focusNode.previousFocus(),
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              border: InputBorder.none,
            ),
            onChanged: _search,
          ),
          actions: [
            IconButton(
              onPressed: () {
                if (searchController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.searchTextIsEmpty),
                    ),
                  );

                  return;
                }

                _search(searchController.text.trim());
                // _onTagPressed(searchController.text.trim());
              },
              icon: const Icon(Icons.search_rounded),
            ),
          ],
        ),
        body: GestureDeadZones(
          left: true,
          right: true,
          child: CustomScrollView(
            slivers: [
              // StreamBuilder(
              //   stream: _filteringEvents.stream,
              //   builder: (context, snapshot) => _SearchInDirectoriesButtons(
              //     db: widget.db,
              //     listPadding: _ChipsPanelBody.listPadding,
              //     filteringValue: snapshot.data ?? "",
              //     joinedDirectories: widget.joinedDirectories,
              //     source: widget.source,
              //   ),
              // ),
              _MostRatedList(
                filteringEvents: _filteringEvents,
                api: widget.api,
                searchController: searchController,
              ),
              // _DirectoryNamesPanel(
              //   filteringEvents: _filteringEvents,
              //   searchController: searchController,
              //   directoryComplete: widget.directoryComplete,
              // ),
              // _LocalTagsPanel(
              //   filteringEvents: _filteringEvents,
              //   searchController: searchController,
              //   joinedDirectories: widget.joinedDirectories,
              //   source: widget.source,
              //   db: widget.db,
              // ),
              // _FilesList(
              //   filteringEvents: _filteringEvents,
              //   searchController: searchController,
              //   db: widget.db,
              // ),
              // _DirectoryList(
              //   filteringEvents: _filteringEvents,
              //   source: widget.source,
              //   searchController: searchController,
              //   onDirectoryPressed: widget.onDirectoryPressed,
              //   blurMap: blurMap,
              // ),
              Builder(
                builder: (context) => SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.viewPaddingOf(context).bottom + 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchPagePopScope extends StatefulWidget {
  const _SearchPagePopScope({
    // super.key,
    required this.searchController,
    required this.sink,
    required this.searchFocus,
    required this.child,
  });

  final TextEditingController searchController;
  final StreamSink<String> sink;
  final FocusNode searchFocus;

  final Widget child;

  @override
  State<_SearchPagePopScope> createState() => __SearchPagePopScopeState();
}

class __SearchPagePopScopeState extends State<_SearchPagePopScope> {
  @override
  void initState() {
    super.initState();

    widget.searchController.addListener(_listener);
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_listener);

    super.dispose();
  }

  void _listener() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.searchController.text.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (widget.searchController.text.isNotEmpty) {
          widget.searchController.clear();
          widget.searchFocus.previousFocus();
          widget.sink.add("");
        }
      },
      child: widget.child,
    );
  }
}
