// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../gallery_search_page.dart";

class _SearchInDirectoriesButtons extends StatelessWidget {
  const _SearchInDirectoriesButtons({
    // super.key,
    required this.filteringValue,
    required this.joinedDirectories,
    required this.source,
    required this.listPadding,
    required this.directoryMetadata,
  });

  final String filteringValue;

  final ResourceSource<int, Directory> source;

  final EdgeInsets listPadding;
  final DirectoryMetadataService? directoryMetadata;

  final void Function(
    String str,
    List<Directory> list, {
    required String tag,
    required FilteringMode? filteringMode,
  }) joinedDirectories;

  void _launchPinned(
    BuildContext context, {
    required bool asTag,
    required DirectoryMetadataService directoryMetadata,
  }) {
    final List<Directory> directories = [];

    final toPin = directoryMetadata.toPinAll.fold(<String, bool>{}, (map, e1) {
      map[e1.categoryName] = e1.sticky;

      return map;
    });

    for (final e in source.backingStorage) {
      final segment = _segment(e);

      if (toPin.containsKey(segment)) {
        directories.add(e);
      }
    }

    _launchDirectories(context, directories, asTag);
  }

  void _launch(
    BuildContext context, {
    required bool asTag,
  }) {
    final directories = source.backingStorage.toList();

    _launchDirectories(context, directories, asTag);
  }

  void _launchDirectories(
    BuildContext context,
    List<Directory> directories,
    bool asTag,
  ) {
    final l10n = context.l10n();

    if (directories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noPinnedDirectories),
        ),
      );

      return;
    }

    // Navigator.pop(context);

    joinedDirectories(
      directories.length == 1
          ? directories.first.name
          : "${directories.length} ${l10n.directoriesPlural}",
      directories,
      tag: filteringValue,
      filteringMode: asTag ? FilteringMode.tag : null,
    );
  }

  String _segment(Directory directory) {
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
    final l10n = context.l10n();

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
                          onPressed: directoryMetadata != null
                              ? () {
                                  _launchPinned(
                                    context,
                                    directoryMetadata: directoryMetadata!,
                                    asTag: true,
                                  );
                                }
                              : null,
                          label: Text(
                            l10n.tagInPinnedDirectories(filteringValue),
                          ),
                          icon: const Icon(Icons.search_outlined),
                        ),
                        TextButton.icon(
                          onPressed: directoryMetadata != null
                              ? () {
                                  _launchPinned(
                                    context,
                                    asTag: false,
                                    directoryMetadata: directoryMetadata!,
                                  );
                                }
                              : null,
                          label: Text(
                            l10n.namesInPinnedDirectories(filteringValue),
                          ),
                          icon: const Icon(Icons.search_outlined),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            _launch(
                              context,
                              asTag: true,
                            );
                          },
                          label: Text(
                            l10n.tagInEverywhere(filteringValue),
                          ),
                          icon: const Icon(Icons.search_outlined),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            _launch(
                              context,
                              asTag: false,
                            );
                          },
                          label: Text(
                            l10n.nameInEverywhere(filteringValue),
                          ),
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
