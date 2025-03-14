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
import "package:azari/src/pages/other/settings/radio_dialog.dart";
import "package:azari/src/typedefs.dart";
import "package:azari/src/widgets/autocomplete_widget.dart";
import "package:azari/src/widgets/fading_panel.dart";
import "package:azari/src/widgets/shell/configuration/shell_app_bar_type.dart";
import "package:azari/src/widgets/shell/shell_scope.dart";
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
    required this.l10n,
    required this.procPop,
    required this.tagManager,
    required this.gridBookmarks,
    required this.settingsService,
  });

  final AppLocalizations l10n;

  final void Function(bool)? procPop;

  final GridBookmarkService? gridBookmarks;

  final TagManagerService tagManager;
  final SettingsService settingsService;

  static void open(
    BuildContext context, {
    void Function(bool)? procPop,
  }) {
    final db = Services.of(context);
    final tagManager = db.get<TagManagerService>();
    if (tagManager == null) {
      // TODO: change
      showSnackbar(context, "Search functionality isn't available");

      return;
    }

    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute(
        builder: (context) => BooruSearchPage(
          l10n: context.l10n(),
          procPop: procPop,
          tagManager: tagManager,
          gridBookmarks: db.get<GridBookmarkService>(),
          settingsService: db.require<SettingsService>(),
        ),
      ),
    );
  }

  @override
  State<BooruSearchPage> createState() => _BooruSearchPageState();
}

class _BooruSearchPageState extends State<BooruSearchPage>
    with SettingsWatcherMixin {
  TagManagerService get tagManager => widget.tagManager;
  GridBookmarkService? get gridBookmarks => widget.gridBookmarks;

  @override
  SettingsService get settingsService => widget.settingsService;

  late final Dio client;
  late final BooruAPI api;

  final searchController = TextEditingController();
  final focusNode = FocusNode();

  final _filteringEvents = StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();

    client = BooruAPI.defaultClientForBooru(settings.selectedBooru);
    api = BooruAPI.fromEnum(settings.selectedBooru, client);
  }

  @override
  void dispose() {
    client.close(force: true);
    _filteringEvents.close();

    focusNode.dispose();
    searchController.dispose();

    super.dispose();
  }

  void _onTagPressed(String str, [SafeMode? safeMode]) {
    _onTag(context, api.booru, str, safeMode ?? settings.safeMode);
  }

  void _onTag(
    BuildContext context,
    Booru booru,
    String tag,
    SafeMode? safeMode,
  ) {
    BooruRestoredPage.open(
      context,
      booru: booru,
      tags: tag,
      rootNavigator: true,
      overrideSafeMode: safeMode,
      saveSelectedPage: (_) {},
    );
  }

  void search(bool dialog) {
    if (searchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.l10n.searchTextIsEmpty),
        ),
      );

      return;
    }

    if (dialog) {
      context.openSafeModeDialog(settingsService, (value) {
        _onTagPressed(searchController.text.trim(), value);
      });
    } else {
      _onTagPressed(searchController.text.trim());
    }
  }

  void pinnedTagPressed(String str_) {
    searchController.text = "$str_ ";
    _filteringEvents.add(searchController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _SearchPagePopScope(
        searchController: searchController,
        sink: _filteringEvents.sink,
        procPop: widget.procPop,
        searchFocus: focusNode,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              forceMaterialTransparency: true,
              floating: true,
              automaticallyImplyLeading: false,
              centerTitle: true,
              toolbarHeight: 78,
              title: SizedBox(
                height: 48,
                child: SearchPageSearchBar(
                  complete: null,
                  onSubmit: search,
                  sink: _filteringEvents.sink,
                  searchTextController: searchController,
                  searchFocus: focusNode,
                ),
              ),
            ),
            _RecentlySearchedTagsPanel(
              filteringEvents: _filteringEvents,
              searchController: searchController,
              tagManager: tagManager,
              onTagPressed: _onTagPressed,
            ),
            _PinnedTagsPanel(
              filteringEvents: _filteringEvents.stream,
              tagManager: tagManager,
              api: api,
              onTagPressed: pinnedTagPressed,
            ),
            _ExcludedTagsPanel(
              filteringEvents: _filteringEvents.stream,
              tagManager: tagManager,
              api: api,
            ),
            if (gridBookmarks != null)
              _BookmarksPanel(
                filteringEvents: _filteringEvents.stream,
                gridBookmarks: gridBookmarks!,
              ),
            _TagList(
              filteringEvents: _filteringEvents,
              searchController: searchController,
              api: api,
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

  final Future<List<BooruTag>> Function(String string)? complete;

  final StreamSink<String> sink;

  final void Function(bool dialog) onSubmit;

  static void _doNothing(bool _) {}

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
    final l10n = context.l10n();

    return SearchBarAutocompleteWrapper(
      search: SearchBarAppBarType(
        onChanged: onChanged,
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
          onSubmit(false);
        },
        elevation: const WidgetStatePropertyAll(0),
        focusNode: focus,
        controller: controller,
        onTapOutside: (event) => focus.unfocus(),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 16),
        ),
        onChanged: onChanged,
        hintText: l10n.searchHint,
        leading: _SearchBackIcon(
          searchTextController: searchTextController,
          onSubmit: onSubmit,
        ),
        trailing: [
          IconButton(
            onPressed: clear,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _SearchBackIcon extends StatefulWidget {
  const _SearchBackIcon({
    super.key,
    required this.searchTextController,
    required this.onSubmit,
  });

  final TextEditingController searchTextController;
  final void Function(bool dialog) onSubmit;

  @override
  State<_SearchBackIcon> createState() => __SearchBackIconState();
}

class __SearchBackIconState extends State<_SearchBackIcon> {
  bool isEmpty = true;

  @override
  void initState() {
    super.initState();

    widget.searchTextController.addListener(listener);
  }

  @override
  void dispose() {
    widget.searchTextController.removeListener(listener);

    super.dispose();
  }

  void listener() {
    final newIsEmpty = widget.searchTextController.text.trim().isEmpty;
    if (newIsEmpty != isEmpty) {
      setState(() {
        isEmpty = newIsEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedCrossFade(
      firstChild: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
      ),
      secondChild: IconButton(
        onPressed: () => widget.onSubmit(true),
        icon: const Icon(Icons.search_rounded),
      ),
      crossFadeState:
          isEmpty ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: Durations.medium3,
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
