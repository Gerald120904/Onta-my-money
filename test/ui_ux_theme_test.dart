import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:donde_se_fue_mi_plata/core/theme/app_theme.dart';
import 'package:donde_se_fue_mi_plata/data/local/app_database.dart';
import 'package:donde_se_fue_mi_plata/data/repositories/finance_repository.dart';
import 'package:donde_se_fue_mi_plata/models/models.dart';
import 'package:donde_se_fue_mi_plata/providers/app_state.dart';
import 'package:donde_se_fue_mi_plata/screens/commitments_screen.dart';
import 'package:donde_se_fue_mi_plata/screens/dashboard_screen.dart';
import 'package:donde_se_fue_mi_plata/screens/goals_screen.dart';
import 'package:donde_se_fue_mi_plata/screens/home_shell.dart';
import 'package:donde_se_fue_mi_plata/screens/login_screen.dart';
import 'package:donde_se_fue_mi_plata/screens/more_screen.dart';
import 'package:donde_se_fue_mi_plata/screens/notifications_screen.dart';
import 'package:donde_se_fue_mi_plata/screens/profile_screen.dart';
import 'package:donde_se_fue_mi_plata/screens/reports_screen.dart';
import 'package:donde_se_fue_mi_plata/screens/review_screen.dart';
import 'package:donde_se_fue_mi_plata/screens/settings_screen.dart';
import 'package:donde_se_fue_mi_plata/screens/sync_screen.dart';
import 'package:donde_se_fue_mi_plata/screens/transactions_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FinanceRepository financeRepo;
  late AppState appState;

  const testUserId = 'user_theme_test_123';
  const testUserEmail = 'usuario.theme@ejemplo.com';
  const testUserName = 'Usuario Theme';

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'token_theme_123',
      'user_id': testUserId,
      'user_email': testUserEmail,
      'current_user_name': testUserName,
      'user_opening_balance': 250000.0,
      'auto_sync_enabled': false,
    });

    db = AppDatabase.inMemory(NativeDatabase.memory());
    financeRepo = FinanceRepository(db);

    await financeRepo.saveUser(
      id: testUserId,
      name: testUserName,
      email: testUserEmail,
      token: 'token_theme_123',
      openingBalance: 250000.0,
      isCurrent: true,
    );

    await financeRepo.saveAccount(
      userId: testUserId,
      account: Account(
        id: 'acc_theme_main',
        userId: testUserId,
        name: 'Cuenta Principal',
        currency: 'CRC',
        initialBalance: 250000.0,
        isDefault: true,
      ),
      isNew: true,
    );

    // Movimientos de prueba
    await financeRepo.saveTransaction(
      userId: testUserId,
      transaction: MoneyTransaction(
        id: 'tx_1',
        type: 'income',
        amount: 80000.0,
        category: 'Salario',
        description: 'Pago quincenal',
        date: DateTime.now(),
        recognized: true,
        accountId: 'acc_theme_main',
      ),
      isNew: true,
    );

    await financeRepo.saveTransaction(
      userId: testUserId,
      transaction: MoneyTransaction(
        id: 'tx_2',
        type: 'expense',
        amount: 25000.0,
        category: 'Supermercado',
        description: 'Compras semanales',
        date: DateTime.now(),
        recognized: true,
        accountId: 'acc_theme_main',
      ),
      isNew: true,
    );

    // Compromiso de prueba
    await financeRepo.saveCommitment(
      userId: testUserId,
      commitment: Commitment(
        id: 'com_1',
        title: 'Alquiler',
        amount: 50000.0,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        status: 'pending',
        accountId: 'acc_theme_main',
      ),
      isNew: true,
    );

    // Meta de ahorro de prueba
    await financeRepo.saveGoal(
      userId: testUserId,
      goal: SavingsGoal(
        id: 'goal_1',
        title: 'Fondo de Emergencia',
        targetAmount: 200000.0,
        savedAmount: 30000.0,
        accountId: 'acc_theme_main',
      ),
      isNew: true,
    );

    appState = AppState(customDb: db);
    appState.currentUserId = testUserId;
    appState.currentUserEmail = testUserEmail;
    appState.currentUserName = testUserName;
    appState.api.token = 'token_theme_123';
    appState.autoSyncEnabled = false;

    await appState.restoreSession();
    await appState.refreshAll();
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildThemedApp({
    required Widget child,
    required ThemeData theme,
    Size size = const Size(412, 915),
  }) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        theme: theme,
        home: Material(child: child),
      ),
    );
  }

  group('AUDITORÍA GLOBAL UI/UX - MODO CLARO Y OSCURO', () {
    testWidgets(
        '1. DashboardScreen renderiza sin overflow en modo Claro y Oscuro',
        (tester) async {
      for (final isDark in [false, true]) {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          buildThemedApp(
            child: DashboardScreen(
              state: appState,
              onReview: () {},
            ),
            theme: isDark ? AppTheme.dark : AppTheme.light,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('¿Dónde se fue\nmi plata?'), findsOneWidget);
        expect(find.text('Resumen del mes'), findsOneWidget);
      }
    });

    testWidgets(
        '2. TransactionsScreen renderiza sin overflow en modo Claro y Oscuro',
        (tester) async {
      for (final isDark in [false, true]) {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          buildThemedApp(
            child: TransactionsScreen(state: appState),
            theme: isDark ? AppTheme.dark : AppTheme.light,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Movimientos'), findsAtLeastNWidgets(1));
        expect(find.text('Salario'), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('3. ReviewScreen renderiza sin overflow en modo Claro y Oscuro',
        (tester) async {
      for (final isDark in [false, true]) {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          buildThemedApp(
            child: ReviewScreen(
              state: appState,
              onCompleted: (_) {},
              onExit: () {},
            ),
            theme: isDark ? AppTheme.dark : AppTheme.light,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Elegir periodo'), findsOneWidget);
      }
    });

    testWidgets(
        '4. ReportsScreen renderiza sin overflow en modo Claro y Oscuro',
        (tester) async {
      for (final isDark in [false, true]) {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          buildThemedApp(
            child: ReportsScreen(
              state: appState,
              onCreateReview: () {},
            ),
            theme: isDark ? AppTheme.dark : AppTheme.light,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Reportes'), findsOneWidget);
      }
    });

    testWidgets('5. SyncScreen renderiza sin overflow en modo Claro y Oscuro',
        (tester) async {
      for (final isDark in [false, true]) {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          buildThemedApp(
            child: SyncScreen(state: appState),
            theme: isDark ? AppTheme.dark : AppTheme.light,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Estado de Sincronización'), findsOneWidget);
      }
    });

    testWidgets(
        '6. CommitmentsScreen y GoalsScreen renderizan en modo Claro y Oscuro',
        (tester) async {
      for (final isDark in [false, true]) {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;

        // Commitments
        await tester.pumpWidget(
          buildThemedApp(
            child: CommitmentsScreen(state: appState),
            theme: isDark ? AppTheme.dark : AppTheme.light,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Alquiler'), findsOneWidget);

        // Goals
        await tester.pumpWidget(
          buildThemedApp(
            child: GoalsScreen(state: appState),
            theme: isDark ? AppTheme.dark : AppTheme.light,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Fondo de Emergencia'), findsOneWidget);
      }
    });

    testWidgets(
        '7. MoreScreen, SettingsScreen, ProfileScreen renderizan en modo Claro y Oscuro',
        (tester) async {
      for (final isDark in [false, true]) {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;

        // MoreScreen
        await tester.pumpWidget(
          buildThemedApp(
            child: MoreScreen(state: appState),
            theme: isDark ? AppTheme.dark : AppTheme.light,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Dinero comprometido'), findsOneWidget);

        // SettingsScreen
        await tester.pumpWidget(
          buildThemedApp(
            child: SettingsScreen(state: appState),
            theme: isDark ? AppTheme.dark : AppTheme.light,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Configuración'), findsOneWidget);

        // ProfileScreen
        await tester.pumpWidget(
          buildThemedApp(
            child: ProfileScreen(state: appState),
            theme: isDark ? AppTheme.dark : AppTheme.light,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Mi perfil'), findsOneWidget);
      }
    });

    testWidgets(
        '8. NotificationsScreen y LoginScreen renderizan en modo Claro y Oscuro',
        (tester) async {
      for (final isDark in [false, true]) {
        tester.view.physicalSize = const Size(412, 915);
        tester.view.devicePixelRatio = 1.0;

        // NotificationsScreen
        await tester.pumpWidget(
          buildThemedApp(
            child: NotificationsScreen(state: appState),
            theme: isDark ? AppTheme.dark : AppTheme.light,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Notificaciones'), findsOneWidget);

        // LoginScreen
        await tester.pumpWidget(
          buildThemedApp(
            child: LoginScreen(state: appState),
            theme: isDark ? AppTheme.dark : AppTheme.light,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('¿Dónde se fue mi plata?'), findsOneWidget);
      }
    });

    testWidgets(
        '9. HomeShell responsive en Desktop (1440x900) y Móvil (360x800)',
        (tester) async {
      // Desktop
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        buildThemedApp(
          child: HomeShell(state: appState),
          theme: AppTheme.dark,
          size: const Size(1440, 900),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Mobile
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        buildThemedApp(
          child: HomeShell(state: appState),
          theme: AppTheme.light,
          size: const Size(360, 800),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
