import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../../../../core/constants/app_assets.dart';
import '../../models/dashboard_widget_item.dart';
import 'dashboard_widget_board.dart';
import 'home_welcome_card.dart';

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    super.key,
    required this.isEditing,
    required this.items,
    required this.onWidgetMoved,
    required this.onWidgetRemoved,
  });

  final bool isEditing;
  final List<DashboardWidgetItem> items;
  final void Function(String id, int columnDelta, int rowDelta) onWidgetMoved;
  final ValueChanged<String> onWidgetRemoved;

  static const _horizontalPadding = 24.0;
  static const _dashboardColumns = 4;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dashboardWidth =
              constraints.maxWidth - (_horizontalPadding * 2);
          final cellSize = dashboardWidth / _dashboardColumns;
          final occupiedRows = items.fold<int>(
            0,
            (maxRows, item) => math.max(maxRows, item.row + item.rowSpan),
          );
          final lowerContentHeight = math.max(
            430.0,
            math.max(
              constraints.maxHeight - 96,
              (occupiedRows * cellSize) + 48,
            ),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              _horizontalPadding,
              14,
              _horizontalPadding,
              120,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                children: [
                  const HomeWelcomeCard(),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: lowerContentHeight,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: items.isEmpty && !isEditing
                          ? const _DashboardEmptyContent()
                          : DashboardWidgetBoard(
                              items: items,
                              isEditing: isEditing,
                              onWidgetMoved: onWidgetMoved,
                              onWidgetRemoved: onWidgetRemoved,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DashboardEmptyContent extends StatelessWidget {
  const _DashboardEmptyContent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: Transform.translate(
            offset: const Offset(0, -38),
            child: Opacity(
              opacity: 0.72,
              child: Lottie.asset(
                AppAssets.homeBubbles,
                width: 250,
                height: 250,
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: Transform.translate(
            offset: const Offset(0, -4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'È tutto così pulito...',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea una home su misura aggiungendo i widget che preferisci.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.64),
                      fontWeight: FontWeight.w600,
                      height: 1.22,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 84,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Tieni premuto lo schermo per\naggiungere widget',
                textAlign: TextAlign.right,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.textPrimary.withValues(alpha: 0.58),
                  fontWeight: FontWeight.w600,
                  height: 1.18,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.touch_app_outlined,
                color: AppColors.textPrimary.withValues(alpha: 0.58),
                size: 31,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
