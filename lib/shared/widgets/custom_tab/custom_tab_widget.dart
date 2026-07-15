// @file custom_tab_widget.dart
// @description Reusable tabs component supporting multiple visual styles
// (line, pill, card, underline), color variants, sizes, icons, badges,
// full-width layout, and dark theme.

import 'package:flutter/material.dart';

import '../../../config/theme/app_colors.dart';

// ─── Types ────────────────────────────────────────────────────────────────────

/// A single tab item configuration.
class TabItem {
  const TabItem({
    required this.id,
    required this.label,
    this.icon,
    this.badge,
    this.disabled = false,
  });

  final String id;
  final String label;

  /// Optional Lucide (or any) icon shown before the label.
  final IconData? icon;

  /// Optional badge value — shown as a small pill after the label.
  final Object? badge; // int | String

  final bool disabled;
}

/// Visual presentation style.
enum TabStyle { line, pill, card, underline }

/// Color variant applied to active states and highlights.
enum TabVariant { primary, secondary, tertiary, success, warning, error, info }

/// Tab size.
enum TabSize { sm, md, lg }

// ─── Widget ───────────────────────────────────────────────────────────────────

/// Flexible tabs widget for navigation and content switching.
///
/// Selection is controlled externally: pass [activeTab] and handle
/// [onTabChange] to update it.
///
/// Usage:
/// ```dart
/// CustomTabWidget(
///   tabs: const [
///     TabItem(id: 'home', label: 'Home'),
///     TabItem(id: 'profile', label: 'Profilo', badge: 3),
///   ],
///   activeTab: _activeTab,
///   onTabChange: (id) => setState(() => _activeTab = id),
/// )
/// ```
class CustomTabWidget extends StatelessWidget {
  const CustomTabWidget({
    super.key,
    required this.tabs,
    required this.activeTab,
    this.tabStyle = TabStyle.line,
    this.variant = TabVariant.primary,
    this.size = TabSize.md,
    this.fullWidth = false,
    this.darkTheme = false,
    this.onTabChange,
  });

  final List<TabItem> tabs;
  final String activeTab;
  final TabStyle tabStyle;
  final TabVariant variant;
  final TabSize size;
  final bool fullWidth;
  final bool darkTheme;
  final ValueChanged<String>? onTabChange;

  void _selectTab(TabItem tab) {
    if (tab.disabled || tab.id == activeTab) return;
    onTabChange?.call(tab.id);
  }

  // ── Size tokens ────────────────────────────────────────────────────────

  double get _fontSize => switch (size) {
    TabSize.sm => 12.5,
    TabSize.md => 14.0,
    TabSize.lg => 16.0,
  };

  double get _iconSize => switch (size) {
    TabSize.sm => 14.0,
    TabSize.md => 16.0,
    TabSize.lg => 18.0,
  };

  EdgeInsets get _tabPadding => switch (size) {
    TabSize.sm => const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    TabSize.md => const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    TabSize.lg => const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  };

  // ── Variant tokens ─────────────────────────────────────────────────────

  ({Color light, Color dark, Color text, Color shadow}) get _vc =>
      switch (variant) {
        TabVariant.primary => (
          light: AppColors.colorPrimaryLight,
          dark: AppColors.colorPrimaryDark,
          text: AppColors.colorPrimaryText,
          shadow: AppColors.colorPrimaryShadow,
        ),
        TabVariant.secondary => (
          light: AppColors.colorSecondaryLight,
          dark: AppColors.colorSecondaryDark,
          text: AppColors.colorSecondaryText,
          shadow: AppColors.colorSecondaryShadow,
        ),
        TabVariant.tertiary => (
          light: AppColors.colorTertiaryLight,
          dark: AppColors.colorTertiaryDark,
          text: AppColors.colorTertiaryText,
          shadow: AppColors.colorTertiaryShadow,
        ),
        TabVariant.success => (
          light: AppColors.colorSuccessLight,
          dark: AppColors.colorSuccessDark,
          text: AppColors.colorSuccessText,
          shadow: AppColors.colorSuccessShadow,
        ),
        TabVariant.warning => (
          light: AppColors.colorWarningLight,
          dark: AppColors.colorWarningDark,
          text: AppColors.colorWarningText,
          shadow: AppColors.colorWarningShadow,
        ),
        TabVariant.error => (
          light: AppColors.colorErrorLight,
          dark: AppColors.colorErrorDark,
          text: AppColors.colorErrorText,
          shadow: AppColors.colorErrorShadow,
        ),
        TabVariant.info => (
          light: AppColors.colorInfoLight,
          dark: AppColors.colorInfoDark,
          text: AppColors.colorInfoText,
          shadow: AppColors.colorInfoShadow,
        ),
      };

  // The accent colour used for text / indicator on active tab.
  Color get _accentColor => darkTheme ? _vc.light : _vc.dark;

  // ── Theme helpers ──────────────────────────────────────────────────────

  Color get _idleTextColor =>
      darkTheme ? AppColors.colorNeutral400 : AppColors.colorNeutral500;

  Color get _hoverTextColor =>
      darkTheme ? AppColors.colorNeutral200 : AppColors.colorNeutral600;

  Color get _dividerColor =>
      darkTheme ? AppColors.colorNeutral600 : AppColors.colorNeutral200;

  Color get _pillBg =>
      darkTheme ? AppColors.colorNeutral600 : AppColors.colorNeutral100;

  Color get _pillBorder =>
      darkTheme ? AppColors.colorNeutral500 : AppColors.colorNeutral200;

  Color get _pillHoverBg =>
      darkTheme ? AppColors.colorNeutral500 : AppColors.colorNeutral200;

  Color get _cardTabBg =>
      darkTheme ? AppColors.colorNeutral600 : AppColors.colorNeutral100;

  Color get _cardTabBorder =>
      darkTheme ? AppColors.colorNeutral500 : AppColors.colorNeutral200;

  Color get _cardActiveTabBg =>
      darkTheme ? AppColors.colorNeutral900 : Colors.white;

  Color get _badgeIdleBg =>
      darkTheme ? AppColors.colorNeutral600 : AppColors.colorNeutral200;

  Color get _badgeIdleText =>
      darkTheme ? AppColors.colorNeutral300 : AppColors.colorNeutral500;

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return switch (tabStyle) {
      TabStyle.pill => _buildPill(),
      TabStyle.card => _buildCard(),
      TabStyle.line => _buildLine(),
      TabStyle.underline => _buildUnderline(),
    };
  }

  // ── Pill style ─────────────────────────────────────────────────────────

  Widget _buildPill() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _pillBg,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: _pillBorder, width: 1.5),
      ),
      child: fullWidth
          ? _buildPillInner()
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: _buildPillInner(),
            ),
    );
  }

  Widget _buildPillInner() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // In full-width mode constraints are bounded; otherwise use intrinsic.
        final useIntrinsic = !fullWidth || !constraints.hasBoundedWidth;
        final totalWidth = useIntrinsic ? null : constraints.maxWidth;

        return SizedBox(
          width: totalWidth,
          child: Stack(
            children: [
              // Sliding active background
              if (totalWidth != null)
                _buildPillSlider(totalWidth)
              else
                _buildPillSliderIntrinsic(),

              // Tab buttons row
              Row(
                mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
                children: tabs.map((tab) {
                  return fullWidth
                      ? Expanded(
                          child: _PillTab(tab: tab, widget: this),
                        )
                      : _PillTab(tab: tab, widget: this);
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Sliding pill indicator for bounded (full-width) layout.
  Widget _buildPillSlider(double totalWidth) {
    final idx = tabs
        .indexWhere((t) => t.id == activeTab)
        .clamp(0, tabs.length - 1);
    final slotWidth = totalWidth / tabs.length;
    final vc = _vc;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      left: idx * slotWidth,
      top: 0,
      bottom: 0,
      width: slotWidth,
      child: Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [vc.light, vc.dark],
          ),
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          boxShadow: [
            BoxShadow(
              color: vc.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }

  /// Pill indicator for intrinsic (non-full-width) layout — no sliding,
  /// each tab renders its own active background.
  Widget _buildPillSliderIntrinsic() => const SizedBox.shrink();

  // ── Line style ─────────────────────────────────────────────────────────

  Widget _buildLine() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _dividerColor, width: 2)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: tabs
                .map((tab) => _LineTab(tab: tab, widget: this))
                .toList(),
          ),
        ),
      ),
    );
  }

  // ── Underline style ────────────────────────────────────────────────────

  Widget _buildUnderline() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _dividerColor, width: 1)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: tabs
                .map((tab) => _UnderlineTab(tab: tab, widget: this))
                .toList(),
          ),
        ),
      ),
    );
  }

  // ── Card style ─────────────────────────────────────────────────────────

  Widget _buildCard() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _dividerColor, width: 1.5)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: tabs
              .map((tab) => _CardTab(tab: tab, widget: this))
              .toList(),
        ),
      ),
    );
  }
}

// ─── Internal tab buttons ─────────────────────────────────────────────────────

/// Shared tab content (icon + label + badge).
class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.tab,
    required this.isActive,
    required this.textColor,
    required this.fontSize,
    required this.iconSize,
    required this.badgeBg,
    required this.badgeText,
  });

  final TabItem tab;
  final bool isActive;
  final Color textColor;
  final double fontSize;
  final double iconSize;
  final Color badgeBg;
  final Color badgeText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (tab.icon != null) ...[
          Icon(tab.icon, size: iconSize, color: textColor),
          SizedBox(width: fontSize * 0.45),
        ],
        Text(
          tab.label,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: textColor,
            height: 1,
          ),
        ),
        if (tab.badge != null) ...[
          SizedBox(width: fontSize * 0.45),
          _Badge(
            value: '${tab.badge}',
            bg: badgeBg,
            textColor: badgeText,
            fontSize: fontSize,
          ),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.value,
    required this.bg,
    required this.textColor,
    required this.fontSize,
  });

  final String value;
  final Color bg;
  final Color textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      constraints: BoxConstraints(minWidth: fontSize * 1.4),
      height: fontSize * 1.4,
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.35),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Center(
        child: Text(
          value,
          style: TextStyle(
            fontSize: fontSize * 0.7,
            fontWeight: FontWeight.w700,
            color: textColor,
            height: 1,
          ),
        ),
      ),
    );
  }
}

// ── Pill tab ───────────────────────────────────────────────────────────────────

class _PillTab extends StatefulWidget {
  const _PillTab({required this.tab, required this.widget});
  final TabItem tab;
  final CustomTabWidget widget;

  @override
  State<_PillTab> createState() => _PillTabState();
}

class _PillTabState extends State<_PillTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final w = widget.widget;
    final isActive = w.activeTab == widget.tab.id;
    final isDisabled = widget.tab.disabled;

    // In full-width mode the sliding background covers the active tab,
    // so we don't draw it here. In intrinsic mode we draw it per-tab.
    final bool drawOwnBg = !w.fullWidth && isActive;
    final vc = w._vc;

    Color textColor;
    if (isActive) {
      textColor = w.fullWidth ? vc.text : vc.text;
    } else if (_hovered && !isDisabled) {
      textColor = w._hoverTextColor;
    } else {
      textColor = w._idleTextColor;
    }

    Color badgeBg;
    Color badgeText;
    if (isActive) {
      badgeBg = Colors.white.withValues(alpha: 0.3);
      badgeText = vc.text;
    } else {
      badgeBg = w._badgeIdleBg;
      badgeText = w._badgeIdleText;
    }

    Widget content = Padding(
      padding: w._tabPadding,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: _TabContent(
          tab: widget.tab,
          isActive: isActive,
          textColor: textColor,
          fontSize: w._fontSize,
          iconSize: w._iconSize,
          badgeBg: badgeBg,
          badgeText: badgeText,
        ),
      ),
    );

    if (drawOwnBg) {
      content = Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [vc.light, vc.dark],
          ),
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          boxShadow: [
            BoxShadow(
              color: vc.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: content,
      );
    } else if (_hovered && !isDisabled && !isActive) {
      content = Container(
        decoration: BoxDecoration(
          color: w._pillHoverBg,
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
        ),
        child: content,
      );
    }

    return MouseRegion(
      cursor: isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) {
        if (!isDisabled) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() => _hovered = false),
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: GestureDetector(
          onTap: () => w._selectTab(widget.tab),
          child: content,
        ),
      ),
    );
  }
}

// ── Line tab ───────────────────────────────────────────────────────────────────

class _LineTab extends StatefulWidget {
  const _LineTab({required this.tab, required this.widget});
  final TabItem tab;
  final CustomTabWidget widget;

  @override
  State<_LineTab> createState() => _LineTabState();
}

class _LineTabState extends State<_LineTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final w = widget.widget;
    final isActive = w.activeTab == widget.tab.id;
    final isDisabled = widget.tab.disabled;
    final accentColor = w._accentColor;

    final textColor = isActive
        ? accentColor
        : (_hovered && !isDisabled ? w._hoverTextColor : w._idleTextColor);

    final badgeBg = isActive ? accentColor : w._badgeIdleBg;
    final badgeText = isActive ? Colors.white : w._badgeIdleText;

    return MouseRegion(
      cursor: isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) {
        if (!isDisabled) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() => _hovered = false),
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: GestureDetector(
          onTap: () => w._selectTab(widget.tab),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: w._tabPadding,
                child: _TabContent(
                  tab: widget.tab,
                  isActive: isActive,
                  textColor: textColor,
                  fontSize: w._fontSize,
                  iconSize: w._iconSize,
                  badgeBg: badgeBg,
                  badgeText: badgeText,
                ),
              ),
              // Bottom indicator
              Positioned(
                bottom: -2,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  height: 2,
                  decoration: BoxDecoration(
                    color: isActive ? accentColor : Colors.transparent,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(2),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Underline tab ──────────────────────────────────────────────────────────────

class _UnderlineTab extends StatefulWidget {
  const _UnderlineTab({required this.tab, required this.widget});
  final TabItem tab;
  final CustomTabWidget widget;

  @override
  State<_UnderlineTab> createState() => _UnderlineTabState();
}

class _UnderlineTabState extends State<_UnderlineTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final w = widget.widget;
    final isActive = w.activeTab == widget.tab.id;
    final isDisabled = widget.tab.disabled;
    final accentColor = w._accentColor;

    final textColor = isActive
        ? accentColor
        : (_hovered && !isDisabled ? w._hoverTextColor : w._idleTextColor);

    final badgeBg = isActive ? accentColor : w._badgeIdleBg;
    final badgeText = isActive ? Colors.white : w._badgeIdleText;

    return MouseRegion(
      cursor: isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) {
        if (!isDisabled) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() => _hovered = false),
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: GestureDetector(
          onTap: () => w._selectTab(widget.tab),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: w._tabPadding,
                child: _TabContent(
                  tab: widget.tab,
                  isActive: isActive,
                  textColor: textColor,
                  fontSize: w._fontSize,
                  iconSize: w._iconSize,
                  badgeBg: badgeBg,
                  badgeText: badgeText,
                ),
              ),
              // Animated underline — shrinks to 30% width when idle
              Positioned(
                bottom: -1,
                left: 0,
                right: 0,
                child: AnimatedFractionallySizedBox(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.bottomCenter,
                  widthFactor: isActive ? 1 : 0,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    height: 2,
                    decoration: BoxDecoration(
                      color: isActive ? accentColor : Colors.transparent,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Card tab ───────────────────────────────────────────────────────────────────

class _CardTab extends StatefulWidget {
  const _CardTab({required this.tab, required this.widget});
  final TabItem tab;
  final CustomTabWidget widget;

  @override
  State<_CardTab> createState() => _CardTabState();
}

class _CardTabState extends State<_CardTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final w = widget.widget;
    final isActive = w.activeTab == widget.tab.id;
    final isDisabled = widget.tab.disabled;
    final accentColor = w._accentColor;

    Color textColor;
    Color bgColor;
    Color borderColor;

    if (isActive) {
      textColor = accentColor;
      bgColor = w._cardActiveTabBg;
      borderColor = w._cardTabBorder;
    } else if (_hovered && !isDisabled) {
      textColor = w._hoverTextColor;
      bgColor = w._pillHoverBg;
      borderColor = w._cardTabBorder;
    } else {
      textColor = w._idleTextColor;
      bgColor = w._cardTabBg;
      borderColor = w._cardTabBorder;
    }

    final badgeBg = isActive ? accentColor : w._badgeIdleBg;
    final badgeText = isActive ? Colors.white : w._badgeIdleText;

    return MouseRegion(
      cursor: isDisabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      onEnter: (_) {
        if (!isDisabled) setState(() => _hovered = true);
      },
      onExit: (_) => setState(() => _hovered = false),
      child: Opacity(
        opacity: isDisabled ? 0.4 : 1.0,
        child: GestureDetector(
          onTap: () => w._selectTab(widget.tab),
          child: Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppColors.radiusMd),
                topRight: Radius.circular(AppColors.radiusMd),
              ),
              border: Border(
                top: BorderSide(color: borderColor, width: 1.5),
                left: BorderSide(color: borderColor, width: 1.5),
                right: BorderSide(color: borderColor, width: 1.5),
                bottom: BorderSide(color: borderColor, width: 1.5),
              ),
            ),
            child: Padding(
              padding: w._tabPadding,
              child: _TabContent(
                tab: widget.tab,
                isActive: isActive,
                textColor: textColor,
                fontSize: w._fontSize,
                iconSize: w._iconSize,
                badgeBg: badgeBg,
                badgeText: badgeText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
