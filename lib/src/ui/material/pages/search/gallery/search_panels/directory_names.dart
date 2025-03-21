// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../gallery_search_page.dart";

class _DirectoryNamesPanel extends StatefulWidget {
  const _DirectoryNamesPanel({
    // super.key,
    required this.filteringEvents,
    required this.searchController,
    required this.directoryComplete,
    required this.api,
  });

  final Directories api;

  final StreamController<String> filteringEvents;
  final TextEditingController searchController;

  final Future<List<BooruTag>> Function(String str) directoryComplete;

  @override
  State<_DirectoryNamesPanel> createState() => __DirectoryNamesPanelState();
}

class __DirectoryNamesPanelState extends State<_DirectoryNamesPanel> {
  String filteringValue = "";
  late final GenericListSource<BooruTag> source = GenericListSource(
    () => Future.value(widget.directoryComplete(filteringValue)),
    watchCount: widget.api.source.backingStorage.watch,
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
        label: l10n.directoryNames,
        source: source,
        enableHide: false,
        childSize: _ChipsPanelBody.size,
        child: _ChipsPanelBody(
          source: source,
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
