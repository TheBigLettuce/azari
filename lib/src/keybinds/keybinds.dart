// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../pages/settings.dart';
import '../widgets/drawer/drawer.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Map<SingleActivatorDescription, Null Function()> digitAndSettings(
    BuildContext context, int from) {
  return {
    SingleActivatorDescription(AppLocalizations.of(context)!.goBooruGrid,
        const SingleActivator(LogicalKeyboardKey.digit1)): () {
      if (from != kBooruGridDrawerIndex) {
        selectDestination(context, from, kBooruGridDrawerIndex);
      }
    },
    SingleActivatorDescription(AppLocalizations.of(context)!.goGallery,
        const SingleActivator(LogicalKeyboardKey.digit2)): () {
      selectDestination(context, from, kGalleryDrawerIndex);
    },
    SingleActivatorDescription(AppLocalizations.of(context)!.goTags,
        const SingleActivator(LogicalKeyboardKey.digit3)): () {
      selectDestination(context, from, kTagsDrawerIndex);
    },
    SingleActivatorDescription(AppLocalizations.of(context)!.goDownloads,
        const SingleActivator(LogicalKeyboardKey.digit4)): () {
      selectDestination(context, from, kDownloadsDrawerIndex);
    },
    SingleActivatorDescription(AppLocalizations.of(context)!.goSettings,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true)): () {
      Navigator.push(context, MaterialPageRoute(builder: (context) {
        return const Settings();
      }));
    }
  };
}

Map<SingleActivator, Null Function()> keybindDescription(
    BuildContext context, List<String> desc, String pageName) {
  return {
    const SingleActivator(LogicalKeyboardKey.keyK, shift: true, control: true):
        () {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                backgroundColor:
                    Theme.of(context).dialogBackgroundColor.withOpacity(0.5),
                title:
                    Text(AppLocalizations.of(context)!.keybindsFor(pageName)),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    children: [
                      ...ListTile.divideTiles(
                          context: context,
                          tiles: desc.map((e) => ListTile(
                                title: Text(e),
                              ))),
                      Padding(
                        padding: const EdgeInsets.only(top: 15),
                        child: ListTile(
                          title: Text(describeKey(SingleActivatorDescription(
                              AppLocalizations.of(context)!.keybindsDialog,
                              const SingleActivator(LogicalKeyboardKey.keyK,
                                  shift: true, control: true)))),
                        ),
                      )
                    ],
                  ),
                ),
              ));
    }
  };
}

class SingleActivatorDescription implements ShortcutActivator {
  final String description;
  final SingleActivator a;

  @override
  String debugDescribeKeys() => a.debugDescribeKeys();

  @override
  bool accepts(RawKeyEvent event, RawKeyboard state) => a.accepts(event, state);

  @override
  Iterable<LogicalKeyboardKey>? get triggers => a.triggers;

  const SingleActivatorDescription(this.description, this.a);
}

List<String> describeKeys(Map<SingleActivatorDescription, dynamic> bindings) =>
    bindings.keys.map((e) => describeKey(e)).toList();

String describeKey(SingleActivatorDescription activator) {
  StringBuffer buffer = StringBuffer();

  buffer.write("'");

  if (activator.a.control) {
    buffer.write("Control+");
  }

  if (activator.a.shift) {
    buffer.write("Shift+");
  }

  if (activator.a.alt) {
    buffer.write("Alt+");
  }

  if (activator.a.meta) {
    buffer.write("Meta+");
  }

  buffer.write(activator.a.trigger.keyLabel == " "
      ? "<space>"
      : activator.a.trigger.keyLabel);
  buffer.write("': ");
  buffer.write(activator.description);

  return buffer.toString();
}
