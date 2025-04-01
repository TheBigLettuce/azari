// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:azari/src/generated/l10n/app_localizations.dart";
import "package:azari/src/generated/platform/platform_api.g.dart" as platform;
import "package:azari/src/init_main/build_theme.dart";
import "package:azari/src/init_main/init_main.dart";
import "package:azari/src/init_main/restart_widget.dart";
import "package:azari/src/logic/local_tags_helper.dart";
import "package:azari/src/logic/resource_source/basic.dart";
import "package:azari/src/logic/typedefs.dart";
import "package:azari/src/services/impl/io/pigeon_gallery_data_impl.dart";
import "package:azari/src/services/impl/obj/file_impl.dart";
import "package:azari/src/services/services.dart";
import "package:azari/src/ui/app_adaptive.dart";
import "package:azari/src/ui/material/pages/gallery/directories.dart";
import "package:azari/src/ui/material/pages/gallery/gallery_return_callback.dart";
import "package:azari/src/ui/material/pages/home/home.dart";
import "package:azari/src/ui/material/widgets/copy_move_preview.dart";
import "package:azari/src/ui/material/widgets/image_view/image_view.dart";
import "package:azari/src/ui/material/widgets/scaffold_selection_bar.dart";
import "package:azari/src/ui/material/widgets/selection_bar.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

part "main_pick_file.dart";
part "main_quick_view.dart";

void main() async {
  await initMain(AppInstanceType.full);

  runApp(const AppAdaptive());
}
