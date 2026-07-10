import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../config/theme/app_colors.dart';
import '../../../../shared/widgets/custom_input/custom_input_widget.dart';
import '../../../../shared/widgets/custom_card/custom_card_widget.dart';
import '../../../../shared/widgets/custom_tab/custom_tab_widget.dart';
import '../../../../shared/widgets/custom_toast/custom_toast_service.dart';
import '../../domain/entities/exam_booking_entity.dart';
import '../providers/appeals_controller.dart';
import '../providers/career_provider.dart';
import '../providers/questionnaires_provider.dart';
import '../widgets/exam_booking_card.dart';
import '../widgets/exam_booking_sheets.dart';

class AppealsOverviewView extends ConsumerStatefulWidget {
  const AppealsOverviewView({super.key});

  @override
  ConsumerState<AppealsOverviewView> createState() =>
      _AppealsOverviewViewState();
}

class _AppealsOverviewViewState extends ConsumerState<AppealsOverviewView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(appealsControllerProvider.notifier).loadAvailableAppeals(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appealsControllerProvider);
    final exams = ref.watch(visibleExamBookingsProvider);
    final recommendations = ref.watch(recommendedExamBookingsProvider);
    final career = ref.watch(careerProvider);
    final resultCount = state.filter == AppealsFilter.recommended
        ? recommendations.length
        : exams.length;

    return ListView(
      key: const Key('appeals-overview-list'),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 112),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          'Appelli',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.colorNeutral900,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Cerca un appello, controlla i posti e prenota il tuo esame.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.colorNeutral500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        CustomInputWidget(
          key: const Key('appeals-search'),
          type: InputType.search,
          size: InputSize.sm,
          placeholder: 'Cerca per corso, docente o aula...',
          iconLeft: LucideIcons.search,
          clearable: true,
          onChanged: ref.read(appealsControllerProvider.notifier).search,
          onCleared: () =>
              ref.read(appealsControllerProvider.notifier).search(''),
        ),
        const SizedBox(height: 12),
        CustomTabWidget(
          key: const Key('appeals-filter-tabs'),
          tabs: const [
            TabItem(id: 'all', label: 'Tutti'),
            TabItem(id: 'booked', label: 'Prenotati'),
            TabItem(id: 'available', label: 'Disponibili'),
            TabItem(id: 'recommended', label: 'Consigliati'),
          ],
          activeTab: state.filter.name,
          tabStyle: TabStyle.pill,
          size: TabSize.sm,
          fullWidth: true,
          onTabChange: (id) => ref
              .read(appealsControllerProvider.notifier)
              .setFilter(AppealsFilter.values.byName(id)),
        ),
        const SizedBox(height: 10),
        Text(
          '$resultCount ${resultCount == 1 ? 'risultato trovato' : 'risultati trovati'}',
          key: const Key('appeals-results-count'),
          style: const TextStyle(
            color: AppColors.colorNeutral400,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        if (state.filter == AppealsFilter.recommended) ...[
          const _RecommendationsInfoCard(),
          const SizedBox(height: 12),
        ],
        if (state.filter == AppealsFilter.recommended) ...[
          if (career.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (career.errorMessage != null)
            _HistoryError(message: career.errorMessage!)
          else if (recommendations.isEmpty)
            const _EmptyAppeals(
              message: 'Non risultano esami ancora da superare.',
            )
          else ...[
            if (state.error != null) ...[
              const _AppealsAvailabilityWarning(),
              const SizedBox(height: 10),
            ],
            for (var index = 0; index < recommendations.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RecommendedCourseCard(
                  recommendation: recommendations[index],
                  position: index + 1,
                ),
              ),
          ],
        ] else if (state.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (state.error != null)
          _HistoryError(
            message: state.error!,
            onRetry: () => ref
                .read(appealsControllerProvider.notifier)
                .loadAvailableAppeals(),
          )
        else if (exams.isEmpty)
          _EmptyAppeals(
            message: state.filter == AppealsFilter.booked
                ? 'Nessuna prenotazione trovata.'
                : 'Nessun appello trovato con i filtri selezionati.',
          )
        else ...[
          ...exams.map((exam) {
            final questionnaireCompleted = ref.watch(
              isQuestionnaireCompletedProvider(exam.courseName),
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ExamBookingCard(
                exam: exam,
                questionnaireCompleted: questionnaireCompleted,
                onInfo: () =>
                    showExamBookingDetailsSheet(context: context, exam: exam),
                onBook: () =>
                    _requestBooking(context, ref, exam, questionnaireCompleted),
              ),
            );
          }),
        ],
        const SizedBox(height: 2),
        const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.info, size: 13, color: AppColors.colorNeutral400),
            SizedBox(width: 7),
            Expanded(
              child: Text(
                'Le prenotazioni sono definitive salvo cancellazione entro la scadenza. Per informazioni contatta la segreteria studenti.',
                style: TextStyle(
                  color: AppColors.colorNeutral400,
                  fontSize: 11,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _requestBooking(
    BuildContext context,
    WidgetRef ref,
    ExamBookingEntity exam,
    bool questionnaireCompleted,
  ) async {
    final toast = ref.read(toastServiceProvider.notifier);
    if (exam.status == ExamBookingStatus.booked) {
      toast.warning("Sei già iscritto all'appello di ${exam.courseName}.");
      return;
    }
    if (exam.status == ExamBookingStatus.closed) {
      toast.error('Le iscrizioni per ${exam.courseName} sono chiuse.');
      return;
    }
    if (!questionnaireCompleted) {
      toast.error(
        'Prenotazione non effettuabile: prima compila il questionario del corso.',
      );
      return;
    }
    final confirmed = await showExamBookingConfirmationSheet(
      context: context,
      exam: exam,
    );
    if (!confirmed || !context.mounted) return;

    toast.warning(
      'Prenotazione reale non ancora disponibile: manca l’endpoint backend.',
    );
  }
}

class _RecommendationsInfoCard extends StatelessWidget {
  const _RecommendationsInfoCard();

  @override
  Widget build(BuildContext context) {
    return const CustomCardWidget(
      variant: CardVariant.neutral,
      padding: CardPadding.sm,
      shadow: CardShadow.none,
      radius: CardRadius.lg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.sparkles,
            size: 20,
            color: AppColors.colorPrimaryDark,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Priorità automatica',
                  style: TextStyle(
                    color: AppColors.colorNeutral900,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Appelli degli esami mancanti ordinati dal minor numero di CFU al maggiore.',
                  style: TextStyle(
                    color: AppColors.colorNeutral500,
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedCourseCard extends StatelessWidget {
  const _RecommendedCourseCard({
    required this.recommendation,
    required this.position,
  });

  final RecommendedExamBooking recommendation;
  final int position;

  @override
  Widget build(BuildContext context) {
    final course = recommendation.course;
    final appeal = recommendation.appeal;
    final status = _recommendedStatus(appeal);

    return CustomCardWidget(
      shadow: CardShadow.sm,
      radius: CardRadius.lg,
      padding: CardPadding.sm,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.colorPrimaryLight.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$position',
              style: const TextStyle(
                color: AppColors.colorPrimaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.colorNeutral900,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  [
                    if (course.code.trim().isNotEmpty) course.code,
                    '${course.credits} CFU',
                    if (appeal != null) _formatShortDate(appeal.date),
                  ].join(' · '),
                  style: const TextStyle(
                    color: AppColors.colorNeutral500,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: status.background,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status.label,
              style: TextStyle(
                color: status.foreground,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  ({String label, Color foreground, Color background}) _recommendedStatus(
    ExamBookingEntity? appeal,
  ) {
    if (appeal == null) {
      return (
        label: 'Nessun appello',
        foreground: AppColors.colorNeutral600,
        background: AppColors.colorNeutral100,
      );
    }
    return switch (appeal.status) {
      ExamBookingStatus.open => (
        label: 'Disponibile',
        foreground: AppColors.colorSuccessDark,
        background: AppColors.colorSuccessLight,
      ),
      ExamBookingStatus.closing => (
        label: 'In scadenza',
        foreground: AppColors.colorWarningDark,
        background: AppColors.colorWarningLight,
      ),
      ExamBookingStatus.booked => (
        label: 'Prenotato',
        foreground: AppColors.colorPrimaryDark,
        background: AppColors.colorPrimaryLight,
      ),
      ExamBookingStatus.closed => (
        label: 'Chiuso',
        foreground: AppColors.colorNeutral600,
        background: AppColors.colorNeutral100,
      ),
    };
  }

  String _formatShortDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
  }
}

class _AppealsAvailabilityWarning extends StatelessWidget {
  const _AppealsAvailabilityWarning();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(LucideIcons.info, size: 14, color: AppColors.colorNeutral500),
        SizedBox(width: 7),
        Expanded(
          child: Text(
            'Gli esami sono ordinati dal piano di studio, ma la disponibilità degli appelli non è aggiornata.',
            style: TextStyle(
              color: AppColors.colorNeutral500,
              fontSize: 10.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyAppeals extends StatelessWidget {
  const _EmptyAppeals({
    this.message = 'Nessun appello trovato con i filtri selezionati.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('appeals-empty-state'),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 38),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.colorNeutral300),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.calendarX,
            size: 30,
            color: AppColors.colorNeutral300,
          ),
          SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.colorNeutral400,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Riprova'),
            ),
          ],
        ],
      ),
    );
  }
}