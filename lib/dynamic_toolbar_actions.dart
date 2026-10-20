import 'dart:math' as math;

import 'package:flutter/material.dart';

export 'meta_toolbar_actions.dart';

class DynamicToolbarActions extends StatelessWidget {
  const DynamicToolbarActions({
    super.key,
    required this.items,
    this.overflowGroups = const [DynamicOverflowGroup.defaultGroup()],
    this.availableWidthOverride,
    this.iconSize,
    this.gap = 4,
    this.overflowButtonWidth = 48,
  });

  final List<DynamicActionItem> items;
  final List<DynamicOverflowGroup> overflowGroups;
  final double? availableWidthOverride;
  final double? iconSize;
  final double gap;
  final double overflowButtonWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            availableWidthOverride ??
            (constraints.hasBoundedWidth
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width * 0.42);
        final layout = _resolveLayout(
          items: items,
          availableWidth: math.max(0, availableWidth),
          gap: gap,
          overflowButtonWidth: overflowButtonWidth,
        );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolbarActionStrip(
              visibleItems: layout.visibleItems,
              gap: gap,
              iconSize: iconSize,
            ),
            if (layout.overflowGroupsWithItems.isNotEmpty &&
                layout.visibleItems.isNotEmpty)
              SizedBox(width: gap),
            for (
              var index = 0;
              index < layout.overflowGroupsWithItems.length;
              index++
            ) ...[
              _DynamicOverflowGroupButton(
                iconSize: iconSize,
                group: layout.overflowGroupsWithItems[index].group,
                overflowItems: layout.overflowGroupsWithItems[index].items,
              ),
              if (index < layout.overflowGroupsWithItems.length - 1)
                SizedBox(width: gap),
            ],
          ],
        );
      },
    );
  }

  _ResolvedLayout _resolveLayout({
    required List<DynamicActionItem> items,
    required double availableWidth,
    required double gap,
    required double overflowButtonWidth,
  }) {
    final toolbarItems = _trimToolbarDividers(
      items.where((item) => item.showInToolbar).toList(),
    );
    var visible = toolbarItems.toList();
    final hidden = <DynamicActionItem>[...items.where((item) => item.menuOnly)];

    final groupById = <String, DynamicOverflowGroup>{
      for (final group in overflowGroups) group.id: group,
      DynamicOverflowGroup.defaultGroup().id:
          DynamicOverflowGroup.defaultGroup(),
    };

    List<_OverflowGroupItems> resolveOverflowGroups(
      List<DynamicActionItem> hiddenItems,
    ) {
      final byGroup = <String, List<DynamicActionItem>>{};
      for (final item in hiddenItems) {
        if (!item.showInMenu) continue;
        byGroup
            .putIfAbsent(item.overflowGroupId, () => <DynamicActionItem>[])
            .add(item);
      }

      final resolved = <_OverflowGroupItems>[];
      final orderedGroupIds = <String>[
        ...overflowGroups.map((group) => group.id),
        ...byGroup.keys.where(
          (groupId) => !overflowGroups.any((group) => group.id == groupId),
        ),
      ];

      for (final groupId in orderedGroupIds) {
        final groupItems = _trimOverflowDividers(byGroup[groupId] ?? const []);
        if (groupItems.isEmpty) continue;
        resolved.add(
          _OverflowGroupItems(
            group: groupById[groupId] ?? DynamicOverflowGroup.defaultGroup(),
            items: groupItems,
          ),
        );
      }
      return resolved;
    }

    double totalWidth(
      List<DynamicActionItem> entries, {
      required int overflowButtonsCount,
    }) {
      final pieces = <double>[];
      if (entries.isNotEmpty) {
        final contentWidth = entries.fold<double>(
          0,
          (sum, item) => sum + item.toolbarWidth,
        );
        final gapsWidth = gap * math.max(0, entries.length - 1);
        pieces.add(contentWidth + gapsWidth);
      }
      if (overflowButtonsCount > 0) {
        final buttonWidths =
            overflowButtonsCount * overflowButtonWidth +
            gap * math.max(0, overflowButtonsCount - 1);
        pieces.add(buttonWidths);
      }
      if (pieces.length == 2) {
        return pieces[0] + gap + pieces[1];
      }
      return pieces.isEmpty ? 0 : pieces.first;
    }

    final hideCandidatesByPriority = <int, List<DynamicActionItem>>{};
    for (final item in toolbarItems.where((item) => item.showInMenu)) {
      hideCandidatesByPriority
          .putIfAbsent(item.hidePriority, () => <DynamicActionItem>[])
          .add(item);
    }
    final orderedPriorities = hideCandidatesByPriority.keys.toList()..sort();
    for (final priority in orderedPriorities) {
      final overflowButtonsCount = resolveOverflowGroups(hidden).length;
      if (totalWidth(visible, overflowButtonsCount: overflowButtonsCount) <=
          availableWidth) {
        break;
      }

      final bucket = hideCandidatesByPriority[priority]!
        ..sort((a, b) => b.originalOrder.compareTo(a.originalOrder));
      var movedAny = false;
      for (final item in bucket) {
        if (!visible.contains(item)) continue;
        visible.remove(item);
        hidden.add(item);
        movedAny = true;
      }
      if (movedAny) {
        visible = _trimToolbarDividers(visible);
      }
    }

    visible = _trimToolbarDividers(visible);
    return _ResolvedLayout(
      visibleItems: visible,
      overflowGroupsWithItems: resolveOverflowGroups(hidden),
    );
  }

  List<DynamicActionItem> _trimToolbarDividers(List<DynamicActionItem> items) {
    final filtered = <DynamicActionItem>[];
    for (final item in items) {
      if (item.kind == DynamicActionKind.divider) {
        if (filtered.isEmpty) continue;
        if (filtered.last.kind == DynamicActionKind.divider) continue;
      }
      filtered.add(item);
    }
    while (filtered.isNotEmpty &&
        filtered.last.kind == DynamicActionKind.divider) {
      filtered.removeLast();
    }
    return filtered;
  }

  List<DynamicActionItem> _trimOverflowDividers(List<DynamicActionItem> items) {
    final filtered = <DynamicActionItem>[];
    for (final item in items) {
      if (!item.showInMenu) continue;
      if (item.kind == DynamicActionKind.divider) {
        if (filtered.isEmpty) continue;
        if (filtered.last.kind == DynamicActionKind.divider) continue;
      }
      filtered.add(item);
    }
    while (filtered.isNotEmpty &&
        filtered.last.kind == DynamicActionKind.divider) {
      filtered.removeLast();
    }
    return filtered;
  }
}

class _ToolbarActionStrip extends StatelessWidget {
  const _ToolbarActionStrip({
    required this.visibleItems,
    required this.gap,
    required this.iconSize,
  });

  final List<DynamicActionItem> visibleItems;
  final double gap;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < visibleItems.length; index++) ...[
          _ToolbarActionItemWidget(
            item: visibleItems[index],
            iconSize: iconSize,
          ),
          if (index < visibleItems.length - 1) SizedBox(width: gap),
        ],
      ],
    );
  }
}

class _ToolbarActionItemWidget extends StatelessWidget {
  const _ToolbarActionItemWidget({required this.item, required this.iconSize});

  final DynamicActionItem item;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    switch (item.kind) {
      case DynamicActionKind.divider:
        return item.widget ?? SizedBox(width: item.toolbarWidth);
      case DynamicActionKind.widget:
        return item.widget!;
      case DynamicActionKind.icon:
        return IconButton(
          tooltip: item.tooltip,
          color: item.color,
          iconSize: iconSize ?? 24,
          onPressed: item.enabled ? item.onTap : null,
          onLongPress: item.enabled ? item.onLongPress : null,
          icon: Icon(item.icon),
        );
    }
  }
}

class _DynamicOverflowGroupButton extends StatelessWidget {
  const _DynamicOverflowGroupButton({
    required this.iconSize,
    required this.group,
    required this.overflowItems,
  });

  final double? iconSize;
  final DynamicOverflowGroup group;
  final List<DynamicActionItem> overflowItems;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      key: group.buttonKey,
      tooltip: group.tooltip,
      icon: Icon(group.icon, size: iconSize),
      onSelected: (index) => overflowItems[index].invoke(),
      itemBuilder: (context) {
        final entries = <PopupMenuEntry<int>>[];
        for (var index = 0; index < overflowItems.length; index++) {
          final item = overflowItems[index];
          switch (item.kind) {
            case DynamicActionKind.divider:
              entries.add(const PopupMenuDivider());
              break;
            case DynamicActionKind.icon:
              entries.add(
                PopupMenuItem<int>(
                  value: index,
                  enabled: item.enabled && item.onTap != null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(item.menuIcon ?? item.icon, color: item.color),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          item.label ?? item.tooltip ?? '',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
              break;
            case DynamicActionKind.widget:
              final hasInlineMenuWidget =
                  item.onTap == null &&
                  (item.menuWidget != null || item.widget != null);
              final label = item.label ?? item.tooltip ?? '';
              final child =
                  item.menuWidget ??
                  (hasInlineMenuWidget
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            item.widget ?? const SizedBox.shrink(),
                            if (label.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.menuIcon != null) ...[
                              Icon(item.menuIcon, color: item.color),
                              const SizedBox(width: 8),
                            ],
                            if (label.isNotEmpty)
                              Flexible(
                                child: Text(
                                  label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            else
                              Flexible(
                                child: item.widget ?? const SizedBox.shrink(),
                              ),
                          ],
                        ));
              if (hasInlineMenuWidget) {
                entries.add(_InlineWidgetPopupMenuEntry<int>(child: child));
              } else {
                entries.add(
                  PopupMenuItem<int>(
                    value: index,
                    enabled: item.enabled && item.onTap != null,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: child,
                  ),
                );
              }
              break;
          }
        }
        return entries;
      },
    );
  }
}

class DynamicOverflowGroup {
  const DynamicOverflowGroup({
    required this.id,
    required this.icon,
    this.tooltip,
    this.buttonKey,
  });

  const DynamicOverflowGroup.defaultGroup()
    : id = 'default',
      icon = Icons.more_vert,
      tooltip = null,
      buttonKey = null;

  final String id;
  final IconData icon;
  final String? tooltip;
  final Key? buttonKey;
}

enum DynamicActionKind { icon, divider, widget }

class DynamicActionItem {
  DynamicActionItem._({
    required this.kind,
    required this.hidePriority,
    required this.toolbarWidth,
    required this.showInToolbar,
    required this.showInMenu,
    required this.menuOnly,
    required this.overflowGroupId,
    required this.originalOrder,
    this.tooltip,
    this.label,
    this.icon,
    this.color,
    this.menuIcon,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.widget,
    this.menuWidget,
  });

  final DynamicActionKind kind;
  final int hidePriority;
  final double toolbarWidth;
  final bool showInToolbar;
  final bool showInMenu;
  final bool menuOnly;
  final String overflowGroupId;
  final int originalOrder;

  final String? tooltip;
  final String? label;
  final IconData? icon;
  final Color? color;
  final IconData? menuIcon;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final Widget? widget;
  final Widget? menuWidget;

  static int _nextOrder = 0;

  factory DynamicActionItem.icon({
    required IconData icon,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    String? tooltip,
    String? label,
    Color? color,
    bool enabled = true,
    int hidePriority = 100,
    double toolbarWidth = 48,
    IconData? menuIcon,
    bool showInMenu = true,
    String overflowGroupId = 'default',
  }) {
    return DynamicActionItem._(
      kind: DynamicActionKind.icon,
      icon: icon,
      color: color,
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
      overflowGroupId: overflowGroupId,
      originalOrder: _nextOrder++,
    );
  }

  factory DynamicActionItem.divider({
    int? width,
    int hidePriority = 0,
    bool showInMenu = false,
    String overflowGroupId = 'default',
  }) {
    final dividerWidth = width?.toDouble() ?? 10;
    return DynamicActionItem._(
      kind: DynamicActionKind.divider,
      widget: SizedBox(width: dividerWidth),
      hidePriority: hidePriority,
      toolbarWidth: dividerWidth,
      showInToolbar: true,
      showInMenu: showInMenu,
      menuOnly: false,
      overflowGroupId: overflowGroupId,
      originalOrder: _nextOrder++,
    );
  }

  factory DynamicActionItem.widget(
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
    String overflowGroupId = 'default',
  }) {
    return DynamicActionItem._(
      kind: DynamicActionKind.widget,
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
      overflowGroupId: overflowGroupId,
      originalOrder: _nextOrder++,
    );
  }

  factory DynamicActionItem.menuOnly({
    required Widget child,
    String? label,
    IconData? menuIcon,
    VoidCallback? onTap,
    bool enabled = true,
    int hidePriority = 0,
    String overflowGroupId = 'default',
  }) {
    return DynamicActionItem._(
      kind: DynamicActionKind.widget,
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
      overflowGroupId: overflowGroupId,
      originalOrder: _nextOrder++,
    );
  }

  void invoke() {
    if (!enabled) return;
    onTap?.call();
  }
}

class _ResolvedLayout {
  const _ResolvedLayout({
    required this.visibleItems,
    required this.overflowGroupsWithItems,
  });

  final List<DynamicActionItem> visibleItems;
  final List<_OverflowGroupItems> overflowGroupsWithItems;
}

class _OverflowGroupItems {
  const _OverflowGroupItems({required this.group, required this.items});

  final DynamicOverflowGroup group;
  final List<DynamicActionItem> items;
}

class _InlineWidgetPopupMenuEntry<T> extends PopupMenuEntry<T> {
  const _InlineWidgetPopupMenuEntry({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  double get height => 52;

  @override
  bool represents(T? value) => false;

  @override
  State<_InlineWidgetPopupMenuEntry<T>> createState() =>
      _InlineWidgetPopupMenuEntryState<T>();
}

class _InlineWidgetPopupMenuEntryState<T>
    extends State<_InlineWidgetPopupMenuEntry<T>> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: 1,
        child: widget.child,
      ),
    );
  }
}
