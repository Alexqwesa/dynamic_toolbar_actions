# dynamic_toolbar_actions

⚠️ Early Development: This project is still in its early stages and is primarily used internally. 
It almost din't change in the last half year but i still not sure about final shape of it's api and that it should bring. 

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
    git:
      url: https://github.com/Alexqwesa/dynamic_toolbar_actions
      ref: v0.0.1
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

## More examples

### Same-priority actions hide together

```dart
DynamicToolbarActions(
  items: [
    DynamicActionItem.icon(
      icon: Icons.home,
      tooltip: 'Pinned',
      label: 'Pinned',
      onTap: () {},
      hidePriority: 300,
    ),
    DynamicActionItem.icon(
      icon: Icons.settings,
      tooltip: 'Settings',
      label: 'Settings',
      onTap: () {},
      hidePriority: 100,
      overflowGroupId: 'settings',
    ),
    DynamicActionItem.icon(
      icon: Icons.edit,
      tooltip: 'Edit',
      label: 'Edit',
      onTap: () {},
      hidePriority: 100, // same bucket as Settings
      overflowGroupId: 'editActions',
    ),
  ],
  overflowGroups: const [
    DynamicOverflowGroup(id: 'settings', icon: Icons.settings),
    DynamicOverflowGroup(id: 'editActions', icon: Icons.edit),
  ],
)
```

### Backward-compatible `Meta*` usage

```dart
MetaToolbarActions(
  items: [
    MetaActionItem.icon(
      icon: Icons.home,
      tooltip: 'Home',
      onTap: () {},
      hidePriority: 300,
    ),
    MetaActionItem.widget(
      const Text('Theme'),
      label: 'Theme',
      menuIcon: Icons.brightness_6,
      hidePriority: 40,
      toolbarWidth: 80,
    ),
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
