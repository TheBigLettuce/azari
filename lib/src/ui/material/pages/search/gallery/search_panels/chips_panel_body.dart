// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../gallery_search_page.dart";

class _ChipsPanelBody extends StatefulWidget {
  const _ChipsPanelBody({
    // super.key,
    required this.source,
    required this.onTagPressed,
    required this.icon,
  });

  final GenericListSource<BooruTag> source;

  final void Function(String)? onTagPressed;

  final Icon? icon;

  static const size = Size(0, 42);
  static const listPadding = EdgeInsets.symmetric(horizontal: 18 + 4);

  @override
  State<_ChipsPanelBody> createState() => __ChipsPanelBodyState();
}

class __ChipsPanelBodyState extends State<_ChipsPanelBody> {
  GenericListSource<BooruTag> get source => widget.source;

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
      height: 42,
      child: widget.source.progress.inRefreshing
          ? const ShimmerPlaceholdersChips(
              padding: _ChipsPanelBody.listPadding,
            )
          : ListView.builder(
              padding: _ChipsPanelBody.listPadding,
              scrollDirection: Axis.horizontal,
              itemCount: source.backingStorage.count,
              itemBuilder: (context, i) {
                final cell = source.backingStorage[i];

                return Padding(
                  padding: const EdgeInsets.all(4),
                  child: ActionChip(
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onTagPressed == null
                        ? null
                        : () {
                            widget.onTagPressed!(cell.tag);
                          },
                    label: Text(cell.tag),
                    avatar: widget.icon,
                  ),
                );
              },
            ).animate().fadeIn(),
    );
  }
}
