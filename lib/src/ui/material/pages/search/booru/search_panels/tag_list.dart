// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../booru_search_page.dart";

class _TagList extends StatefulWidget {
  const _TagList({
    // super.key,
    required this.filteringEvents,
    required this.api,
    required this.searchController,
  });

  final StreamController<String> filteringEvents;
  final TextEditingController searchController;

  final BooruAPI api;

  @override
  State<_TagList> createState() => __TagListState();
}

class __TagListState extends State<_TagList> {
  _TagLoadingStatus search = _TagLoadingStatus();

  late final StreamSubscription<String> subscr;

  @override
  void initState() {
    super.initState();

    subscr = widget.filteringEvents.stream.listen((_) {
      final str_ = widget.searchController.text;

      setState(() {
        final str = str_.isEmpty || str_.characters.last == " "
            ? ""
            : str_.trim().split(" ").lastOrNull ?? "";

        if (search.str == str) {
          return;
        }

        search.f?.ignore();

        if (str.isEmpty) {
          search = _TagLoadingStatus();

          return;
        }

        final newSearch = _TagLoadingStatus()..str = str;
        newSearch.f = widget.api.searchTag(str)
          ..then((e) => newSearch.tags = e).whenComplete(
            () => setState(() {
              newSearch.f = null;
            }),
          );

        search = newSearch;
      });
    });
  }

  @override
  void dispose() {
    subscr.cancel();

    search.f?.ignore();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final theme = Theme.of(context);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: FadingPanelLabel(
            horizontalPadding: const EdgeInsets.symmetric(horizontal: 18),
            label: l10n.tagsLabel,
          ),
        ),
        if (search.f != null)
          const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(top: 40),
                child: SizedBox(
                  height: 4,
                  width: 40,
                  child: LinearProgressIndicator(),
                ),
              ),
            ),
          )
        else
          search.tags.isEmpty
              ? SliverPadding(
                  padding:
                      _ChipsPanelBody.listPadding +
                      const EdgeInsets.only(left: 8),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      l10n.startInputingText,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
                )
              : SliverList.builder(
                  itemCount: search.tags.length,
                  itemBuilder: (context, index) {
                    final tag = search.tags[index];

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18 + 8,
                      ),
                      leading: const Icon(Icons.tag_outlined),
                      title: Text(tag.tag),
                      onTap: () {
                        final tags = List<String>.from(
                          widget.searchController.text.split(" "),
                        );

                        if (tags.isNotEmpty) {
                          tags.removeLast();
                          tags.remove(tag.tag);
                        }

                        tags.add(tag.tag);

                        final tagsString = tags.reduce(
                          (value, element) => "$value $element",
                        );

                        widget.searchController.text = "$tagsString ";
                        widget.filteringEvents.add(
                          widget.searchController.text.trim(),
                        );
                      },
                      trailing: Text(tag.count.toString()),
                    );
                  },
                ),
      ],
    );
  }
}

class _TagLoadingStatus {
  _TagLoadingStatus();

  Future<void>? f;
  List<TagData> tags = const [];
  String str = "";
}
