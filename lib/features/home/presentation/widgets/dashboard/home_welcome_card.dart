import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../config/constants/app_day_greeting.dart';
import '../../../../../config/theme/app_colors.dart';
import '../../../../profile/presentation/providers/student_badge_providers.dart';

class HomeWelcomeCard extends ConsumerWidget {
  const HomeWelcomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final greeting = AppDayGreeting.resolve();
    final badge = ref.watch(studentBadgeProvider).value;
    final firstName = badge?.firstName.trim();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          key: const Key('home-online-indicator'),
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: AppColors.colorSuccessDark,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Text.rich(
            key: const Key('home-greeting'),
            TextSpan(
              children: [
                TextSpan(text: '$greeting, '),
                TextSpan(
                  text: firstName == null || firstName.isEmpty
                      ? 'Alessio'
                      : firstName,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 6),
        const _AnimatedHandMetalIcon(),
      ],
    );
  }
}

class _AnimatedHandMetalIcon extends StatefulWidget {
  const _AnimatedHandMetalIcon();

  @override
  State<_AnimatedHandMetalIcon> createState() => _AnimatedHandMetalIconState();
}

class _AnimatedHandMetalIconState extends State<_AnimatedHandMetalIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rotation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -15, end: 15), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 15, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() => _controller.forward(from: 0);

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _startAnimation(),
      child: GestureDetector(
        key: const Key('home-greeting-hand'),
        behavior: HitTestBehavior.opaque,
        onTap: _startAnimation,
        child: AnimatedBuilder(
          animation: _rotation,
          child: const Icon(
            LucideIcons.handMetal,
            color: AppColors.textPrimary,
            size: 28,
          ),
          builder: (context, child) => Transform.rotate(
            angle: _rotation.value * 3.141592653589793 / 180,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        ),
      ),
    );
  }
}
