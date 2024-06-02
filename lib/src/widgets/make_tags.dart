// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:dynamic_color/dynamic_color.dart";
import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/db/tags/post_tags.dart";
import "package:gallery/src/interfaces/booru/safe_mode.dart";
import "package:gallery/src/pages/more/settings/radio_dialog.dart";
import "package:gallery/src/widgets/image_view/wrappers/wrap_image_view_notifiers.dart";
import "package:gallery/src/widgets/load_tags.dart";
import "package:gallery/src/widgets/menu_wrapper.dart";
import "package:gallery/src/widgets/notifiers/filter.dart";
import "package:gallery/src/widgets/notifiers/filter_value.dart";
import "package:gallery/src/widgets/notifiers/image_view_info_tiles_refresh_notifier.dart";

PopupMenuItem<void> launchGridSafeModeItem(
  BuildContext context,
  String tag,
  void Function(BuildContext, String, [SafeMode?]) launchGrid,
  AppLocalizations l10n,
) =>
    PopupMenuItem(
      onTap: () {
        if (tag.isEmpty) {
          return;
        }

        radioDialog<SafeMode>(
          context,
          SafeMode.values.map((e) => (e, e.translatedString(l10n))),
          SettingsService.db().current.safeMode,
          (value) => launchGrid(context, tag, value),
          title: l10n.chooseSafeMode,
          allowSingle: true,
        );
      },
      child: Text(l10n.launchWithSafeMode),
    );

class DrawerTagsWidget extends StatefulWidget with DbConnHandle<TagManager> {
  const DrawerTagsWidget(
    this.filename, {
    super.key,
    this.res,
    this.launchGrid,
    this.addRemoveTag = false,
    required this.db,
  });

  @override
  final TagManager db;
  final DisassembleResult? res;
  final String filename;
  final void Function(BuildContext, String, [SafeMode?])? launchGrid;
  final bool addRemoveTag;

  @override
  State<DrawerTagsWidget> createState() => _DrawerTagsWidgetState();
}

class _DrawerTagsWidgetState extends State<DrawerTagsWidget>
    with TagManagerDbScope<DrawerTagsWidget> {
  late final StreamSubscription<void>? _watcher;

  @override
  void initState() {
    super.initState();

    _watcher = excluded.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _watcher?.cancel();

    super.dispose();
  }

  List<PopupMenuItem<void>> makeItems(
    BuildContext context,
    String tag,
    AppLocalizations l10n,
  ) {
    return [
      PopupMenuItem(
        onTap: () {
          if (excluded.exists(tag)) {
            excluded.delete(tag);
          } else {
            excluded.add(tag);
          }
        },
        child: Text(
          excluded.exists(tag) ? l10n.removeFromExcluded : l10n.addToExcluded,
        ),
      ),
      if (widget.launchGrid != null)
        launchGridSafeModeItem(
          context,
          tag,
          widget.launchGrid!,
          l10n,
        ),
      if (widget.addRemoveTag)
        PopupMenuItem(
          onTap: () {
            DatabaseConnectionNotifier.of(context)
                .localTags
                .removeSingle([widget.filename], tag);
          },
          child: Text(l10n.delete),
        ),
      PopupMenuItem(
        onTap: () {
          if (pinned.exists(tag)) {
            pinned.delete(tag);
          } else {
            pinned.add(tag);
          }

          ImageViewInfoTilesRefreshNotifier.refreshOf(context);
        },
        child: Text(pinned.exists(tag) ? l10n.unpinTag : l10n.pinTag),
      ),
    ];
  }

  Widget makeTile(
    BuildContext context,
    String e,
    bool pinned,
    AppLocalizations l10n,
  ) =>
      MenuWrapper(
        title: e,
        items: makeItems(context, e, l10n),
        child: RawChip(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          avatar: pinned ? const Icon(Icons.push_pin_rounded, size: 18) : null,
          label: Text(
            e,
            style: TextStyle(
              color: excluded.exists(e)
                  ? Colors.red
                      .harmonizeWith(Theme.of(context).colorScheme.primary)
                      .withOpacity(0.9)
                  : null,
            ),
          ),
          onPressed: widget.launchGrid == null
              ? null
              : () {
                  widget.launchGrid!(context, e);
                },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final filename = widget.filename;
    final res = widget.res;
    final tags = ImageTagsNotifier.of(context);

    if (tags.isEmpty) {
      if (filename.isEmpty) {
        return const SliverPadding(padding: EdgeInsets.zero);
      }

      return res == null
          ? const SliverPadding(padding: EdgeInsets.zero)
          : LoadTags(
              filename: filename,
              res: res,
            );
    }

    final value = FilterValueNotifier.maybeOf(context).trim();
    final data = FilterNotifier.maybeOf(context);

    final Iterable<ImageTag> filteredTags;
    if (data != null && value.isNotEmpty) {
      filteredTags = tags.where((element) => element.tag.contains(value));
    } else {
      filteredTags = tags;
    }

    final l10n = AppLocalizations.of(context)!;

    final tiles =
        filteredTags.map((e) => makeTile(context, e.tag, e.favorite, l10n));

    return SliverPadding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      sliver: SliverToBoxAdapter(
        child: Wrap(
          spacing: 4,
          children: tiles.toList(),
        ),
      ),
    );
  }
}

void openAddTagDialog(
  BuildContext context,
  void Function(String, bool) onSubmit,
  AppLocalizations l10n,
) {
  final regexp = RegExp(r"[^A-Za-z0-9_\(\)']");
  bool delete = false;

  Navigator.push(
    context,
    DialogRoute<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.addTag),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Form(
                autovalidateMode: AutovalidateMode.always,
                child: TextFormField(
                  enabled: true,
                  validator: (value) {
                    if (value == null) {
                      return l10n.valueIsNull;
                    }

                    final v = value.trim();
                    if (v.isEmpty) {
                      return l10n.valueIsEmpty;
                    }

                    if (v.length <= 1) {
                      return l10n.valueIsEmpty;
                    }

                    if (regexp.hasMatch(v)) {
                      return l10n.tagValidationError;
                    }

                    return null;
                  },
                  onFieldSubmitted: (value) {
                    final v = value.trim();
                    if (v.isEmpty || v.length <= 1 || regexp.hasMatch(v)) {
                      return;
                    }

                    onSubmit(v, delete);
                    Navigator.pop(context);
                  },
                ),
              ),
              StatefulBuilder(
                builder: (context, setState) {
                  return SwitchListTile(
                    title: Text(l10n.delete),
                    value: delete,
                    onChanged: (v) {
                      delete = v;

                      setState(() {});
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}
