// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/widgets/keybinds/single_activator_description.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Map<SingleActivatorDescription, Null Function()> makeImageViewBindings(
  BuildContext context,
  GlobalKey<ScaffoldState> scaffoldKey,
  PageController pageController, {
  required void Function()? download,
  required void Function() onTap,
}) =>
    {
      SingleActivatorDescription(AppLocalizations.of(context)!.back,
          const SingleActivator(LogicalKeyboardKey.escape)): () {
        if (scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
          scaffoldKey.currentState?.closeEndDrawer();
        } else {
          Navigator.pop(context);
        }
      },
      SingleActivatorDescription(AppLocalizations.of(context)!.showImageInfo,
          const SingleActivator(LogicalKeyboardKey.keyI, control: true)): () {
        if (scaffoldKey.currentState != null) {
          if (scaffoldKey.currentState!.isEndDrawerOpen) {
            scaffoldKey.currentState?.closeEndDrawer();
          } else {
            scaffoldKey.currentState?.openEndDrawer();
          }
        }
      },
      if (download != null)
        SingleActivatorDescription(AppLocalizations.of(context)!.downloadImage,
            const SingleActivator(LogicalKeyboardKey.keyD, control: true)): () {
          download();
        },
      SingleActivatorDescription(AppLocalizations.of(context)!.hideAppBar,
          const SingleActivator(LogicalKeyboardKey.space, control: true)): () {
        onTap();
      },
      SingleActivatorDescription(AppLocalizations.of(context)!.nextImage,
          const SingleActivator(LogicalKeyboardKey.arrowRight)): () {
        pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Easing.standard);
      },
      SingleActivatorDescription(AppLocalizations.of(context)!.previousImage,
          const SingleActivator(LogicalKeyboardKey.arrowLeft)): () {
        pageController.previousPage(
            duration: const Duration(milliseconds: 500),
            curve: Easing.standard);
      }
    };
