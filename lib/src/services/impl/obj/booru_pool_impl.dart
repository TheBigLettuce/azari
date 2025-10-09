// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/logic/net/booru/booru_api.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/material/pages/discover/discover.dart";
import "package:azari/src/ui/material/widgets/grid_cell_widget.dart";
import "package:azari/src/ui/material/widgets/shell/layouts/cell_builder.dart";
import "package:cached_network_image/cached_network_image.dart";
import "package:flutter/material.dart";
import "package:transparent_image/transparent_image.dart";

abstract class BooruPoolImpl
    with CellBuilderData
    implements BooruPool, CellBuilder {
  const BooruPoolImpl();

  @override
  Key uniqueKey() => ValueKey(id);

  @override
  String title(AppLocalizations l10n) => name;

  @override
  ImageProvider<Object>? thumbnail() =>
      thumbUrl.isEmpty ? null : CachedNetworkImageProvider(thumbUrl);

  @override
  bool tightMode() => true;

  @override
  Widget buildCell(
    AppLocalizations l10n, {
    required CellType cellType,
    required bool hideName,
    bool blur = false,
    Alignment imageAlign = Alignment.center,
  }) => BooruPoolCell(cell: this);
}

class BooruPoolCell extends StatelessWidget {
  const BooruPoolCell({super.key, required this.cell});

  final BooruPool cell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n();
    final theme = Theme.of(context);

    final onPressed = OnPoolPressed.maybeOf(context);

    final thumb = cell.thumbnail();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        color: theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.65),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(26),
                      onTap: onPressed != null ? () => onPressed(cell) : null,
                      child: GridCellImage(
                        blur: false,
                        imageAlign: Alignment.topCenter,
                        thumbnail: thumb ?? MemoryImage(kTransparentImage),
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Padding(padding: EdgeInsets.only(top: 20)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                cell.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                ),
                overflow: TextOverflow.ellipsis,

                maxLines: 2,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: switch (cell.category) {
                          BooruPoolCategory.series =>
                            theme.colorScheme.surfaceContainerLow,
                          BooruPoolCategory.collection =>
                            theme.colorScheme.surfaceContainerLow,
                        },
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 2,
                          horizontal: 6,
                        ),
                        child: Text(
                          cell.category.translatedString(l10n),
                          style: switch (cell.category) {
                            BooruPoolCategory.series =>
                              theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.8,
                                ),
                              ),
                            BooruPoolCategory.collection =>
                              theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 1,
                                ),
                              ),
                          },
                        ),
                      ),
                    ),
                    const Padding(padding: EdgeInsets.only(right: 4)),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(4),
                        ),
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "${cell.postIds.length} ",
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                              TextSpan(
                                text: "posts",
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
