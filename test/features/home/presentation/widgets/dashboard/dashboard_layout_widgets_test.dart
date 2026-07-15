import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohmyuniversity/features/academics/data/mocks/exam_bookings_mock_data.dart';
import 'package:ohmyuniversity/features/academics/presentation/providers/appeals_controller.dart';
import 'package:ohmyuniversity/features/academics/presentation/providers/career_data_providers.dart';
import 'package:ohmyuniversity/features/home/presentation/models/dashboard_widget_item.dart';
import 'package:ohmyuniversity/features/home/presentation/models/dashboard_widget_option.dart';
import 'package:ohmyuniversity/features/home/presentation/widgets/dashboard/dashboard_grid.dart';
import 'package:ohmyuniversity/features/home/presentation/widgets/dashboard/dashboard_placed_widget_tile.dart';
import 'package:ohmyuniversity/features/home/presentation/widgets/dashboard/dashboard_widget_board.dart';
import 'package:ohmyuniversity/features/home/presentation/widgets/dashboard/dashboard_widget_picker.dart';

import '../../../../../helpers/career_test_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('dashboard placed tile moves and removes while editing', (
    tester,
  ) async {
    String? removedId;
    ({String id, int columnDelta, int rowDelta})? movement;

    await tester.pumpWidget(
      _dashboardScope(
        child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 240,
            height: 160,
            child: DashboardPlacedWidgetTile(
              item: _item,
              cellSize: 24,
              isEditing: true,
              onMoved: (id, columnDelta, rowDelta) {
                movement = (
                  id: id,
                  columnDelta: columnDelta,
                  rowDelta: rowDelta,
                );
              },
              onRemoved: (id) => removedId = id,
            ),
          ),
        ),
        ),
      ),
    );

    expect(find.text('Media aritmetica'), findsOneWidget);

    await tester.drag(
      find.byType(DashboardPlacedWidgetTile),
      const Offset(52, 0),
    );
    await tester.pump();

    expect(movement?.id, 'widget-1');
    expect(movement?.columnDelta, 2);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(removedId, 'widget-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard board lays out items and forwards callbacks', (
    tester,
  ) async {
    String? removedId;

    await tester.pumpWidget(
      _dashboardScope(
        child: MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 260,
            child: DashboardWidgetBoard(
              items: [_item],
              isEditing: true,
              onWidgetMoved: (_, _, _) {},
              onWidgetRemoved: (id) => removedId = id,
            ),
          ),
        ),
        ),
      ),
    );

    expect(find.text('Media aritmetica'), findsOneWidget);
    expect(find.byType(DashboardPlacedWidgetTile), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();

    expect(removedId, 'widget-1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard picker returns a selected widget on second tap', (
    tester,
  ) async {
    DashboardWidgetOption? selected;

    await tester.pumpWidget(
      _dashboardScope(
        child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  selected = await showModalBottomSheet<DashboardWidgetOption>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const DashboardWidgetPicker(),
                  );
                },
                child: const Text('Apri picker'),
              ),
            ),
          ),
        ),
        ),
      ),
    );

    await tester.tap(find.text('Apri picker'));
    await tester.pumpAndSettle();

    expect(find.text('Aggiungi alla home'), findsOneWidget);
    expect(find.text('Media aritmetica'), findsWidgets);
    expect(find.text('Orari lezioni'), findsNothing);

    await tester.tap(find.text('Media aritmetica').first);
    await tester.pump();
    await tester.longPressAt(
      tester.getCenter(find.text('Media aritmetica').first),
    );
    await tester.pumpAndSettle();

    expect(selected?.key, DashboardWidgetOptions.arithmeticAverage.key);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard grid renders its initial empty state', (tester) async {
    await tester.pumpWidget(
      _dashboardScope(
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(width: 390, height: 760, child: DashboardGrid()),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Pagina in allestimento'), findsNothing);
    expect(find.byKey(const Key('home-online-indicator')), findsOneWidget);
    expect(find.byKey(const Key('home-greeting')), findsOneWidget);
    expect(find.byKey(const Key('home-greeting-hand')), findsOneWidget);
    expect(
      find.byKey(const Key('dashboard-widget-picker-button')),
      findsNothing,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(DashboardGrid)),
    );
    await tester.pump(const Duration(milliseconds: 900));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Aggiungi alla home'), findsOneWidget);
    Navigator.of(tester.element(find.byType(DashboardWidgetPicker))).pop();
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      find.byKey(const Key('dashboard-widget-picker-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('dashboard-edit-close-button')));
    await tester.pump();

    expect(
      find.byKey(const Key('dashboard-widget-picker-button')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

const _item = DashboardWidgetItem(
  id: 'widget-1',
  option: DashboardWidgetOptions.arithmeticAverage,
  column: 0,
  row: 0,
  columnSpan: 3,
  rowSpan: 3,
);

Widget _dashboardScope({required Widget child}) {
  return ProviderScope(
    overrides: [
      careerSnapshotProvider.overrideWith(
        (ref) async => buildCareerTestSnapshot(),
      ),
      allExamBookingsProvider.overrideWithValue(examBookingsMockData),
    ],
    child: child,
  );
}
