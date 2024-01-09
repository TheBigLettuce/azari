// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'anime_inner.dart';

class AnimeInnerBody extends StatefulWidget {
  final AnimeEntry entry;
  final AnimeAPI api;
  final EdgeInsets viewPadding;

  const AnimeInnerBody({
    super.key,
    required this.entry,
    required this.viewPadding,
    required this.api,
  });

  @override
  State<AnimeInnerBody> createState() => _AnimeInnerBodyState();
}

class _AnimeInnerBodyState extends State<AnimeInnerBody> {
  @override
  Widget build(BuildContext context) {
    return BodyPadding(
      viewPadding: widget.viewPadding,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 4,
                children: widget.entry.genres
                    .map((e) => Chip(
                          surfaceTintColor:
                              Theme.of(context).colorScheme.surfaceTint,
                          elevation: 4,
                          labelStyle: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.8)),
                          visualDensity: VisualDensity.compact,
                          label: Text(e),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25)),
                        ))
                    .toList(),
              ),
            ),
            const Padding(padding: EdgeInsets.only(top: 8)),
            _SegmentConstrained(
              api: widget.api,
              entry: widget.entry,
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width - 16 - 16),
            ),
            AnimeCharactersWidget(api: widget.api, entry: widget.entry),
            AnimeRelations(entry: widget.entry)
          ],
        ),
      ),
    );
  }
}

class AnimeRelations extends StatelessWidget {
  final AnimeEntry entry;

  const AnimeRelations({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return entry.relations.isEmpty
        ? const SizedBox.shrink()
        : Column(
            children: [
              const _Label(text: "Related"),
              Text(
                entry.relations.map((e) => e.title).join(", "),
                overflow: TextOverflow.fade,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8)),
              ),
            ],
          );
  }
}

class AnimeCharactersWidget extends StatefulWidget {
  final AnimeAPI api;
  final AnimeEntry entry;

  const AnimeCharactersWidget(
      {super.key, required this.api, required this.entry});

  @override
  State<AnimeCharactersWidget> createState() => _AnimeCharactersWidgetState();
}

class _AnimeCharactersWidgetState extends State<AnimeCharactersWidget> {
  late final StreamSubscription<SavedAnimeCharacters?> watcher;
  // Future<List<AnimeCharacter>>? future;
  bool _loading = false;
  List<AnimeCharacter> list = [];

  @override
  void initState() {
    super.initState();

    final l = SavedAnimeCharacters.load(widget.entry.id, widget.entry.site);
    if (l.isNotEmpty) {
      list.addAll(l);
    } else {
      SavedAnimeCharacters.addAsync(widget.entry, widget.api);
      _loading = true;
    }

    watcher =
        SavedAnimeCharacters.watch(widget.entry.id, widget.entry.site, (e) {
      list = e!.characters;
      _loading = false;

      setState(() {});
    });
  }

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  // void _load() {
  //   future = widget.api.characters(widget.entry).then((value) {
  //     list = value;

  //     setState(() {});

  //     return value;
  //   }).whenComplete(() => future = null);

  //   setState(() {});
  // }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!_loading) const _Label(text: "Characters"),
        _loading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  children: list.indexed
                      .map((e) => SizedBox(
                            height:
                                MediaQuery.sizeOf(context).longestSide * 0.2,
                            width: MediaQuery.sizeOf(context).longestSide *
                                0.2 *
                                GridAspectRatio.zeroFive.value,
                            child: GridCell(
                              cell: e.$2,
                              indx: e.$1,
                              onPressed: null,
                              tight: false,
                              download: null,
                              isList: false,
                              labelAtBottom: true,
                            ),
                          ))
                      .toList(),
                ),
              ),
      ],
    ).animate().fadeIn();
  }
}

class BodyPadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets viewPadding;

  const BodyPadding(
      {super.key, required this.viewPadding, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.sizeOf(context).height * 0.3 +
            kToolbarHeight +
            viewPadding.top,
        left: 8,
        right: 8,
      ),
      child: child,
    );
  }
}
