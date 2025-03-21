// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../booru_search_page.dart";

class _ExcludedTagsPanel extends StatefulWidget {
  const _ExcludedTagsPanel({
    // super.key,
    required this.filteringEvents,
    required this.tagManager,
    required this.api,
  });

  final Stream<String> filteringEvents;
  final TagManagerService tagManager;

  final BooruAPI api;

  @override
  State<_ExcludedTagsPanel> createState() => __ExcludedTagsPanelState();
}

class __ExcludedTagsPanelState extends State<_ExcludedTagsPanel> {
  String filteringValue = "";
  late final GenericListSource<TagData> source = GenericListSource(
    () => Future.value(widget.tagManager.excluded.complete(filteringValue)),
    watchCount: widget.tagManager.excluded.watchCount,
  );

  late final StreamSubscription<String> filteringSubscr;

  @override
  void initState() {
    super.initState();

    filteringSubscr = widget.filteringEvents.listen((str_) {
      setState(() {
        final str =
            str_.isEmpty ? "" : str_.trim().split(" ").lastOrNull?.trim() ?? "";

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

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: FadingPanel(
            label: l10n.excludedTagsLabel,
            source: source,
            enableHide: false,
            trailing: (
              Icons.add_rounded,
              () {
                Navigator.of(context, rootNavigator: true).push(
                  DialogRoute<void>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(l10n.addToExcluded),
                        content: AutocompleteWidget(
                          null,
                          (s) {},
                          swapSearchIcon: false,
                          (s) {
                            widget.tagManager.excluded.add(s.trim());

                            Navigator.pop(context);
                          },
                          () {},
                          widget.api.searchTag,
                          null,
                          submitOnPress: true,
                          roundBorders: true,
                          plainSearchBar: true,
                          showSearch: true,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            childSize: _ChipsPanelBody.size,
            child: _ChipsPanelBody(
              source: source,
              onTagPressed: (str) {
                Navigator.push(
                  context,
                  DialogRoute<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.removeTag(str)),
                      actions: [
                        TextButton(
                          onPressed: () {
                            widget.tagManager.excluded.delete(str);
                            Navigator.pop(context);
                          },
                          child: Text(l10n.yes),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(l10n.no),
                        ),
                      ],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.tag_rounded),
              backgroundColor: Colors.pink.shade300,
              foregroundColor: Colors.black.withValues(alpha: 0.8),
            ),
          ),
        ),
        _AddTagButton(
          tagManager: widget.tagManager,
          storage: source.backingStorage,
          api: widget.api,
          foregroundColor: Colors.black.withValues(alpha: 0.8),
          backgroundColor: Colors.pink.shade300,
          buildTitle: (context) => Text(
            filteringValue.isNotEmpty
                ? l10n.addTagToExcluded(filteringValue)
                : l10n.addToExcluded,
          ),
          onPressed: () {
            if (filteringValue.isNotEmpty) {
              widget.tagManager.excluded.add(filteringValue);

              return;
            }

            Navigator.of(context, rootNavigator: true).push(
              DialogRoute<void>(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Text(l10n.addToExcluded),
                    content: AutocompleteWidget(
                      null,
                      (s) {},
                      swapSearchIcon: false,
                      (s) {
                        widget.tagManager.excluded.add(s);

                        Navigator.pop(context);
                      },
                      () {},
                      widget.api.searchTag,
                      null,
                      submitOnPress: true,
                      roundBorders: true,
                      plainSearchBar: true,
                      showSearch: true,
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
