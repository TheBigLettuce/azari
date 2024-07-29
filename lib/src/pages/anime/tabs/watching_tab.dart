// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../anime.dart";

class MangaReadingCard<T extends CompactMangaData> extends StatelessWidget {
  const MangaReadingCard({
    super.key,
    required this.cell,
    required this.onPressed,
    required this.idx,
    this.onLongPressed,
    required this.db,
  });

  final T cell;
  final int idx;
  final void Function(T cell, int idx)? onPressed;
  final void Function(T cell, int idx)? onLongPressed;

  final ReadMangaChaptersService db;

  void _onLongPressed() => onLongPressed!(cell, idx);

  void _onPressed() => onPressed!(cell, idx);

  @override
  Widget build(BuildContext context) {
    final lastRead = db.firstForId(cell.mangaId);
    final theme = Theme.of(context);
    final textTheme = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurface.withOpacity(0.7),
    );

    return BaseCard(
      onLongPressed: onLongPressed == null ? null : _onLongPressed,
      subtitle: Text(
        cell.alias(false),
        maxLines: 2,
      ),
      title: SizedBox(
        height: 40,
        width: 40,
        child: GridCell(
          cell: cell,
          hideTitle: true,
        ),
      ),
      backgroundImage: cell.tryAsThumbnailable(),
      tooltip: cell.alias(false),
      onPressed: onPressed == null ? null : _onPressed,
      width: null,
      height: null,
      footer: lastRead != null
          ? RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  if (lastRead.chapterName.isNotEmpty)
                    TextSpan(
                      text: "${lastRead.chapterName} ",
                      style: textTheme,
                    ),
                  TextSpan(
                    text:
                        "${lastRead.chapterNumber} - ${lastRead.chapterProgress}\n",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  TextSpan(
                    text: AppLocalizations.of(context)!
                        .date(lastRead.lastUpdated),
                    style: textTheme?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }
}

class ImportantCard<T extends CellBase> extends StatelessWidget {
  const ImportantCard({
    super.key,
    required this.cell,
    required this.onPressed,
    required this.idx,
    this.onLongPressed,
  });

  final T cell;
  final int idx;
  final void Function(T cell, int idx)? onPressed;
  final void Function(T cell, int idx)? onLongPressed;

  @override
  Widget build(BuildContext context) {
    return UnsizedCard(
      leanToLeft: false,
      subtitle: Text(cell.alias(false)),
      title: SizedBox(
        height: 40,
        width: 40,
        child: GridCell(
          cell: cell,
          hideTitle: true,
        ),
      ),
      backgroundImage: cell.tryAsThumbnailable(),
      tooltip: cell.alias(false),
      onLongPressed: onLongPressed == null
          ? null
          : () {
              onLongPressed!(cell, idx);
            },
      onPressed: onPressed == null
          ? null
          : () {
              onPressed!(cell, idx);
            },
    );
  }
}
