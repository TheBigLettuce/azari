// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

// import "package:azari/src/pages/anime/info_base/background_image/background_image.dart";
import "package:flutter/material.dart";

class UnsizedCard extends StatelessWidget {
  const UnsizedCard({
    super.key,
    required this.subtitle,
    required this.title,
    // this.backgroundImage,
    required this.tooltip,
    this.transparentBackground = false,
    this.onPressed,
    this.leanToLeft = true,
    this.onLongPressed,
  });

  final bool leanToLeft;
  final bool transparentBackground;

  final String tooltip;

  final Widget title;
  final Widget subtitle;

  // final ImageProvider? backgroundImage;

  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      onLongPressed: onLongPressed,
      subtitle: subtitle,
      title: title,
      // backgroundImage: backgroundImage,
      tooltip: tooltip,
      transparentBackground: transparentBackground,
      onPressed: onPressed,
      width: null,
      height: null,
      leanLeft: leanToLeft,
    );
  }
}

class BaseCard extends StatelessWidget {
  const BaseCard({
    super.key,
    // this.backgroundImage,
    required this.subtitle,
    required this.title,
    required this.tooltip,
    this.height = 80,
    this.width = 100,
    this.expandTitle = false,
    this.transparentBackground = false,
    this.onPressed,
    this.onLongPressed,
    this.footer,
    this.leanLeft = false,
  });

  final bool expandTitle;
  final bool leanLeft;
  final bool transparentBackground;

  final double? width;
  final double? height;

  final String tooltip;

  final Widget title;
  final Widget subtitle;
  final Widget? footer;

  // final ImageProvider? backgroundImage;

  final VoidCallback? onPressed;
  final VoidCallback? onLongPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final body = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment:
                leanLeft ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              const SizedBox.shrink(),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: leanLeft
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    DefaultTextStyle.merge(
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: DefaultTextStyle.of(context).style.color ??
                            colorScheme.secondary.withValues(alpha: 0.8),
                        letterSpacing: 0.8,
                      ),
                      child: Padding(
                        padding: height == null
                            ? EdgeInsets.zero
                            : EdgeInsets.only(
                                left: leanLeft ? 0 : 4,
                                right: leanLeft ? 24 : 8,
                                top: 4,
                                bottom: 4,
                              ),
                        child: expandTitle ? Expanded(child: title) : title,
                      ),
                    ),
                    if (constraints.maxWidth > 50)
                      DefaultTextStyle.merge(
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: leanLeft ? 0 : 16,
                            right: leanLeft ? 24 : 16,
                          ),
                          child: subtitle,
                        ),
                      ),
                  ],
                ),
              ),
              if (footer != null)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: footer,
                  ),
                ),
            ],
          ),
        );

        final card = InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onPressed,
          onLongPress: onLongPressed,
          splashColor: colorScheme.onSurface.withValues(alpha: 0.6),
          child: Card.filled(
            clipBehavior: Clip.antiAlias,
            color: transparentBackground
                // || backgroundImage != null
                ? colorScheme.onSurface.withValues(alpha: 0)
                : null,
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  // if (backgroundImage != null)
                  // BackgroundImageBase(image: backgroundImage!),
                  body,
                ],
              ),
            ),
          ),
        );

        return constraints.maxWidth > 50
            ? card
            : Tooltip(
                message: tooltip,
                child: card,
              );
      },
    );
  }
}

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.subtitle,
    required this.title,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      tooltip: subtitle,
      subtitle: Text(
        subtitle,
        textAlign: TextAlign.center,
      ),
      title: Text(
        title,
      ),
    );
  }
}
