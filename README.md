# dynamic_toolbar_actions

Adaptive toolbar actions for Flutter `AppBar` that:

- keep important actions visible first,
- collapse lower-priority actions automatically when width is tight,
- support multiple user-defined overflow menus (for example `settings`, `userMenu`, `editActions`),
- hide actions with the same priority **together**.

## Why use it

Default `AppBar.actions` handling is not enough when you need all of these at once:

- deterministic hide order,
- grouped overflow destinations with different icons,
- consistent behavior across desktop/web/mobile widths,
- mixed action types (`IconButton`, custom widgets, separators, menu-only items).

This package centralizes that behavior into one reusable widget.

## Install

Add to your app `pubspec.yaml`:

```yaml
dependencies:
  dynamic_toolbar_actions:
    path: ../dynamic_toolbar_actions
```

Then run:

```bash
flutter pub get
```

## Basic usage

```dart
import 'package:dynamic_toolbar_actions/dynamic_toolbar_actions.dart';
import 'package:flutter/material.dart';

DynamicToolbarActions(
  items: [
    DynamicActionItem.icon(
      icon: Icons.home,
      tooltip: 'Home',
      label: 'Home',
      onTap: () {},
      hidePriority: 300,
    ),
    DynamicActionItem.icon(
      icon: Icons.settings,
      tooltip: 'Settings',
      label: 'Settings',
      onTap: () {},
      hidePriority: 80,
      overflowGroupId: 'settings',
    ),
    DynamicActionItem.menuOnly(
      child: const Text('Account'),
      label: 'Account',
      overflowGroupId: 'userMenu',
      onTap: () {},
    ),
  ],
  overflowGroups: const [
    DynamicOverflowGroup(id: 'settings', icon: Icons.settings),
    DynamicOverflowGroup(id: 'userMenu', icon: Icons.account_circle),
    DynamicOverflowGroup(id: 'editActions', icon: Icons.edit),
  ],
)
```

## Core concepts

- `hidePriority`: lower values are hidden first.
- same `hidePriority`: hidden as one batch (same frame/decision).
- `overflowGroupId`: route hidden/menu-only items to a specific overflow button.
- `DynamicOverflowGroup`: config for each overflow button (id, icon, tooltip, optional key).
- `menuOnly`: action is never shown in the toolbar, only in overflow.

## Action types

- `DynamicActionItem.icon(...)`
- `DynamicActionItem.widget(...)`
- `DynamicActionItem.divider(...)`
- `DynamicActionItem.menuOnly(...)`

## Meta compatibility API

For existing codebases, the package also exposes:

- `MetaToolbarActions`
- `MetaActionItem`
- `MetaActionKind`

Import:

```dart
import 'package:dynamic_toolbar_actions/meta_toolbar_actions.dart';
```

This lets you migrate to the external package without rewriting all action builders at once.

## Notes

- If an item references an unknown `overflowGroupId`, it falls back to the default overflow group.
- Divider normalization is applied in both toolbar and overflow menus to avoid duplicate/trailing separators.
<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
