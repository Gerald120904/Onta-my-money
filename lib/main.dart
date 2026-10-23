import 'package:flutter/material.dart';
import 'providers/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
