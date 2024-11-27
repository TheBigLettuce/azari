// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../search_page.dart";

class _BookmarksPanelBody extends StatefulWidget {
  const _BookmarksPanelBody({
    // super.key,
    required this.source,
    required this.onPressed,
    required this.onLongPressed,
  });

  final GenericListSource<GridBookmark> source;

  final void Function(GridBookmark)? onPressed;
  final void Function(GridBookmark)? onLongPressed;

  static const size = Size(120 / 1.2, 120);
  static const listPadding = EdgeInsets.symmetric(horizontal: 18 + 4);

  @override
  State<_BookmarksPanelBody> createState() => _BookmarksPanelBodyState();
}

class _BookmarksPanelBodyState extends State<_BookmarksPanelBody> {
  GenericListSource<GridBookmark> get source => widget.source;

  late final StreamSubscription<void> subscr;

  @override
  void initState() {
    super.initState();

    subscr = widget.source.progress.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    subscr.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: _BookmarksPanelBody.size.height,
      child: widget.source.progress.inRefreshing
          ? const ShimmerPlaceholdersMiniBookmark(
              padding: _BookmarksPanelBody.listPadding,
            )
          : ListView.builder(
              padding: _BookmarksPanelBody.listPadding,
              scrollDirection: Axis.horizontal,
              itemCount: source.backingStorage.count,
              itemBuilder: (context, i) {
                final cell = source.backingStorage[i];

                return Padding(
                  padding: const EdgeInsets.all(4),
                  child: SizedBox(
                    width: _BookmarksPanelBody.size.width,
                    child: _MiniBookmark(
                      bookmark: cell,
                      onPressed: widget.onPressed,
                      onLongPressed: widget.onLongPressed,
                    ),
                  ),
                );
              },
            ).animate().fadeIn(),
    );
  }
}

class ShimmerPlaceholdersMiniBookmark extends StatelessWidget {
  const ShimmerPlaceholdersMiniBookmark({
    super.key,
    this.childPadding = const EdgeInsets.all(4),
    this.padding = EdgeInsets.zero,
  });

  final EdgeInsets childPadding;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 15,
      padding: padding,
      scrollDirection: Axis.horizontal,
      itemBuilder: (context, index) {
        return Padding(
          padding: childPadding,
          child: SizedBox(
            key: ValueKey(index),
            width: _BookmarksPanelBody.size.width,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: const ShimmerLoadingIndicator(
                delay: Duration(milliseconds: 900),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniBookmark extends StatelessWidget {
  const _MiniBookmark({
    // super.key,
    required this.bookmark,
    required this.onPressed,
    required this.onLongPressed,
  });

  final GridBookmark bookmark;

  final void Function(GridBookmark)? onPressed;
  final void Function(GridBookmark)? onLongPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onPressed == null ? null : () => onPressed!(bookmark),
        onLongPress:
            onLongPressed == null ? null : () => onLongPressed!(bookmark),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (bookmark.thumbnails.isEmpty)
              Expanded(
                flex: 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                  ),
                  child: const SizedBox.expand(),
                ),
              )
            else
              Expanded(
                flex: 3,
                child: SizedBox.expand(
                  child: Image(
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    image: CachedNetworkImageProvider(
                      bookmark.thumbnails.first.url,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: SizedBox.expand(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Align(
                      child: Text(
                        bookmark.tags,
                        overflow: TextOverflow.fade,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
