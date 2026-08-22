import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/localization/app_localizations.dart';
import 'core/services/background_order_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/supabase_service.dart';
import 'core/state/admin_provider.dart';
import 'core/state/auth_provider.dart';
import 'core/state/booking_provider.dart';
import 'core/state/font_provider.dart';
import 'core/state/locale_provider.dart';
import 'core/state/theme_provider.dart';
import 'core/theme/aurora_theme.dart';
import 'views/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase backend, Notification service & Background driver service
  await SupabaseService.initialize();
  await NotificationService.initialize();
  await BackgroundOrderService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FontProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
      ],
      child: const MaysanCaptainApp(),
    ),
  );
}

class MaysanCaptainApp extends StatelessWidget {
  const MaysanCaptainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final fontProvider = context.watch<FontProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    return MaterialApp(
      title: 'كابتن ميسان | Maysan Captain',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,
      theme: AuroraTheme.getLightTheme(fontProvider.currentFont),
      darkTheme: AuroraTheme.getDarkTheme(fontProvider.currentFont),
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('ar', 'IQ'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}
