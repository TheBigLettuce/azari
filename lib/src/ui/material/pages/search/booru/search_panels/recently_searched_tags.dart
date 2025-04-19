// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../booru_search_page.dart";

class _RecentlySearchedTagsPanel extends StatefulWidget {
  const _RecentlySearchedTagsPanel({
    // super.key,
    required this.filteringEvents,
    required this.tagManager,
    required this.onTagPressed,
    required this.searchController,
  });

  final StreamController<String> filteringEvents;
  final TextEditingController searchController;
  final TagManagerService tagManager;

  final StringCallback onTagPressed;

  @override
  State<_RecentlySearchedTagsPanel> createState() =>
      __RecentlySearchedTagsPanelState();
}

class __RecentlySearchedTagsPanelState
    extends State<_RecentlySearchedTagsPanel> {
  String filteringValue = "";
  late final GenericListSource<TagData> source = GenericListSource(
    () => Future.value(widget.tagManager.latest.complete(filteringValue)),
    watchCount: (f, [_ = false]) => widget.tagManager.latest.events.listen(f),
  );

  late final StreamSubscription<String> filteringSubscr;

  @override
  void initState() {
    super.initState();

    filteringSubscr = widget.filteringEvents.stream.listen((str) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return SliverToBoxAdapter(
      child: FadingPanel(
        label: l10n.recentlySearched,
        source: source,
        enableHide: false,
        trailing: (
          Icons.delete_sweep_outlined,
          () => widget.tagManager.latest.clear(),
        ),
        childSize: _ChipsPanelBody.size,
        child: _ChipsPanelBody(
          source: source,
          onTagLongPressed: widget.onTagPressed,
          onTagPressed: (str) {
            widget.searchController.text = str;
            widget.filteringEvents.add(str.trim());
          },
          icon: null,
        ),
      ),
    );
  }
}
