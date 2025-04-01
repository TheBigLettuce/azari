// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

// import "package:local_auth/local_auth.dart";

// Future<void> initAppInfo() async {
//   final bool canUseAuth;
//   if (PlatformApi().authSupported) {
//     final auth = LocalAuthentication();

//     canUseAuth = await auth.isDeviceSupported() &&
//         await auth.canCheckBiometrics &&
//         (await auth.getAvailableBiometrics()).isNotEmpty;
//   } else {
//     canUseAuth = false;
//   }

//   AppInfo._instance = AppInfo._(canUseAuth, await PlatformApi().version);
// }
