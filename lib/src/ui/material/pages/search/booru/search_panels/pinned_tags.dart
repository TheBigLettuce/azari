// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../booru_search_page.dart";

class PinnedTagsPanel extends StatefulWidget {
  const PinnedTagsPanel({
    super.key,
    required this.filteringEvents,
    required this.onTagPressed,
    required this.api,
    this.sliver = true,
  });

  final bool sliver;
  final Stream<String> filteringEvents;

  final BooruAPI api;

  final StringCallback onTagPressed;

  @override
  State<PinnedTagsPanel> createState() => _PinnedTagsPanelState();
}

class _PinnedTagsPanelState extends State<PinnedTagsPanel>
    with TagManagerService {
  String filteringValue = "";
  late final GenericListSource<TagData> source = GenericListSource(
    () => Future.value(
      filteringValue.trim().isEmpty
          ? _pinnedTags.keys
                .map(
                  (e) => TagData(
                    tag: e,
                    type: TagType.pinned,
                    time: null,
                    count: 0,
                  ),
                )
                .toList()
          : pinned.complete(filteringValue),
    ),
    watchCount: (f, [_ = false]) => latest.events.listen(f),
  );

  late final StreamSubscription<String> filteringSubscr;
  Map<String, void> _pinnedTags = {};

  @override
  void initState() {
    super.initState();

    filteringSubscr = widget.filteringEvents.listen((str_) {
      setState(() {
        final str = str_.isEmpty
            ? ""
            : str_.trim().split(" ").lastOrNull?.trim() ?? "";

        filteringValue = str;
        source.clearRefresh();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final newPinnedTags = PinnedTagsProvider.of(context).map;
    if (_pinnedTags != newPinnedTags) {
      _pinnedTags = newPinnedTags;
      source.clearRefresh();
    }
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
    final theme = Theme.of(context);

    final panel = FadingPanel(
      label: l10n.pinnedTags,
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
                  title: Text(l10n.pinTag),
                  content: AutocompleteWidget(
                    null,
                    (s) {},
                    swapSearchIcon: false,
                    (s) {
                      pinned.add(s.trim());

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
        onTagLongPressed: (str) => Navigator.push(
          context,
          DialogRoute<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(l10n.removeTag(str)),
              actions: [
                TextButton(
                  onPressed: () {
                    pinned.delete(str);
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
        ),
        source: source,
        onTagPressed: widget.onTagPressed,
        icon: const Icon(Icons.push_pin_rounded),
      ),
    );

    final button = _AddTagButton(
      sliver: widget.sliver,
      tagManager: this,
      storage: source.backingStorage,
      api: widget.api,
      foregroundColor: theme.colorScheme.onPrimary,
      backgroundColor: theme.colorScheme.primary,
      buildTitle: (context) => Text(
        filteringValue.isNotEmpty
            ? l10n.addTagToPinned(filteringValue)
            : l10n.addPinnedTag,
      ),
      onPressed: () {
        if (filteringValue.isNotEmpty) {
          pinned.add(filteringValue);

          return;
        }

        Navigator.of(context, rootNavigator: true).push(
          DialogRoute<void>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(l10n.addPinnedTag),
                content: AutocompleteWidget(
                  null,
                  (s) {},
                  swapSearchIcon: false,
                  (s) {
                    pinned.add(s.trim());

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
    );

    if (!widget.sliver) {
      return Column(children: [panel, button]);
    }

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(child: panel),
        button,
      ],
    );
  }
}
