// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/l10n/generated/app_localizations.dart";
import "package:azari/src/db/services/resource_source/basic.dart";
import "package:azari/src/db/services/resource_source/source_storage.dart";
import "package:azari/src/db/services/services.dart";
import "package:azari/src/net/booru/booru.dart";
import "package:azari/src/net/booru/booru_api.dart";
import "package:azari/src/net/booru/safe_mode.dart";
import "package:azari/src/pages/booru/booru_restored_page.dart";
import "package:azari/src/pages/search/booru/popular_random_buttons.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/autocomplete_widget.dart";
import "package:azari/src/widgets/fading_panel.dart";
import "package:azari/src/widgets/grid_frame/configuration/grid_search_widget.dart";
import "package:azari/src/widgets/grid_frame/grid_frame.dart";
import "package:azari/src/widgets/shimmer_loading_indicator.dart";
import "package:azari/src/widgets/shimmer_placeholders.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:dio/dio.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";

part "search_panels/add_tag_button.dart";
part "search_panels/bookmarks.dart";
part "search_panels/bookmarks_panel_body.dart";
part "search_panels/chips_panel_body.dart";
part "search_panels/excluded_tags.dart";
part "search_panels/pinned_tags.dart";
part "search_panels/recently_searched_tags.dart";
part "search_panels/tag_list.dart";

class BooruSearchPage extends StatefulWidget {
  const BooruSearchPage({
    super.key,
    required this.db,
    required this.l10n,
    required this.procPop,
  });

  final AppLocalizations l10n;

  final void Function(bool)? procPop;

  final DbConn db;

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

    api = BooruAPI.fromEnum(settings.selectedBooru, client);
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

  // void _search(String str) {
  //   _filteringEvents.add(str.trim());
  // }

  void _onTagPressed(String str) {
    _onTag(context, api.booru, str, null);
  }

  void _onTag(
    BuildContext context,
    Booru booru,
    String tag,
    SafeMode? safeMode,
  ) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (context) => BooruRestoredPage(
          db: widget.db,
          booru: booru,
          tags: tag,
          wrapScaffold: true,
          overrideSafeMode: safeMode,
          saveSelectedPage: (_) {},
        ),
      ),
    );
  }

  void search() {
    if (searchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.l10n.searchTextIsEmpty),
        ),
      );

      return;
    }

    _onTagPressed(searchController.text.trim());
  }

  void pinnedTagPressed(String str_) {
    // final elements = str_.trim().split(" ");
    // if (elements.isEmpty) {

    // } else {
    //   final last = elements.last;

    //   final searchTextTags = searchController.text.trim().split(" ");
    //   searchTextTags.remove(last);

    //   searchController.text = "${searchTextTags.join(" ")} $last ";
    //   // _filteringEvents.add(searchController.text.trim());
    // }
    searchController.text = "$str_ ";
    _filteringEvents.add(searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return _SearchPagePopScope(
      searchController: searchController,
      sink: _filteringEvents.sink,
      procPop: widget.procPop,
      searchFocus: focusNode,
      child: SliverMainAxisGroup(
        slivers: [
          SearchPageSearchBar(
            complete: null,
            // filter: filter,
            // safeModeState: safeModeState,
            onSubmit: search,
            sink: _filteringEvents.sink,
            searchTextController: searchController,
            searchFocus: focusNode,
          ),
          StreamBuilder(
            stream: _filteringEvents.stream,
            builder: (context, snapshot) => PopularRandomButtons(
              listPadding: _ChipsPanelBody.listPadding,
              db: widget.db,
              booru: api.booru,
              onTagPressed: _onTag,
              tags: snapshot.data ?? "",
              safeMode: () => settings.safeMode,
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
            onTagPressed: pinnedTagPressed,
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
        ],
      ),
    );
  }
}

class SearchPageSearchBar extends StatelessWidget {
  const SearchPageSearchBar({
    super.key,
    required this.searchTextController,
    required this.searchFocus,
    required this.sink,
    required this.complete,
    this.onSubmit = _doNothing,
  });

  final TextEditingController searchTextController;
  final FocusNode searchFocus;

  final void Function() onSubmit;

  final Future<List<BooruTag>> Function(String string)? complete;

  final StreamSink<String> sink;

  static void _doNothing() {}

  void clear() {
    searchTextController.text = "";
    sink.add(searchTextController.text.trim());
    searchFocus.unfocus();
  }

  void onChanged(String? _) {
    sink.add(searchTextController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // final theme = Theme.of(context);

    const padding = EdgeInsets.only(
      right: 26,
      left: 26,
      top: 8,
      bottom: 8,
    );

    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: padding,
          child: SearchBarAutocompleteWrapper(
            search: BarSearchWidget(
              onChanged: onChanged,
              onSubmitted: (_) => onSubmit(),
              complete: complete,
              textEditingController: searchTextController,
            ),
            searchFocus: searchFocus,
            child: (
              context,
              controller,
              focus,
              onSubmitted,
            ) =>
                SearchBar(
              onSubmitted: (str) {
                onSubmitted();
                // filter.clearRefresh();
              },
              elevation: const WidgetStatePropertyAll(0),
              focusNode: focus,
              controller: controller,
              onTapOutside: (event) => focus.unfocus(),
              onChanged: onChanged,
              hintText: l10n.searchHint,
              leading: IconButton(
                onPressed: onSubmit,
                icon: const Icon(Icons.search_rounded),
              ),
              trailing: [
                IconButton(
                  onPressed: clear,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
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
    required this.procPop,
    required this.child,
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

  void onPopInvoked(bool didPop, Object? extra) {
    if (widget.searchController.text.isNotEmpty) {
      widget.searchController.clear();
      widget.searchFocus.previousFocus();
      widget.sink.add("");
      return;
    }

    widget.procPop?.call(didPop);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.searchController.text.isEmpty,
      onPopInvokedWithResult: onPopInvoked,
      child: widget.child,
    );
  }
}
