import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../config/routes/app_routes.dart';
import '../../../../shared/widgets/custom_button/custom_button_widget.dart';
import '../../../../shared/widgets/custom_card/custom_card_widget.dart';
import '../../../../shared/widgets/custom_input/custom_input_widget.dart';
import '../../../../shared/widgets/custom_tab/custom_tab_widget.dart';
import '../../../../shared/widgets/custom_text/custom_text_widget.dart';
import '../../../../shared/widgets/custom_toast/custom_toast_service.dart';
import '../../data/constants/login_universities.dart';
import '../../domain/entities/login_university.dart';
import '../../domain/exceptions/auth_exception.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../../academics/presentation/providers/career_data_providers.dart';
import '../providers/auth_provider.dart';
import 'university_search_select.dart';

enum UniversityLoginMode { ateneo, spid, cie }

class UniversityLoginForm extends ConsumerStatefulWidget {
  const UniversityLoginForm({super.key});

  @override
  ConsumerState<UniversityLoginForm> createState() =>
      _UniversityLoginFormState();
}

class _UniversityLoginFormState extends ConsumerState<UniversityLoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  UniversityLoginMode _mode = UniversityLoginMode.ateneo;
  LoginUniversity? _selectedUniversity;
  bool _isLoading = false;

  bool get _domainUnavailable =>
      _selectedUniversity != null && _selectedUniversity!.emailDomains.isEmpty;

  String get _emailError {
    final university = _selectedUniversity;
    final email = _emailController.text.trim();

    if (university == null || email.isEmpty || _domainUnavailable) return '';
    if (!email.contains('@')) return 'Inserisci un indirizzo email valido';
    if (university.acceptsEmail(email)) return '';

    return 'L\'email deve appartenere a uno dei domini di '
        '${university.shortName} '
        '(es. nome@${university.emailDomains.first})';
  }

  bool get _canSubmit =>
      _selectedUniversity != null &&
      !_domainUnavailable &&
      _emailController.text.trim().isNotEmpty &&
      _emailError.isEmpty &&
      _passwordController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setMode(String id) {
    final mode = UniversityLoginMode.values.firstWhere(
      (value) => value.name == id,
    );
    if (mode == _mode) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _mode = mode);
  }

  void _selectUniversity(LoginUniversity selected) {
    _emailController.clear();
    setState(() => _selectedUniversity = selected);
  }

  Future<void> _submit() async {
    if (!_canSubmit || _isLoading) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _isLoading = true);

    final password = _passwordController.text;
    try {
      await ref
          .read(loginUseCaseProvider)
          .call(
            LoginParams(
              universityId: _selectedUniversity!.id.toUpperCase(),
              username: _selectedUniversity!.authenticationUsername(
                _emailController.text,
              ),
              password: password,
            ),
          );

      ref.invalidate(authSessionProvider);

      try {
        await ref.read(getExamBookingHistoryUseCaseProvider).call(password);
      } catch (_) {
      } finally {
        _passwordController.clear();
      }

      if (!mounted) return;
      ref.read(isAuthenticatedProvider.notifier).setAuthenticated(true);
      context.goNamed(AppRoutes.homeName);
    } on AuthException catch (error) {
      if (!mounted) return;
      ref.read(toastServiceProvider.notifier).error(error.message);
    } catch (_) {
      if (!mounted) return;
      ref
          .read(toastServiceProvider.notifier)
          .error('Accesso non riuscito. Riprova.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _notifyUnavailable(String provider) {
    ref
        .read(toastServiceProvider.notifier)
        .warning('L\'accesso con $provider non è ancora attivo.');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTabWidget(
          key: const Key('university-auth-tabs'),
          tabs: const [
            TabItem(id: 'ateneo', label: 'Ateneo'),
            TabItem(id: 'spid', label: 'SPID'),
            TabItem(id: 'cie', label: 'CIE'),
          ],
          activeTab: _mode.name,
          tabStyle: TabStyle.underline,
          variant: TabVariant.primary,
          fullWidth: true,
          onTabChange: _setMode,
        ),
        const SizedBox(height: 24),
        switch (_mode) {
          UniversityLoginMode.ateneo => _buildUniversityForm(),
          UniversityLoginMode.spid => _IdentityProviderPanel(
            key: const ValueKey('spid-panel'),
            provider: 'SPID',
            icon: LucideIcons.shieldCheck,
            description:
                'SPID è il sistema di accesso che consente di utilizzare, '
                'con un\'identità digitale unica, i servizi online della '
                'Pubblica Amministrazione e dei privati accreditati. Se sei '
                'già in possesso di un\'identità digitale, accedi con le '
                'credenziali del tuo gestore.',
            onPressed: () => _notifyUnavailable('SPID'),
          ),
          UniversityLoginMode.cie => _IdentityProviderPanel(
            key: const ValueKey('cie-panel'),
            provider: 'CIE',
            icon: LucideIcons.creditCard,
            description:
                'CIE è lo schema di identificazione che consente l\'accesso '
                'ai servizi digitali erogati in rete da pubbliche '
                'amministrazioni e privati, mediante l\'impiego della Carta '
                'd\'Identità Elettronica.',
            onPressed: () => _notifyUnavailable('CIE'),
          ),
        },
      ],
    );
  }

  Widget _buildUniversityForm() {
    return Column(
      key: const ValueKey('ateneo-panel'),
      children: [
        UniversitySearchSelect(
          key: const Key('university-search'),
          universities: loginUniversities,
          selected: _selectedUniversity,
          onSelected: _selectUniversity,
        ),
        if (_domainUnavailable) ...[
          const SizedBox(height: 8),
          const CustomTextWidget(
            key: Key('university-domain-unavailable'),
            text:
                'La verifica email per questo ateneo non è ancora disponibile. '
                'Contatta il supporto per assistenza.',
            variant: TextVariant.bodySm,
            color: TextColor.warning,
          ),
        ],
        const SizedBox(height: 16),
        CustomInputWidget(
          key: const Key('university-email'),
          controller: _emailController,
          type: InputType.email,
          label: 'Email istituzionale',
          placeholder: 'nome.cognome@studenti.ateneo.it',
          disabled:
              _selectedUniversity == null ||
              _domainUnavailable,
          errorMessage: _emailError,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        CustomInputWidget(
          key: const Key('university-password'),
          controller: _passwordController,
          type: InputType.password,
          label: 'Password',
          placeholder: '••••••••',
          disabled:
              _selectedUniversity == null ||
              _domainUnavailable,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: 16),
        CustomButtonWidget(
          key: const Key('university-submit'),
          label: 'Accedi',
          variant: ButtonVariant.primary,
          size: ButtonSize.md,
          fullWidth: true,
          disabled: !_canSubmit,
          loading: _isLoading,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _IdentityProviderPanel extends StatelessWidget {
  const _IdentityProviderPanel({
    super.key,
    required this.provider,
    required this.icon,
    required this.description,
    required this.onPressed,
  });

  final String provider;
  final IconData icon;
  final String description;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return CustomCardWidget(
      variant: CardVariant.neutral,
      padding: CardPadding.md,
      shadow: CardShadow.none,
      radius: CardRadius.lg,
      darkTheme: false,
      child: Column(
        children: [
          CustomTextWidget(
            text: description,
            variant: TextVariant.bodySm,
            color: TextColor.muted,
          ),
          const SizedBox(height: 16),
          CustomButtonWidget(
            key: Key('${provider.toLowerCase()}-submit'),
            label: 'Entra con $provider',
            icon: icon,
            variant: ButtonVariant.primary,
            size: ButtonSize.md,
            fullWidth: true,
            onPressed: onPressed,
          ),
        ],
      ),
    );
  }
}