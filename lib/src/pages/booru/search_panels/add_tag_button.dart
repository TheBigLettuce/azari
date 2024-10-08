// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../search_page.dart";

class _AddTagButton extends StatefulWidget {
  const _AddTagButton({
    super.key,
    required this.tagManager,
    required this.api,
    required this.storage,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.buildTitle,
    required this.onPressed,
  });

  final TagManager tagManager;

  final ReadOnlyStorage<dynamic, TagData> storage;

  final Color backgroundColor;
  final Color foregroundColor;

  final Widget Function(BuildContext context) buildTitle;
  final void Function() onPressed;

  final BooruAPI api;

  @override
  State<_AddTagButton> createState() => __AddTagStateTagButton();
}

class __AddTagStateTagButton extends State<_AddTagButton> {
  late final StreamSubscription<void> subscr;

  @override
  void initState() {
    super.initState();

    subscr = widget.storage.watch((_) {
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
    return widget.storage.count != 0
        ? const SliverPadding(padding: EdgeInsets.zero)
        : SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: _ChipsPanelBody.listPadding +
                    const EdgeInsets.only(top: 12, bottom: 8),
                child: FilledButton.tonalIcon(
                  onPressed: widget.onPressed,
                  label: widget.buildTitle(context),
                  icon: Icon(
                    Icons.tag_rounded,
                    color: widget.foregroundColor,
                  ),
                  style: ButtonStyle(
                    foregroundColor:
                        WidgetStatePropertyAll(widget.foregroundColor),
                    backgroundColor:
                        WidgetStatePropertyAll(widget.backgroundColor),
                  ),
                ),
              ),
            ).animate().fadeIn(),
          );
  }
}
