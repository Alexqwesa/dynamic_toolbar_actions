import 'package:dynamic_toolbar_actions/dynamic_toolbar_actions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('renders several overflow group buttons from user config', (tester) async {
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

  testWidgets('same hide priority actions hide at the same time', (tester) async {
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

  testWidgets('menu-only actions are routed to their assigned overflow group', (tester) async {
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
            DynamicToolbarActions(
              items: items,
              overflowGroups: groups,
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
