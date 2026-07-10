import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ohmyuniversity/features/academics/data/mocks/exam_bookings_mock_data.dart';
import 'package:ohmyuniversity/features/academics/data/mocks/questionnaires_mock_data.dart';
import 'package:ohmyuniversity/features/academics/domain/entities/exam_booking_entity.dart';
import 'package:ohmyuniversity/features/academics/presentation/providers/appeals_controller.dart';
import 'package:ohmyuniversity/features/academics/presentation/providers/career_data_providers.dart';
import 'package:ohmyuniversity/features/academics/presentation/providers/questionnaires_provider.dart';
import 'package:ohmyuniversity/features/academics/presentation/views/appeals_overview_view.dart';
import 'package:ohmyuniversity/shared/widgets/custom_button/custom_button_widget.dart';

import '../../helpers/career_test_snapshot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('filters appeals by availability and search query', () {
    final container = _mockAppealsContainer();
    addTearDown(container.dispose);

    expect(container.read(visibleExamBookingsProvider), hasLength(6));

    container
        .read(appealsControllerProvider.notifier)
        .setFilter(AppealsFilter.available);
    expect(container.read(visibleExamBookingsProvider), hasLength(4));

    container.read(appealsControllerProvider.notifier).search('Laura Conti');
    final result = container.read(visibleExamBookingsProvider);
    expect(result, hasLength(1));
    expect(result.single.courseName, 'Sistemi Operativi');
  });

  test('enables bookings only for courses with a completed questionnaire', () {
    final container = _mockAppealsContainer();
    addTearDown(container.dispose);

    expect(
      container.read(isQuestionnaireCompletedProvider('Analisi Matematica II')),
      isTrue,
    );
    expect(
      container.read(
        isQuestionnaireCompletedProvider('Ingegneria del Software'),
      ),
      isTrue,
    );
    expect(
      container.read(
        isQuestionnaireCompletedProvider('Algoritmi e Strutture Dati'),
      ),
      isFalse,
    );
  });

  test('recommends pending exams from the study plan ordered by CFU', () async {
    final container = _mockAppealsWithCareerContainer();
    addTearDown(container.dispose);

    await container.read(careerSnapshotProvider.future);

    final recommendations = container.read(recommendedExamBookingsProvider);
    final credits = recommendations
        .map((recommendation) => recommendation.course.credits)
        .toList();

    expect(recommendations, isNotEmpty);
    expect(credits, orderedEquals([...credits]..sort()));
    expect(recommendations.first.course.credits, 6);

    final operatingSystems = recommendations.firstWhere(
      (recommendation) => recommendation.course.name == 'Sistemi Operativi',
    );
    expect(operatingSystems.appeal?.id, 'e2');
    expect(operatingSystems.appeal?.status, ExamBookingStatus.closing);

    container.read(appealsControllerProvider.notifier).search('reti');
    final filtered = container.read(recommendedExamBookingsProvider);

    expect(filtered, hasLength(1));
    expect(filtered.single.course.name, 'Reti di Calcolatori');
    expect(filtered.single.appeal?.id, 'e5');
  });

  testWidgets('is responsive and confirms an eligible booking', (tester) async {
    tester.view.physicalSize = const Size(320, 760);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = _mockAppealsContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: AppealsOverviewView())),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Analisi Matematica II');
    await tester.pump();
    expect(find.byKey(const Key('exam-booking-card-e4')), findsOneWidget);
    expect(find.byKey(const Key('exam-booking-card-e1')), findsNothing);
    expect(find.text('12 CFU'), findsOneWidget);
    expect(find.text('L · 12 CFU · Anno 2'), findsNothing);

    final button = find.byKey(const Key('book-exam-e4'));
    await tester.scrollUntilVisible(
      button,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('confirm-exam-booking')), findsOneWidget);
    expect(
      container.read(appealsControllerProvider).bookedIds,
      isNot(contains('e4')),
    );

    await tester.tap(find.byKey(const Key('confirm-exam-booking')));
    await tester.pumpAndSettle();

    expect(
      container.read(appealsControllerProvider).bookedIds,
      isNot(contains('e4')),
    );
    expect(find.byKey(const Key('confirm-exam-booking')), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
  });

  testWidgets('locks booking until questionnaire and shows details on demand', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appealsControllerProvider.overrideWith(_MockAppealsController.new),
          remoteQuestionnairesProvider.overrideWith(
            (ref) async => questionnairesMockData,
          ),
          suggestedExamsProvider.overrideWith(
            (ref) async => const <Map<String, dynamic>>[],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: AppealsOverviewView())),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Algoritmi');
    await tester.pump();

    final bookingButton = tester.widget<CustomButtonWidget>(
      find.byKey(const Key('book-exam-e1')),
    );
    expect(bookingButton.disabled, isTrue);
    expect(bookingButton.label, 'Questionario da compilare');
    expect(find.text('Prof. Mario Bianchi'), findsNothing);
    expect(find.text('Aula A1'), findsNothing);

    await tester.tap(find.byKey(const Key('exam-info-e1')));
    await tester.pumpAndSettle();

    expect(find.text('Dettagli appello'), findsOneWidget);
    expect(find.text('Prof. Mario Bianchi'), findsOneWidget);
    expect(find.text('Aula A1'), findsOneWidget);
    expect(find.text('34 su 80'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the empty state when no exam matches', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appealsControllerProvider.overrideWith(_MockAppealsController.new),
          remoteQuestionnairesProvider.overrideWith(
            (ref) async => questionnairesMockData,
          ),
          suggestedExamsProvider.overrideWith(
            (ref) async => const <Map<String, dynamic>>[],
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: AppealsOverviewView())),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'corso inesistente');
    await tester.pump();

    expect(find.byKey(const Key('appeals-empty-state')), findsOneWidget);
    expect(find.text('0 risultati trovati'), findsOneWidget);
  });
}

ProviderContainer _mockAppealsContainer() {
  return ProviderContainer(
    overrides: [
      appealsControllerProvider.overrideWith(_MockAppealsController.new),
      remoteQuestionnairesProvider.overrideWith(
        (ref) async => questionnairesMockData,
      ),
      suggestedExamsProvider.overrideWith(
        (ref) async => const <Map<String, dynamic>>[],
      ),
    ],
  );
}

ProviderContainer _mockAppealsWithCareerContainer() {
  return ProviderContainer(
    overrides: [
      appealsControllerProvider.overrideWith(_MockAppealsController.new),
      remoteQuestionnairesProvider.overrideWith(
        (ref) async => questionnairesMockData,
      ),
      suggestedExamsProvider.overrideWith(
        (ref) async => const <Map<String, dynamic>>[],
      ),
      careerSnapshotProvider.overrideWith(
        (ref) async => buildCareerTestSnapshot(),
      ),
    ],
  );
}

class _MockAppealsController extends AppealsController {
  @override
  AppealsState build() {
    return AppealsState(examBookings: examBookingsMockData, loaded: true);
  }

  @override
  Future<void> loadAvailableAppeals() async {}
}