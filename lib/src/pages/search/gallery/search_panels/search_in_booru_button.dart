// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../gallery_search_page.dart";

class _SearchInBooruButton extends StatefulWidget {
  const _SearchInBooruButton({
    // super.key,
    required this.onPressed,
    required this.filteringEvents,
  });

  final Stream<String> filteringEvents;

  final VoidCallback onPressed;

  @override
  State<_SearchInBooruButton> createState() => __SearchInBooruButtonState();
}

class __SearchInBooruButtonState extends State<_SearchInBooruButton> {
  String filteringValue = "";
  late final StreamSubscription<String> subscr;

  @override
  void initState() {
    super.initState();

    subscr = widget.filteringEvents.listen((str) {
      setState(() {
        filteringValue = str;
      });
    });
  }

  @override
  void dispose() {
    subscr.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();

    return filteringValue.isEmpty
        ? const SliverPadding(padding: EdgeInsets.zero)
        : SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: _ChipsPanelBody.listPadding +
                    const EdgeInsets.only(top: 12, bottom: 8),
                child: FilledButton.tonalIcon(
                  onPressed: widget.onPressed,
                  label: Text(l10n.tagInBooru(filteringValue)),
                  icon: const Icon(Icons.search_rounded),
                ),
              ),
            ).animate().fadeIn(),
          );
  }
}
