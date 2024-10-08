// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/source_storage.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/pages/anime/anime.dart";
import "package:azari/src/pages/booru/booru_page.dart";
import "package:azari/src/pages/booru/booru_restored_page.dart";
import "package:azari/src/pages/booru/popular_random_buttons.dart";
import "package:azari/src/widgets/gesture_dead_zones.dart";
import "package:azari/src/widgets/search/autocomplete/autocomplete_widget.dart";
import "package:azari/src/widgets/shimmer_loading_indicator.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";

part "search_panels/pinned_tags.dart";
part "search_panels/chips_panel_body.dart";
part "search_panels/bookmarks_panel_body.dart";
part "search_panels/tag_list.dart";
part "search_panels/excluded_tags.dart";
part "search_panels/bookmarks.dart";
part "search_panels/recently_searched_tags.dart";
part "search_panels/add_tag_button.dart";

class BooruSearchPage extends StatefulWidget {
  const BooruSearchPage({
    super.key,
    required this.db,
    required this.onTagPressed,
  });

  final DbConn db;

  final OnBooruTagPressedFunc onTagPressed;

  @override
  State<BooruSearchPage> createState() => _BooruSearchPageState();
}

class _BooruSearchPageState extends State<BooruSearchPage> {
  SettingsData settings = SettingsService.db().current;

  late final Dio client;
  late final BooruAPI api;

  late final StreamSubscription<SettingsData?> settingsSubsc;

  final searchController = TextEditingController();
  final focusNode = FocusNode();

  final _filteringEvents = StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();

    client = BooruAPI.defaultClientForBooru(settings.selectedBooru);
    settingsSubsc = settings.s.watch((newSettings) {
      setState(() {
        settings = newSettings!;
      });
    });

    api = BooruAPI.fromEnum(
      settings.selectedBooru,
      client,
      PageSaver.noPersist(),
    );
  }

  @override
  void dispose() {
    client.close(force: true);
    settingsSubsc.cancel();
    _filteringEvents.close();

    focusNode.dispose();
    searchController.dispose();

    super.dispose();
  }

  void _search(String str) {
    _filteringEvents.add(str.trim());
  }

  void _onTagPressed(String str) {
    Navigator.pop(context);

    widget.onTagPressed(context, api.booru, str, null);
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
                    const SnackBar(
                        content: Text("Search text is empty")), // TODO: change
                  );

                  return;
                }

                _onTagPressed(searchController.text.trim());
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
              SliverPadding(
                padding: _ChipsPanelBody.listPadding,
                sliver: StreamBuilder(
                  stream: _filteringEvents.stream,
                  builder: (context, snapshot) => PopularRandomButtons(
                    db: widget.db,
                    booru: api.booru,
                    onTagPressed: widget.onTagPressed,
                    tags: snapshot.data ?? "",
                    safeMode: () => settings.safeMode,
                  ),
                ),
              ),
              _RecentlySearchedTagsPanel(
                filteringEvents: _filteringEvents,
                searchController: searchController,
                tagManager: widget.db.tagManager,
                onTagPressed: _onTagPressed,
              ),
              _PinnedTagsPanel(
                filteringEvents: _filteringEvents.stream,
                tagManager: widget.db.tagManager,
                api: api,
                onTagPressed: (str_) {
                  final str = str_.isEmpty
                      ? ""
                      : str_.trim().split(" ").lastOrNull?.trim() ?? "";

                  searchController.text = "${searchController.text}$str ";
                  _filteringEvents.add(searchController.text.trim());
                },
              ),
              _ExcludedTagsPanel(
                filteringEvents: _filteringEvents.stream,
                tagManager: widget.db.tagManager,
                api: api,
              ),
              _BookmarksPanel(
                db: widget.db,
                filteringEvents: _filteringEvents.stream,
              ),
              _TagList(
                filteringEvents: _filteringEvents,
                searchController: searchController,
                api: api,
              ),
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
