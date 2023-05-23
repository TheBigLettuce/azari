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

Map<SingleActivatorDescription, Null Function()> digitAndSettings(
    BuildContext context, int from) {
  return {
    const SingleActivatorDescription(
            "Go to the booru grid", SingleActivator(LogicalKeyboardKey.digit1)):
        () {
      if (from != kBooruGridDrawerIndex) {
        selectDestination(context, from, kBooruGridDrawerIndex);
      }
    },
    const SingleActivatorDescription(
        "Go to the tags page", SingleActivator(LogicalKeyboardKey.digit2)): () {
      selectDestination(context, from, kTagsDrawerIndex);
    },
    const SingleActivatorDescription(
        "Go to the downloads", SingleActivator(LogicalKeyboardKey.digit3)): () {
      selectDestination(context, from, kDownloadsDrawerIndex);
    },
    const SingleActivatorDescription("Open settings page",
        SingleActivator(LogicalKeyboardKey.keyS, control: true)): () {
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
                title: Text("Keybinds for: $pageName"),
                content: SizedBox(
                  width: double.maxFinite,
                  child: ListView(
                    children: [
                      ...desc.map((e) => ListTile(
                            title: Text(e),
                          )),
                      ListTile(
                        title: Text(describeKey(
                            const SingleActivatorDescription(
                                "This menu",
                                SingleActivator(LogicalKeyboardKey.keyK,
                                    shift: true, control: true)))),
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
