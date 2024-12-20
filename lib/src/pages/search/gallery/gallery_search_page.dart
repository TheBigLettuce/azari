// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/chained_filter.dart";
import "package:azari/src/db/services/resource_source/filtering_mode.dart";
import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/pages/gallery/directories.dart";
import "package:azari/src/pages/gallery/directories_actions.dart";
import "package:azari/src/pages/gallery/files.dart";
import "package:azari/src/pages/search/booru/booru_search_page.dart";
import "package:azari/src/platform/gallery_api.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/fading_panel.dart";
import "package:azari/src/widgets/grid_frame/parts/grid_cell.dart";
import "package:azari/src/widgets/image_view/image_view.dart";
import "package:azari/src/widgets/shimmer_placeholders.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

part "search_panels/chips_panel_body.dart";
part "search_panels/directory_list.dart";
part "search_panels/directory_names.dart";
part "search_panels/files_list.dart";
part "search_panels/local_tags.dart";
part "search_panels/search_in_booru_button.dart";
part "search_panels/search_in_directories_buttons.dart";

class GallerySearchPage extends StatefulWidget {
  const GallerySearchPage({
    super.key,
    required this.db,
    required this.l10n,
    required this.procPop,
  });

  final AppLocalizations l10n;

  final void Function(bool)? procPop;

  final DbConn db;

  @override
  State<GallerySearchPage> createState() => _GallerySearchPageState();
}

class _GallerySearchPageState extends State<GallerySearchPage> {
  final searchController = TextEditingController();
  final focusNode = FocusNode();

  final _filteringEvents = StreamController<String>.broadcast();
  late final Directories api;

  late final Map<String, bool> blurMap;

  @override
  void initState() {
    super.initState();

    api = GalleryApi().open(
      widget.db.blacklistedDirectories,
      widget.db.directoryTags,
      l10n: widget.l10n,
    );

    blurMap = widget.db.directoryMetadata.toBlurAll.fold({}, (map, e) {
      map[e.categoryName] = e.blur;

      return map;
    });

    api.source.clearRefresh();
  }

  @override
  void dispose() {
    api.close();

    _filteringEvents.close();

    focusNode.dispose();
    searchController.dispose();

    super.dispose();
  }

  // void _search(String str) {
  //   _filteringEvents.add(str.trim());
  // }

  void _onDirectoryPressed(Directory directory) {
    final l10n = context.l10n();

    directory.openFilesPage(
      context: context,
      l10n: l10n,
      callback: null,
      addScaffold: true,
      api: api,
      segmentFnc: (cell) => DirectoriesPage.segmentCell(
        cell.name,
        cell.bucketId,
        widget.db.directoryTags,
      ),
    );
  }

  void _joinedDirectories(
    String str,
    List<Directory> list, {
    required String tag,
    required FilteringMode? filteringMode,
  }) {
    joinedDirectoriesFnc(
      context,
      str,
      list,
      api,
      null,
      (cell) => DirectoriesPage.segmentCell(
        cell.name,
        cell.bucketId,
        widget.db.directoryTags,
      ),
      widget.db.directoryMetadata,
      widget.db.directoryTags,
      widget.db.favoritePosts,
      widget.db.localTags,
      widget.l10n,
      tag: tag,
      filteringMode: filteringMode,
      addScaffold: true,
    );
  }

  Future<List<BooruTag>> _completeDirectoryNameTag(String str) {
    final m = <String, void>{};

    return Future.value(
      api.source.backingStorage
          .map(
            (e) {
              if (e.tag.isNotEmpty &&
                  e.tag.contains(str) &&
                  !m.containsKey(e.tag)) {
                m[e.tag] = null;
                return e.tag;
              }

              if (e.name.startsWith(str) && !m.containsKey(e.name)) {
                m[e.name] = null;

                return e.name;
              } else {
                return null;
              }
            },
          )
          .where((e) => e != null)
          .take(15)
          .map((e) => BooruTag(e!, -1))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // final l10n = context.l10n();

    return Scaffold(
      appBar: AppBar(),
      body: _SearchPagePopScope(
        searchController: searchController,
        sink: _filteringEvents.sink,
        searchFocus: focusNode,
        procPop: widget.procPop,
        child: CustomScrollView(
          slivers: [
            SearchPageSearchBar(
              complete: null,
              searchTextController: searchController,
              searchFocus: focusNode,
              sink: _filteringEvents.sink,
            ),
            StreamBuilder(
              stream: _filteringEvents.stream,
              builder: (context, snapshot) => _SearchInDirectoriesButtons(
                db: widget.db,
                listPadding: _ChipsPanelBody.listPadding,
                filteringValue: snapshot.data ?? "",
                joinedDirectories: _joinedDirectories,
                source: api.source,
              ),
            ),
            _DirectoryNamesPanel(
              api: api,
              filteringEvents: _filteringEvents,
              searchController: searchController,
              directoryComplete: _completeDirectoryNameTag,
            ),
            _LocalTagsPanel(
              filteringEvents: _filteringEvents,
              searchController: searchController,
              joinedDirectories: _joinedDirectories,
              source: api.source,
              db: widget.db,
            ),
            _FilesList(
              filteringEvents: _filteringEvents,
              searchController: searchController,
              db: widget.db,
            ),
            _DirectoryList(
              filteringEvents: _filteringEvents,
              source: api.source,
              searchController: searchController,
              onDirectoryPressed: _onDirectoryPressed,
              blurMap: blurMap,
            ),
            Builder(
              builder: (context) => SliverPadding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewPaddingOf(context).bottom + 8,
                ),
              ),
            ),
          ],
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
    required this.procPop,
  });

  final TextEditingController searchController;
  final StreamSink<String> sink;
  final FocusNode searchFocus;

  final void Function(bool)? procPop;

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
          return;
        }

        widget.procPop?.call(didPop);
      },
      child: widget.child,
    );
  }
}
