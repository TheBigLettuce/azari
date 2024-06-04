// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:gallery/src/widgets/keybinds/single_activator_description.dart";

List<String> describeKeys(Map<SingleActivatorDescription, dynamic> bindings) =>
    bindings.keys.map((e) => describeKey(e)).toList();

String describeKey(SingleActivatorDescription activator) {
  final StringBuffer buffer = StringBuffer();

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

  buffer.write(
    activator.a.trigger.keyLabel == " "
        ? "<space>"
        : activator.a.trigger.keyLabel,
  );
  buffer.write("': ");
  buffer.write(activator.description);

  return buffer.toString();
}
