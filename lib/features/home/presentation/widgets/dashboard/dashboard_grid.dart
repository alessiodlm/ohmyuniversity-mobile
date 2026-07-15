import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../config/theme/app_colors.dart';
import '../../models/dashboard_widget_item.dart';
import '../../models/dashboard_widget_option.dart';
import 'dashboard_empty_state.dart';
import 'dashboard_widget_picker.dart';

class DashboardGrid extends StatefulWidget {
  const DashboardGrid({super.key});

  @override
  State<DashboardGrid> createState() => _DashboardGridState();
}

class _DashboardGridState extends State<DashboardGrid> {
  static const _columns = 10;
  static const _maxRows = 48;

  Timer? _longPressTimer;
  bool _isEditing = false;
  bool _hasActivatedWidgetControls = false;
  int _nextWidgetId = 0;
  final List<DashboardWidgetItem> _items = [];

  @override
  void dispose() {
    _cancelLongPressTimer();
    super.dispose();
  }

  void _startLongPressTimer() {
    if (_isEditing) return;

    _cancelLongPressTimer();
    _longPressTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted) return;

      HapticFeedback.mediumImpact();
      _longPressTimer = null;

      if (_items.isEmpty) {
        _openWidgetPicker();
        return;
      }

      setState(() {
        _hasActivatedWidgetControls = true;
        _isEditing = true;
      });
    });
  }

  void _cancelLongPressTimer() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
  }

  void _exitEditMode() {
    _cancelLongPressTimer();
    if (!_isEditing) return;

    HapticFeedback.selectionClick();
    setState(() => _isEditing = false);
  }

  void _addWidget(DashboardWidgetOption option) {
    final position = _findFirstFreePosition(
      columnSpan: option.columnSpan,
      rowSpan: option.rowSpan,
    );

    if (position == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Non c\'è spazio libero nella dashboard'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }

    setState(() {
      _items.add(
        DashboardWidgetItem(
          id: 'dashboard-widget-${_nextWidgetId++}',
          option: option,
          column: position.column,
          row: position.row,
          columnSpan: option.columnSpan,
          rowSpan: option.rowSpan,
        ),
      );
      _isEditing = true;
    });
  }

  void _removeWidget(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      _items.removeWhere((item) => item.id == id);
      _isEditing = true;
    });
  }

  void _moveWidget(String id, int columnDelta, int rowDelta) {
    setState(() {
      final index = _items.indexWhere((item) => item.id == id);
      if (index == -1) return;

      final item = _items[index];
      final maxColumn = _columns - item.columnSpan;
      final nextColumn = (item.column + columnDelta).clamp(0, maxColumn);
      final nextRow = (item.row + rowDelta).clamp(0, _maxRows - item.rowSpan);
      final candidate = item.copyWith(column: nextColumn, row: nextRow);

      if (!_isAreaFree(candidate, movingItemId: id)) {
        HapticFeedback.selectionClick();
        return;
      }

      _items[index] = candidate;
    });
  }

  _GridPosition? _findFirstFreePosition({
    required int columnSpan,
    required int rowSpan,
  }) {
    for (var row = 0; row <= _maxRows - rowSpan; row++) {
      for (var column = 0; column <= _columns - columnSpan; column++) {
        final candidate = DashboardWidgetItem(
          id: 'candidate',
          option: DashboardWidgetOptions.placeholder,
          column: column,
          row: row,
          columnSpan: columnSpan,
          rowSpan: rowSpan,
        );

        if (_isAreaFree(candidate)) {
          return _GridPosition(column: column, row: row);
        }
      }
    }

    return null;
  }

  bool _isAreaFree(DashboardWidgetItem candidate, {String? movingItemId}) {
    if (candidate.column < 0 || candidate.row < 0) return false;
    if (candidate.column + candidate.columnSpan > _columns) return false;
    if (candidate.row + candidate.rowSpan > _maxRows) return false;

    for (final item in _items) {
      if (item.id == movingItemId) continue;
      if (_itemsOverlap(candidate, item)) return false;
    }

    return true;
  }

  bool _itemsOverlap(DashboardWidgetItem first, DashboardWidgetItem second) {
    final firstRight = first.column + first.columnSpan;
    final firstBottom = first.row + first.rowSpan;
    final secondRight = second.column + second.columnSpan;
    final secondBottom = second.row + second.rowSpan;

    return first.column < secondRight &&
        firstRight > second.column &&
        first.row < secondBottom &&
        firstBottom > second.row;
  }

  Future<void> _openWidgetPicker() async {
    _cancelLongPressTimer();
    setState(() {
      _hasActivatedWidgetControls = true;
      _isEditing = true;
    });

    final selectedWidget = await showModalBottomSheet<DashboardWidgetOption>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const DashboardWidgetPicker(),
    );

    if (!mounted || selectedWidget == null) return;

    _addWidget(selectedWidget);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _startLongPressTimer(),
      onTapUp: (_) => _cancelLongPressTimer(),
      onTapCancel: _cancelLongPressTimer,
      child: Stack(
        children: [
          Positioned.fill(
            child: DashboardEmptyState(
              isEditing: _isEditing,
              items: _items,
              onWidgetMoved: _moveWidget,
              onWidgetRemoved: _removeWidget,
            ),
          ),
          if (_isEditing)
            Positioned(
              right: 20,
              bottom: 78,
              child: FloatingActionButton.small(
                key: const Key('dashboard-edit-close-button'),
                heroTag: 'dashboard-edit-close',
                backgroundColor: const Color(0xFFE84C4F),
                foregroundColor: Colors.white,
                elevation: 4,
                shape: const CircleBorder(),
                onPressed: _exitEditMode,
                child: const Icon(LucideIcons.x),
              ),
            ),
          if (_hasActivatedWidgetControls)
            Positioned(
              right: 20,
              bottom: 24,
              child: FloatingActionButton.small(
                key: const Key('dashboard-widget-picker-button'),
                heroTag: 'dashboard-widget-picker',
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.textPrimary,
                elevation: 4,
                shape: const CircleBorder(),
                onPressed: _openWidgetPicker,
                child: const Icon(LucideIcons.plus),
              ),
            ),
        ],
      ),
    );
  }
}

class _GridPosition {
  const _GridPosition({required this.column, required this.row});

  final int column;
  final int row;
}
