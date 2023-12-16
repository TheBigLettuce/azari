// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';

class LoadingErrorWidget extends StatelessWidget {
  final String error;
  final bool short;
  final void Function() refresh;

  const LoadingErrorWidget(
      {super.key,
      required this.error,
      required this.refresh,
      this.short = true});

  @override
  Widget build(BuildContext context) {
    Widget button() => IconButton(
        constraints: short ? const BoxConstraints.expand() : null,
        onPressed: refresh,
        icon: Icon(
          Icons.refresh_outlined,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ));

    return Container(
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
      child: Center(
        child: short
            ? button()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  button(),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: Text(
                      error,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .iconTheme
                              .color
                              ?.withOpacity(0.6)),
                    ),
                  )
                ],
              ),
      ),
    );
  }
}
