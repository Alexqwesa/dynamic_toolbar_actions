import 'package:dynamic_toolbar_actions/dynamic_toolbar_actions.dart';
import 'package:flutter/material.dart';

/// Backward-compatible API for projects that already use MetaAction* types.
class MetaToolbarActions extends StatelessWidget {
  const MetaToolbarActions({
    super.key,
    required this.items,
    this.availableWidthOverride,
    this.iconSize,
    this.gap = 4,
    this.moreIcon = Icons.more_vert,
    this.popupTooltip,
    this.overflowButtonWidth = 48,
  });

  final List<MetaActionItem> items;
  final double? availableWidthOverride;
  final double? iconSize;
  final double gap;
  final IconData moreIcon;
  final String? popupTooltip;
  final double overflowButtonWidth;

  @override
  Widget build(BuildContext context) {
    return DynamicToolbarActions(
      items: items.map(_toDynamicActionItem).toList(),
      availableWidthOverride: availableWidthOverride,
      iconSize: iconSize,
      gap: gap,
      overflowButtonWidth: overflowButtonWidth,
      overflowGroups: [
        DynamicOverflowGroup(
          id: 'default',
          icon: moreIcon,
          tooltip: popupTooltip,
        ),
      ],
    );
  }
}

enum MetaActionKind { icon, divider, widget }

class MetaActionItem {
  MetaActionItem._({
    required this.kind,
    required this.hidePriority,
    required this.toolbarWidth,
    required this.showInToolbar,
    required this.showInMenu,
    required this.menuOnly,
    required this.originalOrder,
    this.tooltip,
    this.label,
    this.icon,
    this.menuIcon,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.widget,
    this.menuWidget,
  });

  final MetaActionKind kind;
  final int hidePriority;
  final double toolbarWidth;
  final bool showInToolbar;
  final bool showInMenu;
  final bool menuOnly;
  final int originalOrder;

  final String? tooltip;
  final String? label;
  final IconData? icon;
  final IconData? menuIcon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final Widget? widget;
  final Widget? menuWidget;

  static int _nextOrder = 0;

  factory MetaActionItem.icon({
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    String? tooltip,
    String? label,
    bool enabled = true,
    int hidePriority = 100,
    double toolbarWidth = 48,
    IconData? menuIcon,
    bool showInMenu = true,
  }) {
    return MetaActionItem._(
      kind: MetaActionKind.icon,
      icon: icon,
      menuIcon: menuIcon,
      onTap: onTap,
      onLongPress: onLongPress,
      tooltip: tooltip,
      label: label,
      enabled: enabled,
      hidePriority: hidePriority,
      toolbarWidth: toolbarWidth,
      showInToolbar: true,
      showInMenu: showInMenu,
      menuOnly: false,
      originalOrder: _nextOrder++,
    );
  }

  factory MetaActionItem.divider({
    int? width,
    int hidePriority = 0,
    bool showInMenu = false,
  }) {
    final dividerWidth = width?.toDouble() ?? 10;
    return MetaActionItem._(
      kind: MetaActionKind.divider,
      widget: SizedBox(width: dividerWidth),
      hidePriority: hidePriority,
      toolbarWidth: dividerWidth,
      showInToolbar: true,
      showInMenu: showInMenu,
      menuOnly: false,
      originalOrder: _nextOrder++,
    );
  }

  factory MetaActionItem.widget(
    Widget widget, {
    String? label,
    String? tooltip,
    IconData? menuIcon,
    Widget? menuWidget,
    VoidCallback? onTap,
    bool enabled = true,
    int hidePriority = 50,
    double toolbarWidth = 56,
    bool showInMenu = true,
  }) {
    return MetaActionItem._(
      kind: MetaActionKind.widget,
      widget: widget,
      menuWidget: menuWidget,
      label: label,
      tooltip: tooltip,
      menuIcon: menuIcon,
      onTap: onTap,
      enabled: enabled,
      hidePriority: hidePriority,
      toolbarWidth: toolbarWidth,
      showInToolbar: true,
      showInMenu: showInMenu,
      menuOnly: false,
      originalOrder: _nextOrder++,
    );
  }

  factory MetaActionItem.menuOnly({
    required Widget child,
    String? label,
    IconData? menuIcon,
    VoidCallback? onTap,
    bool enabled = true,
    int hidePriority = 0,
  }) {
    return MetaActionItem._(
      kind: MetaActionKind.widget,
      menuWidget: child,
      label: label,
      menuIcon: menuIcon,
      onTap: onTap,
      enabled: enabled,
      hidePriority: hidePriority,
      toolbarWidth: 0,
      showInToolbar: false,
      showInMenu: true,
      menuOnly: true,
      originalOrder: _nextOrder++,
    );
  }

  void invoke() {
    if (!enabled) return;
    onTap?.call();
  }
}

DynamicActionItem _toDynamicActionItem(MetaActionItem item) {
  switch (item.kind) {
    case MetaActionKind.icon:
      return DynamicActionItem.icon(
        icon: item.icon!,
        onTap: item.onTap ?? () {},
        onLongPress: item.onLongPress,
        tooltip: item.tooltip,
        label: item.label,
        enabled: item.enabled,
        hidePriority: item.hidePriority,
        toolbarWidth: item.toolbarWidth,
        menuIcon: item.menuIcon,
        showInMenu: item.showInMenu,
      );
    case MetaActionKind.divider:
      return DynamicActionItem.divider(
        width: item.toolbarWidth.round(),
        hidePriority: item.hidePriority,
        showInMenu: item.showInMenu,
      );
    case MetaActionKind.widget:
      if (item.menuOnly) {
        return DynamicActionItem.menuOnly(
          child: item.menuWidget ?? const SizedBox.shrink(),
          label: item.label,
          menuIcon: item.menuIcon,
          onTap: item.onTap,
          enabled: item.enabled,
          hidePriority: item.hidePriority,
        );
      }
      return DynamicActionItem.widget(
        item.widget ?? const SizedBox.shrink(),
        label: item.label,
        tooltip: item.tooltip,
        menuIcon: item.menuIcon,
        menuWidget: item.menuWidget,
        onTap: item.onTap,
        enabled: item.enabled,
        hidePriority: item.hidePriority,
        toolbarWidth: item.toolbarWidth,
        showInMenu: item.showInMenu,
      );
  }
}
