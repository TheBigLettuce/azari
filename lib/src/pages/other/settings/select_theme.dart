// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "settings_page.dart";

bool _themeChange = false;
bool get themeIsChanging => _themeChange;

void themeChangeOver() {
  _themeChange = false;
}

void themeChangeStart() {
  _themeChange = true;
}

void selectTheme(
  BuildContext context,
  SettingsData miscSettings,
  ThemeType value,
) {
  if (miscSettings.themeType == value) {
    return;
  }

  _themeChange = true;

  miscSettings.copy(themeType: value).save();

  RestartWidget.restartApp(context);
}
