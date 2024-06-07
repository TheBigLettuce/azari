// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/widgets/make_tags.dart";
import "package:gallery/src/widgets/menu_wrapper.dart";

class TagsWidget extends StatefulWidget {
  const TagsWidget({
    super.key,
    this.redBackground = false,
    required this.tagging,
    required this.onPress,
    this.leading,
  });

  final void Function(String tag, SafeMode? safeMode)? onPress;
  final bool redBackground;
  final BooruTagging tagging;
  final Widget? leading;

  @override
  State<TagsWidget> createState() => _TagsWidgetState();
}

class _TagsWidgetState extends State<TagsWidget> {
  late final StreamSubscription<void> watcher;
  late final List<TagData> _tags = widget.tagging.get(30);
  int refreshes = 0;

  @override
  void initState() {
    super.initState();

    watcher = widget.tagging.watch((_) {
      _tags.clear();
      setState(() {});

      _tags.addAll(widget.tagging.get(30));

      setState(() {
        refreshes += 1;
      });
    });
  }

  @override
  void dispose() {
    watcher.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Animate(
      effects: slideFadeEffects,
      child: _tags.isEmpty
          ? Row(
              children: [
                if (widget.leading != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: widget.leading,
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.label_off_rounded,
                        size: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                      const Padding(padding: EdgeInsets.only(right: 4)),
                      Text(
                        l10n.noBooruTags,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const Padding(padding: EdgeInsets.only(right: 4)),
                    ],
                  ),
                ),
              ],
            )
          : SizedBox(
              height: 38,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.leading != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: widget.leading,
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: ListView.builder(
                          key: ValueKey(refreshes),
                          itemCount: _tags.length,
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: SingleTagWidget(
                                tag: _tags[index],
                                tagging: widget.tagging,
                                onPress: widget.onPress,
                                redBackground: widget.redBackground,
                              ),
                            );
                          },
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

const slideFadeEffects = <Effect<dynamic>>[
  SlideEffect(
    curve: Easing.emphasizedDecelerate,
    duration: Durations.medium4,
    begin: Offset(0.2, 0),
    end: Offset.zero,
  ),
  FadeEffect(
    delay: Duration(milliseconds: 80),
    curve: Easing.standard,
    duration: Durations.medium4,
    begin: 0,
    end: 1,
  ),
];

class SingleTagWidget extends StatelessWidget {
  const SingleTagWidget({
    super.key,
    required this.tag,
    required this.onPress,
    required this.tagging,
    required this.redBackground,
  });

  final TagData tag;
  final BooruTagging tagging;
  final bool redBackground;
  final void Function(String tag, SafeMode? safeMode)? onPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MenuWrapper(
      title: tag.tag,
      items: [
        if (onPress != null)
          launchGridSafeModeItem(
            context,
            tag.tag,
            (context, _, [safeMode]) {
              onPress!(tag.tag, safeMode);
            },
            l10n,
          ),
        PopupMenuItem(
          onTap: () {
            tagging.delete(tag.tag);
          },
          child: Text(l10n.delete),
        ),
      ],
      child: FilledButton.tonalIcon(
        icon: const Icon(Icons.tag_rounded),
        style: ButtonStyle(
          visualDensity: VisualDensity.comfortable,
          backgroundColor: WidgetStatePropertyAll(
            redBackground ? Colors.pink.shade300 : null,
          ),
        ),
        onPressed: onPress == null
            ? null
            : () {
                onPress!(tag.tag, null);
              },
        label: Text(
          tag.tag,
          style: redBackground
              ? TextStyle(color: Colors.black.withOpacity(0.8))
              : null,
        ),
      ),
    );
  }
}
