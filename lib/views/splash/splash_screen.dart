import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/state/auth_provider.dart';
import '../../core/theme/aurora_theme.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';
import '../widgets/aurora_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final auth = context.read<AuthProvider>();
    await Future.wait([
      Future.delayed(const Duration(milliseconds: 2000)),
      auth.initSession(),
    ]);

    if (!mounted) return;

    if (auth.isAuthenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: AuroraBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Glowing App Icon
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AuroraTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AuroraTheme.primaryCyan.withValues(alpha: 0.5),
                      blurRadius: 36,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(4),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icon/app.png',
                    fit: BoxFit.cover,
                  ),
                ),
              )
                  .animate()
                  .scale(duration: 800.ms, curve: Curves.easeOutBack)
                  .shimmer(duration: 1600.ms, delay: 600.ms),

              const SizedBox(height: 28),

              // Title
              Text(
                loc.translate('appName'),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                loc.translate('appSlogan'),
                style: const TextStyle(
                  fontSize: 16,
                  color: AuroraTheme.primaryCyan,
                  fontWeight: FontWeight.w600,
                ),
              )
                  .animate()
                  .fadeIn(delay: 600.ms, duration: 600.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 6),

              // Maysan Specialization badge
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0x330EA5E9)
                      : const Color(0x220284C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0x660EA5E9)
                        : const Color(0xFF0284C7),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  loc.translate('maysanSpecialized'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : const Color(0xFF0369A1), // High contrast deep blue in light mode
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms, duration: 600.ms),

              const SizedBox(height: 60),

              // Loading Spinner
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AuroraTheme.primaryCyan),
                ),
              ).animate().fadeIn(delay: 1000.ms),
            ],
          ),
        ),
      ),
    );
  }
}
