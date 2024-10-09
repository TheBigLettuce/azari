// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../search_page.dart";

class _SearchInDirectoriesButtons extends StatelessWidget {
  const _SearchInDirectoriesButtons({
    super.key,
    required this.db,
    required this.filteringValue,
    required this.joinedDirectories,
    required this.source,
    required this.listPadding,
  });

  final ResourceSource<int, GalleryDirectory> source;

  final EdgeInsets listPadding;
  final String filteringValue;

  final void Function(
    String str,
    List<GalleryDirectory> list, {
    required String tag,
    required FilteringMode? filteringMode,
  }) joinedDirectories;

  final DbConn db;

  void _launch(BuildContext context, bool asTag) {
    final l10n = AppLocalizations.of(context)!;

    final toPin =
        db.directoryMetadata.toPinAll.fold(<String, bool>{}, (map, e1) {
      map[e1.categoryName] = e1.sticky;

      return map;
    });

    final List<GalleryDirectory> pinned = [];

    for (final e in source.backingStorage) {
      final segment = _segment(e);

      if (toPin.containsKey(segment)) {
        pinned.add(e);
      }
    }

    if (pinned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No pinned directories found"),
        ), // TODO: change
      );

      return;
    }

    Navigator.pop(context);

    joinedDirectories(
      pinned.length == 1
          ? pinned.first.name
          : "${pinned.length} ${l10n.directoriesPlural}",
      pinned,
      tag: filteringValue,
      filteringMode: asTag ? FilteringMode.tag : null,
    );
  }

  String _segment(GalleryDirectory directory) {
    for (final booru in Booru.values) {
      if (booru.url == directory.name) {
        return "Booru";
      }
    }

    if (directory.tag.isNotEmpty) {
      return directory.tag;
    }

    return directory.name.split(" ").first.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      sliver: SliverToBoxAdapter(
        child: AnimatedSize(
          duration: Durations.medium3,
          alignment: Alignment.topCenter,
          curve: Easing.standard,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SingleChildScrollView(
              padding: listPadding,
              scrollDirection: Axis.horizontal,
              child: filteringValue.isEmpty
                  ? const SizedBox.shrink()
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            _launch(context, true);
                          },
                          label: Text("#$filteringValue in pinned directories"),
                          icon: const Icon(Icons.search_outlined),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            _launch(context, false);
                          },
                          label:
                              Text("'$filteringValue' in pinned directories"),
                          icon: const Icon(Icons.search_outlined),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
