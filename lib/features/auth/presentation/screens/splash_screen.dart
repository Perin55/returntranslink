import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/helpers/onboarding_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () async {
      if (!mounted) return;
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final route = await OnboardingHelper.getOnboardingRoute();
          if (mounted) context.go(route);
        } else {
          if (mounted) context.go('/login');
        }
      } catch (e) {
        debugPrint('Splash navigation error: $e');
        if (mounted) context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Image.asset(
            'assets/images/logo.png',
            width: 220,
            fit: BoxFit.contain,
          ).animate()
           .fadeIn(duration: 600.ms, curve: Curves.easeOut)
           .scale(begin: const Offset(0.95, 0.95), end: const Offset(1.0, 1.0), duration: 600.ms, curve: Curves.easeOutCubic),
        ),
      ),
    );
  }
}


