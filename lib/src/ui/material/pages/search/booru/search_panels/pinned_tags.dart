// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../booru_search_page.dart";

class _PinnedTagsPanel extends StatefulWidget {
  const _PinnedTagsPanel({
    // super.key,
    required this.filteringEvents,
    required this.tagManager,
    required this.onTagPressed,
    required this.api,
  });

  final Stream<String> filteringEvents;
  final TagManagerService tagManager;

  final BooruAPI api;

  final StringCallback onTagPressed;

  @override
  State<_PinnedTagsPanel> createState() => __PinnedTagsPanelState();
}

class __PinnedTagsPanelState extends State<_PinnedTagsPanel> {
  String filteringValue = "";
  late final GenericListSource<TagData> source = GenericListSource(
    () => Future.value(widget.tagManager.pinned.complete(filteringValue)),
    watchCount: (f, [_ = false]) => widget.tagManager.latest.events.listen(f),
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
    final theme = Theme.of(context);

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: FadingPanel(
            label: l10n.pinnedTags,
            source: source,
            enableHide: false,
            trailing: (
              Icons.add_rounded,
              () => BooruSearchPage.openPinTagDialogDialog(context, widget.api),
            ),
            childSize: _ChipsPanelBody.size,
            child: _ChipsPanelBody(
              onTagLongPressed: (str) =>
                  BooruSearchPage.openRemovePinnedTagDialog(context, str),
              source: source,
              onTagPressed: widget.onTagPressed,
              icon: const Icon(Icons.push_pin_rounded),
            ),
          ),
        ),
        _AddTagButton(
          tagManager: widget.tagManager,
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
              widget.tagManager.pinned.add(filteringValue);

              return;
            }

            BooruSearchPage.openPinTagDialogDialog(context, widget.api);
          },
        ),
      ],
    );
  }
}
