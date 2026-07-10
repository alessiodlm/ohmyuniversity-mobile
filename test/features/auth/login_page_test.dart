import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ohmyuniversity/config/routes/app_routes.dart';
import 'package:ohmyuniversity/features/auth/domain/entities/auth_session_entity.dart';
import 'package:ohmyuniversity/features/auth/domain/entities/career_profile_entity.dart';
import 'package:ohmyuniversity/features/auth/domain/repositories/auth_repository.dart';
import 'package:ohmyuniversity/features/auth/domain/usecases/login_usecase.dart';
import 'package:ohmyuniversity/features/auth/presentation/pages/login_page.dart';
import 'package:ohmyuniversity/features/auth/presentation/providers/auth_provider.dart';
import 'package:ohmyuniversity/features/auth/presentation/widgets/university_search_select.dart';
import 'package:ohmyuniversity/features/academics/domain/entities/career_snapshot_entity.dart';
import 'package:ohmyuniversity/features/academics/domain/entities/exam_booking_history_entity.dart';
import 'package:ohmyuniversity/features/academics/domain/repositories/academic_repository.dart';
import 'package:ohmyuniversity/features/academics/domain/usecases/get_exam_booking_history_usecase.dart';
import 'package:ohmyuniversity/features/academics/presentation/providers/career_data_providers.dart';
import 'package:ohmyuniversity/shared/widgets/custom_button/custom_button_widget.dart';
import 'package:ohmyuniversity/shared/widgets/custom_toast/custom_toast_model.dart';
import 'package:ohmyuniversity/shared/widgets/custom_toast/custom_toast_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LoginPage', () {
    testWidgets('starts in university/ateneo mode with disabled credentials', (
      tester,
    ) async {
      await _pumpLogin(tester);

      expect(find.text('OhMyUniversity!'), findsOneWidget);
      expect(find.text('by OhMyOpenSource!'), findsOneWidget);
      expect(find.byKey(const Key('university-login-form')), findsOneWidget);
      expect(find.byKey(const Key('university-search')), findsOneWidget);
      expect(
        tester
            .widget<UniversitySearchSelect>(
              find.byKey(const Key('university-search')),
            )
            .universities,
        hasLength(112),
      );

      final email = _textField(tester, 'university-email');
      final password = _textField(tester, 'university-password');
      final submit = tester.widget<CustomButtonWidget>(
        find.byKey(const Key('university-submit')),
      );

      expect(email.enabled, isFalse);
      expect(password.enabled, isFalse);
      expect(submit.disabled, isTrue);
    });

    testWidgets('filters universities by name and short name', (tester) async {
      await _pumpLogin(tester);

      await tester.tap(_searchFieldFinder());
      await tester.pump();
      await tester.enterText(_searchFieldFinder(), 'unimol');
      await tester.pump();
      expect(find.byKey(const Key('university-option-unimol')), findsOneWidget);
      expect(find.byKey(const Key('university-option-polimi')), findsNothing);

      await tester.enterText(_searchFieldFinder(), 'Molise');
      await tester.pump();
      expect(find.byKey(const Key('university-option-unimol')), findsOneWidget);

      await tester.enterText(_searchFieldFinder(), 'ateneo inesistente');
      await tester.pump();
      expect(find.byKey(const Key('university-search-empty')), findsOneWidget);
    });

    testWidgets('validates university domains and clears email on change', (
      tester,
    ) async {
      await _pumpLogin(tester);
      await _selectUniversity(tester, 'unimol');

      expect(_textField(tester, 'university-email').enabled, isTrue);
      await _enterText(tester, 'university-email', 'mario@example.com');
      expect(find.textContaining('domini di UniMol'), findsOneWidget);

      await _enterText(tester, 'university-email', 'mario@studenti.unimol.it');
      await _enterText(tester, 'university-password', 'password');
      expect(find.textContaining('domini di UniMol'), findsNothing);
      expect(
        tester
            .widget<CustomButtonWidget>(
              find.byKey(const Key('university-submit')),
            )
            .disabled,
        isFalse,
      );

      await _selectUniversity(tester, 'casd');
      expect(_textField(tester, 'university-email').controller?.text, isEmpty);
    });

    testWidgets('blocks universities whose domains are unavailable', (
      tester,
    ) async {
      await _pumpLogin(tester);
      await _selectUniversity(tester, 'isuf');

      expect(
        find.byKey(const Key('university-domain-unavailable')),
        findsOneWidget,
      );
      expect(_textField(tester, 'university-email').enabled, isFalse);
      expect(
        tester
            .widget<CustomButtonWidget>(
              find.byKey(const Key('university-submit')),
            )
            .disabled,
        isTrue,
      );
    });

    testWidgets('limits real integration to UNIMOL', (tester) async {
      await _pumpLogin(tester);
      await _selectUniversity(tester, 'polimi');

      expect(
        find.byKey(const Key('university-integration-unavailable')),
        findsOneWidget,
      );
      expect(_textField(tester, 'university-email').enabled, isFalse);
      expect(
        tester
            .widget<CustomButtonWidget>(
              find.byKey(const Key('university-submit')),
            )
            .disabled,
        isTrue,
      );
    });

    testWidgets('keeps the overlay open until an option tap completes', (
      tester,
    ) async {
      await _pumpLogin(tester);
      await tester.tap(_searchFieldFinder());
      await tester.pump();
      await tester.enterText(_searchFieldFinder(), 'unimol');
      await tester.pump();

      final option = find.byKey(const Key('university-option-unimol'));
      final gesture = await tester.startGesture(tester.getCenter(option));
      await tester.pump();

      expect(option, findsOneWidget);

      await gesture.up();
      await tester.pump();

      expect(
        tester
            .widget<UniversitySearchSelect>(
              find.byKey(const Key('university-search')),
            )
            .selected
            ?.id,
        'unimol',
      );
      expect(_textField(tester, 'university-email').enabled, isTrue);
    });

    testWidgets('switches auth modes and reports unavailable providers', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await _pumpLogin(tester, container: container);

      await tester.tap(find.text('SPID'));
      await tester.pump();
      expect(find.byKey(const Key('spid-panel')), findsOneWidget);

      await tester.tap(find.byKey(const Key('spid-submit')));
      await tester.pump();
      expect(
        container.read(toastServiceProvider).single.variant,
        ToastVariant.warning,
      );
      expect(
        container.read(toastServiceProvider).single.message,
        contains('SPID'),
      );

      container.read(toastServiceProvider.notifier).dismissAll();
      await tester.tap(find.text('CIE'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('cie-submit')));
      await tester.pump();
      expect(
        container.read(toastServiceProvider).single.message,
        contains('CIE'),
      );

      container.read(toastServiceProvider.notifier).dismissAll();
    });

    testWidgets('partner form enables submit and uses warning toast', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await _pumpLogin(tester, container: container);

      await tester.tap(find.text('Partner'));
      await tester.pump();
      expect(find.byKey(const Key('partner-login-form')), findsOneWidget);

      await _enterText(tester, 'partner-email', 'info@azienda.it');
      await _enterText(tester, 'partner-password', 'password');
      expect(
        tester
            .widget<CustomButtonWidget>(find.byKey(const Key('partner-submit')))
            .disabled,
        isFalse,
      );

      await tester.tap(find.byKey(const Key('partner-submit')));
      await tester.pump();
      expect(
        container.read(toastServiceProvider).single.message,
        'Il login organizzazioni non è ancora attivo.',
      );

      container.read(toastServiceProvider.notifier).dismissAll();
      await tester.ensureVisible(find.byKey(const Key('partner-request-link')));
      await tester.tap(find.byKey(const Key('partner-request-link')));
      await tester.pump();
      expect(
        container.read(toastServiceProvider).single.message,
        contains('richiesta di accesso'),
      );

      container.read(toastServiceProvider.notifier).dismissAll();
    });

    testWidgets('resets university state after switching to partner', (
      tester,
    ) async {
      await _pumpLogin(tester);
      await _selectUniversity(tester, 'unimol');
      await _enterText(tester, 'university-email', 'mario@studenti.unimol.it');

      await tester.tap(find.text('Partner'));
      await tester.pump();
      await tester.tap(find.text('Università'));
      await tester.pump();

      final search = tester.widget<UniversitySearchSelect>(
        find.byKey(const Key('university-search')),
      );
      expect(search.selected, isNull);
      expect(
        tester.widget<TextField>(_searchFieldFinder()).controller?.text,
        isEmpty,
      );
      expect(_textField(tester, 'university-email').enabled, isFalse);
    });

    testWidgets('legal links use the custom toast service', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await _pumpLogin(tester, container: container);

      await tester.ensureVisible(find.byKey(const Key('terms-link')));
      await tester.tap(find.byKey(const Key('terms-link')));
      await tester.pump();
      expect(
        container.read(toastServiceProvider).single.message,
        contains('Termini & Condizioni'),
      );

      container.read(toastServiceProvider.notifier).dismissAll();
      await tester.tap(find.byKey(const Key('privacy-link')));
      await tester.pump();
      expect(
        container.read(toastServiceProvider).single.message,
        contains('Privacy Policy'),
      );

      container.read(toastServiceProvider.notifier).dismissAll();
    });

    testWidgets('logs in through the use case and navigates home', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          loginUseCaseProvider.overrideWithValue(
            LoginUseCase(_SuccessfulAuthRepository()),
          ),
          getExamBookingHistoryUseCaseProvider.overrideWithValue(
            GetExamBookingHistoryUseCase(_ImmediateAcademicRepository()),
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = GoRouter(
        initialLocation: AppRoutes.login,
        routes: [
          GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
          GoRoute(
            path: AppRoutes.home,
            name: AppRoutes.homeName,
            builder: (_, _) => const Scaffold(body: Text('HOME')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();

      await _selectUniversity(tester, 'unimol');
      await _enterText(tester, 'university-email', 'mario@studenti.unimol.it');
      await _enterText(tester, 'university-password', 'password');
      await tester.tap(find.byKey(const Key('university-submit')));
      await tester.pump();

      expect(
        tester
            .widget<CustomButtonWidget>(
              find.byKey(const Key('university-submit')),
            )
            .loading,
        isTrue,
      );

      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump();
      expect(container.read(isAuthenticatedProvider), isTrue);
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('shows an error toast when authentication fails', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          loginUseCaseProvider.overrideWithValue(
            LoginUseCase(_FailingAuthRepository()),
          ),
        ],
      );
      addTearDown(container.dispose);
      await _pumpLogin(tester, container: container);

      await _selectUniversity(tester, 'unimol');
      await _enterText(tester, 'university-email', 'mario@studenti.unimol.it');
      await _enterText(tester, 'university-password', 'password');
      await tester.tap(find.byKey(const Key('university-submit')));
      await tester.pump();

      expect(
        container.read(toastServiceProvider).single.variant,
        ToastVariant.error,
      );
      expect(
        container.read(toastServiceProvider).single.message,
        'Accesso non riuscito. Riprova.',
      );

      container.read(toastServiceProvider.notifier).dismissAll();
    });

    for (final width in [320.0, 360.0, 390.0]) {
      testWidgets('does not overflow at ${width.toInt()} px', (tester) async {
        tester.view.physicalSize = Size(width, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await _pumpLogin(tester);

        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsWidgets);
      });
    }

    testWidgets('remains scrollable with the keyboard open', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await _pumpLogin(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });

    testWidgets('keeps light styling when the host theme is dark', (
      tester,
    ) async {
      await _pumpLogin(tester, hostBrightness: Brightness.dark);

      final scaffoldContext = tester.element(find.byType(Scaffold).first);
      expect(Theme.of(scaffoldContext).brightness, Brightness.light);
      expect(
        tester.widget<Scaffold>(find.byType(Scaffold).first).backgroundColor,
        Colors.white,
      );
    });
  });
}

Future<void> _pumpLogin(
  WidgetTester tester, {
  ProviderContainer? container,
  Brightness hostBrightness = Brightness.light,
}) async {
  final ownedContainer = container ?? ProviderContainer();
  if (container == null) addTearDown(ownedContainer.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: ownedContainer,
      child: MaterialApp(
        theme: ThemeData(brightness: hostBrightness),
        home: const LoginPage(),
      ),
    ),
  );
  await tester.pump();
}

Finder _searchFieldFinder() => find.descendant(
  of: find.byKey(const Key('university-search-input')),
  matching: find.byType(TextField),
);

Future<void> _selectUniversity(WidgetTester tester, String id) async {
  await tester.tap(_searchFieldFinder());
  await tester.pump();
  await tester.enterText(_searchFieldFinder(), id);
  await tester.pump();
  await tester.tap(find.byKey(Key('university-option-$id')));
  await tester.pump();
}

TextField _textField(WidgetTester tester, String key) {
  return tester.widget<TextField>(
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField)),
  );
}

Future<void> _enterText(WidgetTester tester, String key, String value) async {
  final finder = find.descendant(
    of: find.byKey(Key(key)),
    matching: find.byType(TextField),
  );
  await tester.enterText(finder, value);
  await tester.pump();
}

class _FailingAuthRepository implements AuthRepository {
  @override
  Future<AuthSessionEntity> login({
    required String universityId,
    required String username,
    required String password,
  }) {
    throw Exception('Authentication failed');
  }

  @override
  Future<AuthSessionEntity> switchCareer(CareerProfileEntity profile) {
    throw Exception('Career switch failed');
  }

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<AuthSessionEntity?> currentSession() async => null;
}

class _SuccessfulAuthRepository implements AuthRepository {
  @override
  Future<AuthSessionEntity> login({
    required String universityId,
    required String username,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return AuthSessionEntity(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      universityId: universityId,
      username: username,
      nome: 'Mario',
      cognome: 'Rossi',
      profiles: const [],
    );
  }

  @override
  Future<AuthSessionEntity> switchCareer(CareerProfileEntity profile) async {
    return AuthSessionEntity(
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      universityId: profile.universityId,
      username: profile.studentNumber,
      nome: 'Mario',
      cognome: 'Rossi',
      profiles: const [],
    );
  }

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<AuthSessionEntity?> currentSession() async => null;
}

class _ImmediateAcademicRepository implements AcademicRepository {
  @override
  Future<CareerSnapshotEntity> getCareerSnapshot() {
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> getBookableExamSessions() async {
    return const [];
  }

  @override
  Future<List<Map<String, dynamic>>> getActiveExamBookings() async {
    return const [];
  }

  @override
  Future<List<ExamBookingHistoryEntity>> getExamBookingHistory(
    String password,
  ) async {
    return const [];
  }

  @override
  Future<List<ExamBookingHistoryEntity>?> getCachedExamBookingHistory() async {
    return const [];
  }

  @override
  Future<List<Map<String, dynamic>>> getSuggestedExams() async {
    return const [];
  }
}