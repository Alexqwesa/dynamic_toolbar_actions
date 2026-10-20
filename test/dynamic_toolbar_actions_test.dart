import 'package:dynamic_toolbar_actions/dynamic_toolbar_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders several overflow group buttons from user config', (
    tester,
  ) async {
    await _pumpToolbar(
      tester,
      width: 220,
      items: [
        DynamicActionItem.icon(
          icon: Icons.home,
          label: 'Home',
          tooltip: 'Home',
          onTap: () {},
          hidePriority: 300,
        ),
        DynamicActionItem.icon(
          icon: Icons.settings,
          label: 'Settings action',
          tooltip: 'Settings action',
          onTap: () {},
          hidePriority: 10,
          overflowGroupId: 'settings',
        ),
        DynamicActionItem.icon(
          icon: Icons.person,
          label: 'User action',
          tooltip: 'User action',
          onTap: () {},
          hidePriority: 10,
          overflowGroupId: 'userMenu',
        ),
      ],
      groups: const [
        DynamicOverflowGroup(
          id: 'settings',
          icon: Icons.settings,
          buttonKey: Key('settings-overflow'),
        ),
        DynamicOverflowGroup(
          id: 'userMenu',
          icon: Icons.account_circle,
          buttonKey: Key('user-overflow'),
        ),
      ],
    );

    expect(find.byKey(const Key('settings-overflow')), findsOneWidget);
    expect(find.byKey(const Key('user-overflow')), findsOneWidget);
  });

  testWidgets('same hide priority actions hide at the same time', (
    tester,
  ) async {
    await _pumpToolbar(
      tester,
      width: 170,
      items: [
        DynamicActionItem.icon(
          icon: Icons.home,
          label: 'Pinned',
          tooltip: 'Pinned',
          onTap: () {},
          hidePriority: 300,
        ),
        DynamicActionItem.icon(
          icon: Icons.wifi,
          label: 'Settings action',
          tooltip: 'Settings action',
          onTap: () {},
          hidePriority: 100,
          toolbarWidth: 72,
          overflowGroupId: 'settings',
        ),
        DynamicActionItem.icon(
          icon: Icons.bluetooth,
          label: 'Edit action',
          tooltip: 'Edit action',
          onTap: () {},
          hidePriority: 100,
          toolbarWidth: 72,
          overflowGroupId: 'editActions',
        ),
      ],
      groups: const [
        DynamicOverflowGroup(
          id: 'settings',
          icon: Icons.settings,
          buttonKey: Key('settings-overflow'),
        ),
        DynamicOverflowGroup(
          id: 'editActions',
          icon: Icons.edit,
          buttonKey: Key('edit-overflow'),
        ),
      ],
    );

    expect(find.byTooltip('Settings action'), findsNothing);
    expect(find.byTooltip('Edit action'), findsNothing);
    expect(find.byKey(const Key('settings-overflow')), findsOneWidget);
    expect(find.byKey(const Key('edit-overflow')), findsOneWidget);
  });

  testWidgets('menu-only actions are routed to their assigned overflow group', (
    tester,
  ) async {
    var settingsTap = 0;
    var userTap = 0;
    await _pumpToolbar(
      tester,
      width: 280,
      items: [
        DynamicActionItem.icon(
          icon: Icons.home,
          label: 'Home',
          tooltip: 'Home',
          onTap: () {},
          hidePriority: 200,
        ),
        DynamicActionItem.menuOnly(
          label: 'Theme',
          overflowGroupId: 'settings',
          onTap: () => settingsTap++,
          child: const Text('Theme'),
        ),
        DynamicActionItem.menuOnly(
          label: 'Account',
          overflowGroupId: 'userMenu',
          onTap: () => userTap++,
          child: const Text('Account'),
        ),
      ],
      groups: const [
        DynamicOverflowGroup(
          id: 'settings',
          icon: Icons.settings,
          buttonKey: Key('settings-overflow'),
        ),
        DynamicOverflowGroup(
          id: 'userMenu',
          icon: Icons.account_circle,
          buttonKey: Key('user-overflow'),
        ),
      ],
    );

    await tester.tap(find.byKey(const Key('settings-overflow')));
    await tester.pumpAndSettle();
    expect(find.text('Theme'), findsOneWidget);
    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    expect(settingsTap, 1);

    await tester.tap(find.byKey(const Key('user-overflow')));
    await tester.pumpAndSettle();
    expect(find.text('Account'), findsOneWidget);
    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(userTap, 1);
  });

  testWidgets('wide screen keeps toolbar icon order stable', (tester) async {
    await _pumpToolbar(
      tester,
      width: 1600,
      items: _resultToolbarItems(isAdmin: true),
      groups: const [DynamicOverflowGroup.defaultGroup()],
    );

    // Regression guard: all actions must stay visible on wide layouts.
    expect(find.byIcon(Icons.undo), findsOneWidget);
    expect(find.byIcon(Icons.save), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.byIcon(Icons.history), findsOneWidget);
    expect(find.byIcon(Icons.visibility), findsOneWidget);
    expect(find.byIcon(Icons.help), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
    expect(find.byIcon(Icons.more_vert), findsNothing);

    final order = <IconData>[
      Icons.undo,
      Icons.save,
      Icons.add,
      Icons.refresh,
      Icons.history,
      Icons.visibility,
      Icons.help,
      Icons.logout,
    ];

    final x = <double>[
      for (final icon in order) tester.getTopLeft(find.byIcon(icon)).dx,
    ];
    for (var i = 0; i < x.length - 1; i++) {
      expect(
        x[i],
        lessThan(x[i + 1]),
        reason: 'Icon order changed between ${order[i]} and ${order[i + 1]}',
      );
    }
  });

  testWidgets('view options action is admin-only', (tester) async {
    await _pumpToolbar(
      tester,
      width: 1600,
      items: _resultToolbarItems(isAdmin: false),
      groups: const [DynamicOverflowGroup.defaultGroup()],
    );
    expect(find.byIcon(Icons.visibility), findsNothing);

    await _pumpToolbar(
      tester,
      width: 1600,
      items: _resultToolbarItems(isAdmin: true),
      groups: const [DynamicOverflowGroup.defaultGroup()],
    );
    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });

  testWidgets('icon action applies configured color', (tester) async {
    await _pumpToolbar(
      tester,
      width: 400,
      items: [
        DynamicActionItem.icon(
          icon: Icons.save,
          tooltip: 'Save',
          label: 'Save',
          color: Colors.blue,
          onTap: () {},
        ),
      ],
      groups: const [DynamicOverflowGroup.defaultGroup()],
    );

    final button = tester.widget<IconButton>(
      find
          .ancestor(
            of: find.byIcon(Icons.save),
            matching: find.byType(IconButton),
          )
          .first,
    );
    expect(button.color, Colors.blue);
  });

  testWidgets('app bar title regains width after window expands', (
    tester,
  ) async {
    const titleKey = Key('app-bar-title');
    final items = _resultToolbarItems(isAdmin: true);

    await _pumpToolbarWithTitle(
      tester,
      width: 720,
      title: Text(
        'A very long title that should expand again when space becomes available',
        key: titleKey,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      items: items,
      groups: const [DynamicOverflowGroup.defaultGroup()],
    );

    final narrowTitleWidth = tester.getSize(find.byKey(titleKey)).width;
    expect(find.byIcon(Icons.more_vert), findsOneWidget);

    await _pumpToolbarWithTitle(
      tester,
      width: 1400,
      title: Text(
        'A very long title that should expand again when space becomes available',
        key: titleKey,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      items: items,
      groups: const [DynamicOverflowGroup.defaultGroup()],
    );

    final wideTitleWidth = tester.getSize(find.byKey(titleKey)).width;
    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(wideTitleWidth, greaterThan(narrowTitleWidth + 100));
  });
}

Future<void> _pumpToolbar(
  WidgetTester tester, {
  required double width,
  required List<DynamicActionItem> items,
  required List<DynamicOverflowGroup> groups,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('T'),
          actions: [
            DynamicToolbarActions(items: items, overflowGroups: groups),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpToolbarWithTitle(
  WidgetTester tester, {
  required double width,
  required Widget title,
  required List<DynamicActionItem> items,
  required List<DynamicOverflowGroup> groups,
}) async {
  tester.view.physicalSize = Size(width, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: title,
          actions: [
            DynamicToolbarActions(items: items, overflowGroups: groups),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

List<DynamicActionItem> _resultToolbarItems({required bool isAdmin}) {
  final items = <DynamicActionItem>[
    DynamicActionItem.icon(
      icon: Icons.undo,
      tooltip: 'Undo',
      label: 'Undo',
      onTap: () {},
      hidePriority: 300,
    ),
    DynamicActionItem.icon(
      icon: Icons.save,
      tooltip: 'Save',
      label: 'Save',
      onTap: () {},
      hidePriority: 300,
    ),
    DynamicActionItem.icon(
      icon: Icons.add,
      tooltip: 'Add',
      label: 'Add',
      onTap: () {},
      hidePriority: 300,
    ),
    DynamicActionItem.divider(width: 16),
    DynamicActionItem.icon(
      icon: Icons.refresh,
      tooltip: 'Refresh',
      label: 'Refresh',
      onTap: () {},
      hidePriority: 300,
    ),
    DynamicActionItem.icon(
      icon: Icons.history,
      tooltip: 'History',
      label: 'History',
      onTap: () {},
      hidePriority: 300,
    ),
    if (isAdmin) ...[
      DynamicActionItem.divider(width: 16),
      DynamicActionItem.icon(
        icon: Icons.visibility,
        tooltip: 'View options',
        label: 'View options',
        onTap: () {},
        hidePriority: 300,
      ),
    ],
    DynamicActionItem.divider(width: 16),
    DynamicActionItem.icon(
      icon: Icons.help,
      tooltip: 'Help',
      label: 'Help',
      onTap: () {},
      hidePriority: 300,
    ),
    DynamicActionItem.icon(
      icon: Icons.logout,
      tooltip: 'Log out',
      label: 'Log out',
      onTap: () {},
      hidePriority: 300,
    ),
  ];
  return items;
}
