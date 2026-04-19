import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;

import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/download_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/active_downloads_screen.dart';
import 'screens/status_screen.dart';
import 'screens/changelog_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/author_screen.dart';

import 'services/settings_service.dart';
import 'services/widget_service.dart';
import 'services/quick_actions_service.dart';
import 'services/download_progress_service.dart';
import 'services/background_download_handler.dart';
import 'services/extractors/scraper_config.dart';
import 'utils/app_routes.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  assert(
    ScraperConfig.usesOnlySecureEndpoints(),
    'ScraperConfig must define HTTPS endpoints only.',
  );

  // Initialize FlutterDownloader y Ads (Mobile Only)
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await FlutterDownloader.initialize(debug: kDebugMode, ignoreSsl: false);
    await DownloadProgressService.instance.ensureInitialized();
    // Eliminado: inicialización de anuncios
  }

  // Initialize date formatting for Spanish locale
  await initializeDateFormatting('es', null);

  // Initialize widget service (mobile only)
  if (WidgetService.isSupported) {
    await WidgetService.initialize();
  }

  // Allow all orientations to support tablet and desktop landscape layouts
  // SystemChrome.setPreferredOrientations is intentionally removed.

  // Prevent tree-shaking of background entry point
  if (DateTime.now().year < 2000) {
    backgroundMain();
  }

  if (kIsWeb) usePathUrlStrategy();

  // Check onboarding state BEFORE running app
  final bool hasCompletedOnboarding =
      await SettingsService.hasCompletedOnboarding();

  runApp(DownloaderApp(hasCompletedOnboarding: hasCompletedOnboarding));
}

class DownloaderApp extends StatefulWidget {
  final bool hasCompletedOnboarding;

  const DownloaderApp({super.key, required this.hasCompletedOnboarding});

  @override
  State<DownloaderApp> createState() => DownloaderAppState();
}

class DownloaderAppState extends State<DownloaderApp>
    with WidgetsBindingObserver {
  ThemeMode _themeMode = ThemeMode.system;

  final QuickActionsService _quickActions = QuickActionsService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Eliminado: carga de anuncios AppOpenAd
    _loadThemeMode();
    _setupWidgetListener();
    _setupQuickActions();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {}

  void _setupQuickActions() {
    _quickActions.initialize(context, (action) {
      if (action == 'action_history') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const HistoryScreen()),
        );
      } else if (action == 'action_settings') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _quickActions.dispose();
    super.dispose();
  }

  void _setupWidgetListener() {
    WidgetService.onActionReceived = (action, url) {
      if (action.contains('OPEN_HISTORY')) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const HistoryScreen()),
        );
      } else if (action.contains('OPEN_SETTINGS')) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      } else if (action.contains('DOWNLOAD_FROM_WIDGET')) {
        // Redirigir a la pantalla de descarga
        navigatorKey.currentState?.popUntil((route) => route.isFirst);
        Navigator.pushReplacement(
          navigatorKey.currentContext!,
          MaterialPageRoute(
            builder: (_) =>
                url != null && url.isNotEmpty
                ? DownloadScreen(initialUrl: url)
                : const DownloadScreen(),
          ),
        );
      }
    };
  }

  Future<void> _loadThemeMode() async {
    final mode = await SettingsService.getThemeMode();
    setState(() => _themeMode = mode);
  }

  void updateThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Media Keep',
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CC9F0),
          brightness: Brightness.light,
          primary: const Color(0xFF00B4D8),
          secondary: const Color(0xFF48CAE4),
          surface: Colors.white,
          onSurface: const Color(0xFF18181B),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF18181B),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Color(0xFF18181B)),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: const Color(0xFF00B4D8).withValues(alpha: 0.1),
            ),
          ),
          color: const Color(0xFFFAFAFA),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: const Color(0xFF00B4D8),
            foregroundColor: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: const Color(0xFF18181B).withValues(alpha: 0.05),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF00B4D8), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4CC9F0),
          brightness: Brightness.dark,
          surface: const Color(0xFF18181B),
          onSurface: const Color(0xFFE4E4E7),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF18181B),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
          color: const Color(0xFF27272A),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: const Color(0xFF4CC9F0),
            foregroundColor: const Color(0xFF18181B),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF27272A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF4CC9F0), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
      themeMode: _themeMode,
      navigatorKey: navigatorKey,
      builder: (context, child) => child!,
      onGenerateRoute: (settings) {
        Widget page;
        switch (settings.name) {
          case '/':
            // Ensure the root route returns the correct home screen
            page = widget.hasCompletedOnboarding
                ? const DownloadScreen()
                : const OnboardingScreen();
            break;
          case AppRoutes.download:
            page = const DownloadScreen();
            break;
          case AppRoutes.history:
            page = const HistoryScreen();
            break;
          case AppRoutes.activeDownloads:
            page = const ActiveDownloadsScreen();
            break;
          case AppRoutes.settings:
            page = const SettingsScreen();
            break;
          case AppRoutes.status:
            page = const StatusScreen();
            break;
          case AppRoutes.changelog:
            page = const ChangelogScreen();
            break;
          case AppRoutes.privacy:
            page = const PrivacyScreen();
            break;
          case AppRoutes.author:
            page = const AuthorScreen();
            break;
          // Eliminadas rutas checkout y auth
          default:
            return null;
        }
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: child,
              ),
          transitionDuration: const Duration(milliseconds: 200),
          reverseTransitionDuration: const Duration(milliseconds: 150),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// ==========================================
// BACKGROUND ENTRY POINT
// ==========================================

// Entry point for the background process
@pragma('vm:entry-point')
void backgroundMain() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    try {
      await FlutterDownloader.initialize(debug: kDebugMode, ignoreSsl: false);
    } catch (e) {
      debugPrint('[Background] FlutterDownloader init error: $e');
    }
  }

  // Initialize the method channel for background communication
  const MethodChannel channel = MethodChannel('com.mediakeep.aur/background');

  // Set up the method call handler
  channel.setMethodCallHandler((MethodCall call) async {
    if (call.method == 'startDownload') {
      final args = call.arguments;
      if (args is! Map) {
        await channel.invokeMethod('downloadError', {
          'message':
              'Solicitud rechazada: accion en segundo plano no autorizada.',
        });
        return;
      }

      final dynamic urlValue = args['url'];
      final dynamic triggerValue = args['trigger'];
      if (urlValue is! String ||
          urlValue.trim().isEmpty ||
          triggerValue != 'share_confirmation') {
        await channel.invokeMethod('downloadError', {
          'message':
              'Solicitud rechazada: se requiere confirmacion explicita del usuario.',
        });
        return;
      }

      await _handleBackgroundDownload(urlValue.trim(), channel);
    }
  });
}

Future<void> _handleBackgroundDownload(
  String url,
  MethodChannel channel,
) async {
  await BackgroundDownloadHandler.handleBackgroundDownload(url, channel);
}
