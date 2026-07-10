// @file avatar_profile_panel_widget.dart
// @description Account switcher panel built around avatar-based selection.
// Supports multi-account display, profile header, and action section
// (add account, settings, logout) with animated dropdown behavior.

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../config/theme/app_colors.dart';
import '../custom_avatar/custom_avatar_widget.dart';

// ─── Domain types ─────────────────────────────────────────────────────────────

/// Account status — drives avatar variant and ring colour.
enum AccountStatus {
  active, // → success (verde)
  warning, // → warning (giallo)
  suspended, // → error   (rosso)
  withdrawn, // → neutral (grigio)
  graduated, // → primary (blu)
}

/// Panel horizontal position relative to the trigger avatar.
enum PanelPosition { left, right }

/// Animation preset for panel open/close behaviour.
///
/// - [ios]    — scale from anchor (iOS-style popover)
/// - [gmail]  — vertical slide + fade (Gmail account menu)
/// - [fade]   — opacity only
/// - [scale]  — generic scale from anchor
enum PanelAnimation { ios, gmail, fade, scale }

/// Account item displayed inside the panel.
class AccountEntry {
  const AccountEntry({
    required this.id,
    required this.name,
    required this.courseLabel,
    required this.email,
    required this.universityLabel,
    required this.courseAcronym,
    this.avatarSrc,
    required this.status,
    this.isCurrent = false,
  });

  final String id;
  final String name;
  final String courseLabel;
  final String email;
  final String universityLabel;
  final String courseAcronym;
  final String? avatarSrc;
  final AccountStatus status;
  final bool isCurrent;
}

// ─── Mapping helpers ──────────────────────────────────────────────────────────

AvatarVariant _variantFor(AccountStatus status) => switch (status) {
  AccountStatus.active => AvatarVariant.success,
  AccountStatus.warning => AvatarVariant.warning,
  AccountStatus.suspended => AvatarVariant.error,
  AccountStatus.withdrawn => AvatarVariant.neutral,
  AccountStatus.graduated => AvatarVariant.primary,
};

Color _ringColorFor(AccountStatus status) => switch (status) {
  AccountStatus.active => AppColors.colorSuccessDark,
  AccountStatus.warning => AppColors.colorWarningDark,
  AccountStatus.suspended => AppColors.colorErrorDark,
  AccountStatus.withdrawn => AppColors.colorNeutral400,
  AccountStatus.graduated => AppColors.colorPrimaryDark,
};

/// Returns background + text colours for the course acronym badge.
({Color bg, Color text, Color border}) _acronymColors(String acronym) {
  return switch (acronym) {
    'L' => (
      bg: const Color(0xFFE0F2FE),
      text: const Color(0xFF075985),
      border: const Color(0xFF7DD3FC),
    ),
    'LM' => (
      bg: const Color(0xFFEDE9FE),
      text: const Color(0xFF5B21B6),
      border: const Color(0xFFC4B5FD),
    ),
    'LMcu' => (
      bg: const Color(0xFFF3E8FF),
      text: const Color(0xFF6B21A8),
      border: const Color(0xFFD8B4FE),
    ),
    'DOC' => (
      bg: const Color(0xFFFEF3C7),
      text: const Color(0xFF92400E),
      border: const Color(0xFFFCD34D),
    ),
    'DOT' => (
      bg: const Color(0xFFFFEDD5),
      text: const Color(0xFF9A3412),
      border: const Color(0xFFFDBA74),
    ),
    'MASTER' => (
      bg: const Color(0xFFD1FAE5),
      text: const Color(0xFF065F46),
      border: const Color(0xFF6EE7B7),
    ),
    _ => (
      bg: const Color(0xFFF3F4F6),
      text: const Color(0xFF374151),
      border: const Color(0xFFD1D5DB),
    ),
  };
}

// ─── Widget ───────────────────────────────────────────────────────────────────

/// Account switcher panel with avatar trigger.
///
/// Usage:
/// ```dart
/// AvatarProfilePanelWidget(
///   accounts: accounts,
///   onAccountSwitch: (account) { ... },
///   onLogout: () { ... },
/// )
/// ```
class AvatarProfilePanelWidget extends StatefulWidget {
  const AvatarProfilePanelWidget({
    super.key,
    required this.accounts,
    this.darkTheme = false,
    this.showSettings = true,
    this.showLogout = true,
    this.showAddAccount = false,
    this.position = PanelPosition.right,
    this.animation = PanelAnimation.ios,
    this.panelWidth = 300,
    this.onProfileClick,
    this.onAccountSwitch,
    this.onSettingsClick,
    this.onLogoutClick,
    this.onAddAccount,
    this.onPanelClose,
  });

  /// All accounts to display. The one with [AccountEntry.isCurrent] == true
  /// (or the first) is used as the trigger avatar.
  final List<AccountEntry> accounts;

  final bool darkTheme;
  final bool showSettings;
  final bool showLogout;
  final bool showAddAccount;

  /// Panel horizontal position relative to the trigger.
  final PanelPosition position;

  /// Animation preset for open/close.
  final PanelAnimation animation;

  /// Panel width in logical pixels.
  final double panelWidth;

  final VoidCallback? onProfileClick;
  final ValueChanged<AccountEntry>? onAccountSwitch;
  final VoidCallback? onSettingsClick;
  final VoidCallback? onLogoutClick;
  final VoidCallback? onAddAccount;
  final VoidCallback? onPanelClose;

  @override
  State<AvatarProfilePanelWidget> createState() =>
      _AvatarProfilePanelWidgetState();
}

class _AvatarProfilePanelWidgetState extends State<AvatarProfilePanelWidget>
    with SingleTickerProviderStateMixin {
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final Animation<Offset> _slideAnim;
  final _triggerKey = GlobalKey();

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(
      begin: _scaleBegin,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  double get _scaleBegin => switch (widget.animation) {
    PanelAnimation.ios => 0.75,
    PanelAnimation.scale => 0.90,
    _ => 1.0,
  };

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    super.dispose();
  }

  // ── Accounts helpers ───────────────────────────────────────────────────

  AccountEntry? get _currentAccount =>
      widget.accounts.where((a) => a.isCurrent).firstOrNull ??
      widget.accounts.firstOrNull;

  // ── Overlay management ─────────────────────────────────────────────────

  void _toggle() {
    _isOpen ? _close() : _open();
  }

  void _open() {
    if (_isOpen) return;
    setState(() => _isOpen = true);
    _overlayEntry = _buildOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    _controller.forward(from: 0);
  }

  Future<void> _close() async {
    if (!_isOpen) return;
    await _controller.reverse();
    _removeOverlay();
    setState(() => _isOpen = false);
    widget.onPanelClose?.call();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // ── Overlay position ───────────────────────────────────────────────────

  /// Computes panel [left] and [top] in global coordinates from the trigger.
  ({double left, double top}) _panelOffset() {
    final box = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return (left: 0, top: 0);
    final pos = box.localToGlobal(Offset.zero);
    final triggerW = box.size.width;
    final top = pos.dy;

    final left = switch (widget.position) {
      PanelPosition.right => pos.dx,
      PanelPosition.left => pos.dx + triggerW - widget.panelWidth,
    };

    return (left: left, top: top);
  }

  // ── Overlay entry ──────────────────────────────────────────────────────

  OverlayEntry _buildOverlayEntry() {
    return OverlayEntry(
      builder: (_) {
        final offset = _panelOffset();
        return Stack(
          children: [
            // Barrier — captures click-outside
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _close,
              ),
            ),
            // Panel
            Positioned(
              left: offset.left,
              top: offset.top,
              width: widget.panelWidth,
              child: _buildAnimatedPanel(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedPanel() {
    Widget panel = _PanelContent(
      accounts: widget.accounts,
      darkTheme: widget.darkTheme,
      position: widget.position,
      showSettings: widget.showSettings,
      showLogout: widget.showLogout,
      showAddAccount: widget.showAddAccount,
      onProfile: () {
        widget.onProfileClick?.call();
        _close();
      },
      onAccountSwitch: (account) {
        widget.onAccountSwitch?.call(account);
        _close();
      },
      onSettings: () {
        widget.onSettingsClick?.call();
        _close();
      },
      onLogout: () {
        widget.onLogoutClick?.call();
        _close();
      },
      onAdd: () {
        widget.onAddAccount?.call();
        _close();
      },
    );

    // Wrap with Escape key handler
    panel = KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      onKeyEvent: (e) {
        if (e.logicalKey.keyLabel == 'Escape') _close();
      },
      child: panel,
    );

    return switch (widget.animation) {
      PanelAnimation.ios || PanelAnimation.scale => AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            alignment: widget.position == PanelPosition.right
                ? Alignment.topLeft
                : Alignment.topRight,
            child: child,
          ),
        ),
        child: panel,
      ),
      PanelAnimation.gmail => AnimatedBuilder(
        animation: _controller,
        builder: (_, child) => FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(position: _slideAnim, child: child),
        ),
        child: panel,
      ),
      PanelAnimation.fade => FadeTransition(opacity: _fadeAnim, child: panel),
    };
  }

  // ── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final current = _currentAccount;
    if (current == null) return const SizedBox.shrink();

    return SizedBox(
      key: _triggerKey,
      child: CustomAvatarWidget(
        src: current.avatarSrc,
        name: current.name,
        variant: _variantFor(current.status),
        showRing: true,
        ringSize: AvatarRingSize.lg,
        ringGap: true,
        ringColor: _ringColorFor(current.status),
        size: AvatarSize.md,
        shape: AvatarShape.circle,
        clickable: true,
        darkTheme: widget.darkTheme,
        ariaLabel: 'Profilo di ${current.name}',
        onTap: _toggle,
      ),
    );
  }
}

// ─── Panel content (inner stateless widget) ───────────────────────────────────

class _PanelContent extends StatelessWidget {
  const _PanelContent({
    required this.accounts,
    required this.darkTheme,
    required this.position,
    required this.showSettings,
    required this.showLogout,
    required this.showAddAccount,
    required this.onProfile,
    required this.onAccountSwitch,
    required this.onSettings,
    required this.onLogout,
    required this.onAdd,
  });

  final List<AccountEntry> accounts;
  final bool darkTheme;
  final PanelPosition position;
  final bool showSettings;
  final bool showLogout;
  final bool showAddAccount;
  final VoidCallback onProfile;
  final ValueChanged<AccountEntry> onAccountSwitch;
  final VoidCallback onSettings;
  final VoidCallback onLogout;
  final VoidCallback onAdd;

  // ── Theme helpers ────────────────────────────────────────────────────

  Color get _bgColor => darkTheme ? const Color(0xFF111827) : Colors.white;

  Color get _borderColor =>
      darkTheme ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

  Color get _textColor =>
      darkTheme ? const Color(0xFFF3F4F6) : const Color(0xFF1F2937);

  Color get _subtextColor =>
      darkTheme ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

  Color get _dividerColor =>
      darkTheme ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

  Color get _hoverColor =>
      darkTheme ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB);

  Color get _badgeBg =>
      darkTheme ? const Color(0xFF374151) : const Color(0xFFF3F4F6);

  Color get _badgeText =>
      darkTheme ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280);

  // ── Acronym badge ────────────────────────────────────────────────────

  Widget _acronymBadge(String acronym, {double fontSize = 9}) {
    final c = _acronymColors(acronym);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border),
      ),
      child: Text(
        acronym,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: c.text,
          height: 1.2,
        ),
      ),
    );
  }

  Widget _buildCurrentItem(BuildContext context, AccountEntry acc) {
    final isLeft = position == PanelPosition.left;

    final avatar = CustomAvatarWidget(
      src: acc.avatarSrc,
      name: acc.name,
      variant: _variantFor(acc.status),
      showRing: true,
      ringSize: AvatarRingSize.lg,
      ringGap: true,
      ringColor: _ringColorFor(acc.status),
      size: AvatarSize.lg,
      shape: AvatarShape.circle,
      darkTheme: darkTheme,
    );

    final info = Expanded(
      child: Column(
        crossAxisAlignment: isLeft
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            acc.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            acc.email,
            style: TextStyle(fontSize: 11, color: _subtextColor),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            acc.courseLabel,
            style: TextStyle(fontSize: 11, color: _subtextColor),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _badgeBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              acc.universityLabel,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: _badgeText,
              ),
              overflow: TextOverflow.ellipsis,
              textAlign: isLeft ? TextAlign.right : TextAlign.left,
            ),
          ),
        ],
      ),
    );

    final acronymBadge = SizedBox(
      width: 48,
      child: Align(
        alignment: Alignment.centerRight,
        child: _acronymBadge(acc.courseAcronym, fontSize: 9),
      ),
    );

    final children = isLeft
        ? [acronymBadge, info, avatar]
        : [avatar, info, acronymBadge];

    return InkWell(
      key: const Key('profile-panel-current-account'),
      onTap: onProfile,
      hoverColor: _hoverColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            children[0],
            const SizedBox(width: 12),
            children[1],
            const SizedBox(width: 12),
            children[2],
          ],
        ),
      ),
    );
  }

  Widget _buildOtherItem(BuildContext context, AccountEntry acc) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onAccountSwitch(acc),
        hoverColor: _hoverColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CustomAvatarWidget(
                src: acc.avatarSrc,
                name: acc.name,
                variant: _variantFor(acc.status),
                showRing: true,
                ringSize: AvatarRingSize.sm,
                ringGap: true,
                ringColor: _ringColorFor(acc.status),
                size: AvatarSize.sm,
                shape: AvatarShape.circle,
                darkTheme: darkTheme,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      acc.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      acc.courseLabel,
                      style: TextStyle(fontSize: 10, color: _subtextColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      acc.universityLabel,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: darkTheme
                            ? const Color(0xFF6B7280)
                            : const Color(0xFF9CA3AF),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _acronymBadge(acc.courseAcronym, fontSize: 8.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Action button ────────────────────────────────────────────────────

  Widget _buildAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? textColor,
    Color? hoverColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: hoverColor ?? _hoverColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 14, color: textColor ?? _subtextColor),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor ?? _subtextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Divider ──────────────────────────────────────────────────────────

  Widget get _divider => Divider(height: 1, thickness: 1, color: _dividerColor);

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(16),
      color: _bgColor,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _borderColor),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Accounts ──
              if (accounts.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                  child: Text(
                    'ALTRI ACCOUNT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.08,
                      color: _subtextColor,
                    ),
                  ),
                ),
                ...accounts.map(
                  (acc) => acc.isCurrent
                      ? _buildCurrentItem(context, acc)
                      : _buildOtherItem(context, acc),
                ),
                _divider,
              ],

              // ── Actions ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showAddAccount)
                      _buildAction(
                        icon: LucideIcons.plus,
                        label: 'Aggiungi account',
                        onTap: onAdd,
                      ),
                    if (showSettings)
                      _buildAction(
                        icon: LucideIcons.settings,
                        label: 'Impostazioni profilo',
                        onTap: onSettings,
                      ),
                    if (showLogout)
                      _buildAction(
                        icon: LucideIcons.logOut,
                        label: 'Esci',
                        onTap: onLogout,
                        textColor: const Color(0xFFEF4444),
                        hoverColor: darkTheme
                            ? const Color(0xFF450A0A).withValues(alpha: 0.3)
                            : const Color(0xFFFEF2F2),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}