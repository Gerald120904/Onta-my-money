import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'providers/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('es_CR', null);
    await initializeDateFormatting('es', null);
    Intl.defaultLocale = 'es_CR';
  } catch (e) {
    debugPrint('Error inicializando locale data: $e');
  }
  final state = AppState();
  await state.restoreSession();
  runApp(PlataApp(state: state));
}

class PlataApp extends StatelessWidget {
  final AppState state;
  const PlataApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '¿Dónde se fue mi plata?',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: state.themeMode,
        home: state.isAuthenticated ? HomeShell(state: state) : LoginScreen(state: state),
      ),
    );
  }
}
