// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../gallery_search_page.dart";

class _LocalTagsPanel extends StatefulWidget {
  const _LocalTagsPanel({
    // super.key,
    required this.filteringEvents,
    required this.searchController,
    required this.db,
    required this.source,
    required this.joinedDirectories,
  });

  final StreamController<String> filteringEvents;
  final TextEditingController searchController;

  final ResourceSource<int, Directory> source;

  final void Function(
    String str,
    List<Directory> list, {
    required String tag,
    required FilteringMode? filteringMode,
  }) joinedDirectories;

  final DbConn db;

  @override
  State<_LocalTagsPanel> createState() => __LocalTagsPanelState();
}

class __LocalTagsPanelState extends State<_LocalTagsPanel> {
  String filteringValue = "";
  late final GenericListSource<BooruTag> source = GenericListSource(
    () => widget.db.localTagDictionary.complete(filteringValue),
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

  bool _isBooruGroup(Directory directory) {
    for (final booru in Booru.values) {
      if (booru.url == directory.name) {
        return true;
      }
    }

    return directory.tag == "Booru";
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: FadingPanel(
            label: l10n.tagsLabel,
            source: source,
            enableHide: false,
            childSize: _ChipsPanelBody.size,
            child: _ChipsPanelBody(
              source: source,
              onTagPressed: (str) {
                widget.searchController.text = str;
                widget.filteringEvents.add(str.trim());
              },
              icon: const Icon(Icons.tag_rounded),
            ),
          ),
        ),
        _SearchInBooruButton(
          onPressed: () {
            final List<Directory> booru = [];

            for (final e in widget.source.backingStorage) {
              if (_isBooruGroup(e)) {
                booru.add(e);
              }
            }

            if (booru.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.noBooruDirectories),
                ),
              );

              return;
            }

            // Navigator.pop(context);

            widget.joinedDirectories(
              "Booru",
              booru,
              tag: filteringValue,
              filteringMode: FilteringMode.tag,
            );
          },
          filteringEvents: widget.filteringEvents.stream,
        ),
      ],
    );
  }
}
