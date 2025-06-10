// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../booru_search_page.dart";

class _BookmarksPanel extends StatefulWidget {
  const _BookmarksPanel({
    // super.key,
    required this.filteringEvents,
    required this.gridBookmarks,
  });

  final Stream<String> filteringEvents;

  final GridBookmarkService gridBookmarks;

  @override
  State<_BookmarksPanel> createState() => __BookmarksPanelState();
}

class __BookmarksPanelState extends State<_BookmarksPanel> {
  String filteringValue = "";
  late final GenericListSource<GridBookmark> source = GenericListSource(
    () => filteringValue.isEmpty
        ? Future.value(const [])
        : Future.value(widget.gridBookmarks.complete(filteringValue)),
    watchCount: widget.gridBookmarks.watch,
  );

  late final StreamSubscription<String> filteringSubscr;

  @override
  void initState() {
    super.initState();

    filteringSubscr = widget.filteringEvents.listen((str) {
      setState(() {
        filteringValue = str;
        source.clearRefresh();
      });
    });

    source.clearRefresh();
  }

  @override
  void dispose() {
    source.destroy();
    filteringSubscr.cancel();

    super.dispose();
  }

  void _onPressed(GridBookmark bookmark) {
    // Navigator.pop(context);

    BooruRestoredPage.open(
      context,
      booru: bookmark.booru,
      tags: bookmark.tags,
      name: bookmark.name,
    );
  }

  void _onLongPressed(GridBookmark bookmark) {}

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return SliverToBoxAdapter(
      child: FadingPanel(
        label: l10n.bookmarksPageName,
        source: source,
        enableHide: false,
        childSize: _BookmarksPanelBody.size,
        child: _BookmarksPanelBody(
          source: source,
          onPressed: _onPressed,
          onLongPressed: _onLongPressed,
        ),
      ),
    );
  }
}
