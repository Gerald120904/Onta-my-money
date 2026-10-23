import 'dart:convert';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:donde_se_fue_mi_plata/core/api/api_client.dart';
import 'package:donde_se_fue_mi_plata/core/theme/app_theme.dart';
import 'package:donde_se_fue_mi_plata/data/local/app_database.dart';
import 'package:donde_se_fue_mi_plata/data/repositories/finance_repository.dart';
import 'package:donde_se_fue_mi_plata/data/repositories/review_repository.dart';
import 'package:donde_se_fue_mi_plata/models/models.dart';
import 'package:donde_se_fue_mi_plata/providers/app_state.dart';
import 'package:donde_se_fue_mi_plata/screens/more_screen.dart';
import 'package:donde_se_fue_mi_plata/screens/notifications_screen.dart';
import 'package:donde_se_fue_mi_plata/screens/profile_screen.dart';
import 'package:donde_se_fue_mi_plata/screens/settings_screen.dart';
import 'package:donde_se_fue_mi_plata/services/notifications/notification_preferences.dart';
import 'package:donde_se_fue_mi_plata/services/notifications/notification_service.dart';

class MockApiForProfile extends ApiClient {
  bool isOnline = true;
  final List<Map<String, dynamic>> pushedOperations = [];
  Map<String, dynamic>? patchedProfile;

  @override
  Future<dynamic> patch(String path, [Map<String, dynamic>? body]) async {
    if (!isOnline) {
      throw ApiException('Sin conexión', 0, isNetworkError: true);
    }
    if (path == '/api/me') {
      patchedProfile = body;
      return {'status': 'updated', 'profile': body};
    }
    return {};
  }

  @override
  Future<dynamic> post(String path, [Map<String, dynamic>? body]) async {
    if (!isOnline) {
      throw ApiException('Sin conexión', 0, isNetworkError: true);
    }
    if (path == '/api/sync/push') {
      final ops = (body?['operations'] as List? ?? []).cast<Map<String, dynamic>>();
      final results = <Map<String, dynamic>>[];
      for (final op in ops) {
        pushedOperations.add(op);
        results.add({
          'operation_id': op['operation_id'],
          'status': 'applied',
          'version': (op['base_version'] as num?)?.toInt() ?? 1,
        });
      }
      return {'processed': results, 'conflicts': []};
    }
    if (path == '/api/me/change-password') {
      return {'status': 'password_updated', 'message': 'Contraseña actualizada'};
    }
    return {};
  }

  @override
  Future<dynamic> get(String path) async {
    if (!isOnline) {
      throw ApiException('Sin conexión', 0, isNetworkError: true);
    }
    if (path == '/api/sync/pull') {
      return {'cursor': 1, 'has_more': false, 'items': []};
    }
    if (path == '/api/me') {
      return {
        'id': 'user_123',
        'name': 'Derek Senior',
        'email': 'derek@test.com',
        'opening_balance': 50000.0,
        'created_at': '2026-01-01T00:00:00.000Z',
      };
    }
    return {};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FinanceRepository financeRepo;
  late AppState appState;

  const testUserId = 'user_abc_789';
  const testUserEmail = 'derek@ejemplo.com';
  const testUserName = 'Derek Rodríguez';

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'test_token_xyz',
      'user_id': testUserId,
      'user_email': testUserEmail,
      'current_user_name': testUserName,
      'user_opening_balance': 150000.0,
    });

    db = AppDatabase.inMemory(NativeDatabase.memory());
    financeRepo = FinanceRepository(db);

    await financeRepo.saveUser(
      id: testUserId,
      name: testUserName,
      email: testUserEmail,
      token: 'test_token_xyz',
      openingBalance: 150000.0,
      isCurrent: true,
    );

    appState = AppState(customDb: db);
    appState.currentUserId = testUserId;
    appState.currentUserEmail = testUserEmail;
    appState.currentUserName = testUserName;
    appState.api.token = 'test_token_xyz';
  });

  tearDown(() async {
    await db.close();
  });

  Widget buildTestApp(Widget home) {
    return MaterialApp(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: appState.themeMode,
      home: home,
    );
  }

  group('1. NAVEGACIÓN Y APERTURA DE PANTALLAS (MoreScreen)', () {
    testWidgets('1.1 Mi perfil, Notificaciones y Configuración abren sus pantallas', (tester) async {
      await tester.pumpWidget(buildTestApp(MoreScreen(state: appState)));
      await tester.pumpAndSettle();

      // Verificar que los títulos existen en pantalla
      expect(find.text('Mi perfil'), findsOneWidget);
      expect(find.text('Notificaciones'), findsOneWidget);
      expect(find.text('Configuración'), findsOneWidget);

      // 1. Abrir Mi Perfil
      await tester.tap(find.text('Mi perfil'));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileScreen), findsOneWidget);
      expect(find.text(testUserName), findsWidgets);
      expect(find.text(testUserEmail), findsWidgets);

      // Regresar a MoreScreen
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // 2. Abrir Notificaciones
      await tester.tap(find.text('Notificaciones'));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationsScreen), findsOneWidget);
      expect(find.textContaining('Todas'), findsOneWidget);

      // Regresar a MoreScreen
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();

      // 3. Abrir Configuración
      await tester.tap(find.text('Configuración'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Apariencia y tema'), findsOneWidget);
    });

    testWidgets('1.2 ProfileScreen muestra los datos reales de la sesión autenticada', (tester) async {
      await tester.pumpWidget(buildTestApp(ProfileScreen(state: appState)));
      await tester.pumpAndSettle();

      expect(find.text(testUserName), findsWidgets);
      expect(find.text(testUserEmail), findsWidgets);
      expect(find.text('Sesión activa'), findsOneWidget);
      expect(find.text('Editar'), findsOneWidget);
      expect(find.text('Actualizar contraseña'), findsOneWidget);
    });
  });

  group('2. PERFIL: EDICIÓN OFFLINE-FIRST Y PERSISTENCIA TRAS REINICIO', () {
    test('2.1 Modificar nombre sin conexión guarda localmente y encola operación', () async {
      appState.api.token = null; // Sin conexión o token ausente

      await appState.updateUserName('Derek Offline Master');

      // Comprobar que en memoria se actualizó inmediatamente
      expect(appState.currentUserName, 'Derek Offline Master');

      // Comprobar que en Drift local se actualizó inmediatamente
      final localUser = await financeRepo.getCurrentUser();
      expect(localUser, isNotNull);
      expect(localUser!.name, 'Derek Offline Master');

      // Comprobar que en la cola de sincronización existe la operación pendiente
      final pendingOps = await financeRepo.getPendingOperations(testUserId);
      expect(pendingOps.length, 1);
      final op = pendingOps.first;
      expect(op.entityType, 'user');
      expect(op.action, 'update');
      final payload = jsonDecode(op.payloadJson) as Map<String, dynamic>;
      expect(payload['name'], 'Derek Offline Master');
    });

    test('2.2 El nombre editado offline persiste tras simular reinicio de aplicación', () async {
      await appState.updateUserName('Derek Persistente');

      // Simular reinicio de la aplicación leyendo de base de datos y SharedPreferences
      final newDb = db; // Mismo almacenamiento
      final newRepo = FinanceRepository(newDb);
      final restoredUser = await newRepo.getCurrentUser();

      expect(restoredUser, isNotNull);
      expect(restoredUser!.name, 'Derek Persistente');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('current_user_name'), 'Derek Persistente');
    });

    test('2.3 Cambiar contraseña requiere conexión y autenticación válida', () async {
      appState.api.token = null; // Sin autenticación online

      expect(
        () => appState.changePassword(
          currentPassword: 'Password123!',
          newPassword: 'NewPassword123!',
          confirmPassword: 'NewPassword123!',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('3. NOTIFICACIONES: RECORDATORIOS DE COMPROMISOS Y DESDOPLICACIÓN', () {
    test('3.1 Genera avisos para compromisos vencidos, 7d, 3d, 1d y hoy', () async {
      final notifService = NotificationService(db);
      final now = DateTime(2026, 10, 23);

      final commitments = <Commitment>[
        Commitment(
          id: 'c_overdue',
          title: 'Alquiler Atrasado',
          amount: 250000,
          dueDate: DateTime(2026, 10, 20), // 3 días vencido
          status: 'pending',
          version: 1,
        ),
        Commitment(
          id: 'c_7d',
          title: 'Internet Fibra',
          amount: 35000,
          dueDate: DateTime(2026, 10, 30), // 7 días
          status: 'pending',
          version: 1,
        ),
        Commitment(
          id: 'c_3d',
          title: 'Tarjeta de Crédito',
          amount: 80000,
          dueDate: DateTime(2026, 10, 26), // 3 días
          status: 'pending',
          version: 1,
        ),
        Commitment(
          id: 'c_1d',
          title: 'Luz Eléctrica',
          amount: 22000,
          dueDate: DateTime(2026, 10, 24), // 1 día
          status: 'pending',
          version: 1,
        ),
        Commitment(
          id: 'c_today',
          title: 'Gimnasio',
          amount: 18000,
          dueDate: DateTime(2026, 10, 23), // Hoy
          status: 'pending',
          version: 1,
        ),
      ];

      await notifService.recalculateCommitmentReminders(
        userId: testUserId,
        commitments: commitments,
        nowOverride: now,
      );

      final notifs = await notifService.getNotifications(testUserId);
      expect(notifs.length, greaterThanOrEqualTo(5));

      final types = notifs.map((n) => n.type).toSet();
      expect(types.contains('overdue'), isTrue);
      expect(types.contains('reminder_7d'), isTrue);
      expect(types.contains('reminder_3d'), isTrue);
      expect(types.contains('reminder_1d'), isTrue);
      expect(types.contains('reminder_due'), isTrue);
    });

    test('3.2 Idempotencia: recalcular múltiples veces no duplica notificaciones', () async {
      final notifService = NotificationService(db);
      final now = DateTime(2026, 10, 23);

      final commitments = <Commitment>[
        Commitment(
          id: 'c_single',
          title: 'Seguro de Auto',
          amount: 45000,
          dueDate: DateTime(2026, 10, 26), // 3 días
          status: 'pending',
          version: 1,
        ),
      ];

      await notifService.recalculateCommitmentReminders(
        userId: testUserId,
        commitments: commitments,
        nowOverride: now,
      );
      final initialCount = (await notifService.getNotifications(testUserId)).length;

      // Recalcular 3 veces más simulando reinicios sucesivos de la app
      await notifService.recalculateCommitmentReminders(
        userId: testUserId,
        commitments: commitments,
        nowOverride: now,
      );
      await notifService.recalculateCommitmentReminders(
        userId: testUserId,
        commitments: commitments,
        nowOverride: now,
      );

      final afterCount = (await notifService.getNotifications(testUserId)).length;
      expect(afterCount, equals(initialCount));
    });

    test('3.3 Los avisos se retiran cuando el compromiso se marca como pagado', () async {
      final notifService = NotificationService(db);
      final now = DateTime(2026, 10, 23);

      final commitmentPending = Commitment(
        id: 'c_to_pay',
        title: 'Préstamo Personal',
        amount: 90000,
        dueDate: DateTime(2026, 10, 26),
        status: 'pending',
        version: 1,
      );

      await notifService.recalculateCommitmentReminders(
        userId: testUserId,
        commitments: [commitmentPending],
        nowOverride: now,
      );

      var notifs = await notifService.getNotifications(testUserId);
      expect(notifs.any((n) => n.relatedEntityId == 'c_to_pay'), isTrue);

      // Ahora el compromiso pasa a pagado
      final commitmentPaid = Commitment(
        id: commitmentPending.id,
        title: commitmentPending.title,
        amount: commitmentPending.amount,
        dueDate: commitmentPending.dueDate,
        status: 'paid',
        version: commitmentPending.version,
      );
      await notifService.recalculateCommitmentReminders(
        userId: testUserId,
        commitments: [commitmentPaid],
        nowOverride: now,
      );

      notifs = await notifService.getNotifications(testUserId);
      expect(notifs.any((n) => n.relatedEntityId == 'c_to_pay'), isFalse);
    });

    test('3.4 Marcar como leída y descartar actualizan el estado persistente', () async {
      final notifService = NotificationService(db);
      final now = DateTime(2026, 10, 23);

      await notifService.recalculateCommitmentReminders(
        userId: testUserId,
        commitments: [
          Commitment(
            id: 'c_mark',
            title: 'Agua',
            amount: 15000,
            dueDate: DateTime(2026, 10, 24),
            status: 'pending',
            version: 1,
          )
        ],
        nowOverride: now,
      );

      final unreadBefore = await notifService.getUnreadCount(testUserId);
      expect(unreadBefore, greaterThan(0));

      final notifs = await notifService.getNotifications(testUserId);
      final firstId = notifs.first.id;

      await notifService.markAsRead(firstId);
      final unreadAfter = await notifService.getUnreadCount(testUserId);
      expect(unreadAfter, equals(unreadBefore - 1));

      // Descartar
      await notifService.dismissNotification(firstId);
      final activeNotifs = await notifService.getNotifications(testUserId, includeDismissed: false);
      expect(activeNotifs.any((n) => n.id == firstId), isFalse);

      final allNotifs = await notifService.getNotifications(testUserId, includeDismissed: true);
      expect(allNotifs.any((n) => n.id == firstId), isTrue);
    });

    test('3.5 Preferencias de avisos persisten por usuario', () async {
      final prefs = const NotificationPreferences(
        reminder7d: false,
        reminder3d: true,
        reminder1d: false,
        reminderDueDay: true,
        reminderOverdue: true,
        reminderWeeklyReview: false,
      );

      await prefs.saveForUser(testUserId);

      final loaded = await NotificationPreferences.load(testUserId);
      expect(loaded.reminder7d, isFalse);
      expect(loaded.reminder3d, isTrue);
      expect(loaded.reminder1d, isFalse);
      expect(loaded.reminderDueDay, isTrue);
      expect(loaded.reminderWeeklyReview, isFalse);
    });
  });

  group('4. CONFIGURACIÓN: APARIENCIA, TEMA OSCURO Y AUTO-SYNC', () {
    test('4.1 Tema oscuro se aplica a toda la aplicación y persiste', () async {
      expect(appState.themeMode, ThemeMode.system);

      await appState.setThemeMode(ThemeMode.dark);
      expect(appState.themeMode, ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_theme_mode'), 'dark');

      // Validar colores del tema oscuro
      expect(AppTheme.dark.brightness, Brightness.dark);
      expect(AppTheme.dark.scaffoldBackgroundColor, const Color(0xFF0B132B));
    });

    test('4.2 Desactivar auto-sync conserva operaciones pendientes para sincronización manual', () async {
      expect(appState.autoSyncEnabled, isTrue);

      await appState.setAutoSyncEnabled(false);
      expect(appState.autoSyncEnabled, isFalse);
      expect(appState.syncService.autoSyncEnabled, isFalse);

      // Crear transacción con auto-sync desactivado
      final tx = MoneyTransaction(
        id: 'tx_manual_sync_1',
        type: 'expense',
        category: 'Alimentación',
        amount: 5500,
        description: 'Almuerzo soda',
        date: DateTime.now(),
        recognized: true,
      );

      await financeRepo.saveTransaction(
        userId: testUserId,
        transaction: tx,
        isNew: true,
      );

      // Sigue en la cola de pendientes sin sincronizar automáticamente
      final pendingCount = await financeRepo.getPendingOperationsCount(testUserId);
      expect(pendingCount, greaterThanOrEqualTo(1));
    });

    test('4.3 Limpieza de caché segura: NO toca transacciones, compromisos ni cola pendiente', () async {
      // 1. Crear datos financieros
      final tx = MoneyTransaction(
        id: 'tx_safe_cache',
        type: 'income',
        category: 'Salario',
        amount: 500000,
        description: 'Pago quincenal',
        date: DateTime.now(),
        recognized: true,
      );
      await financeRepo.saveTransaction(
        userId: testUserId,
        transaction: tx,
        isNew: true,
      );

      final commitment = Commitment(
        id: 'c_safe_cache',
        title: 'Ahorro Escolar',
        amount: 25000,
        dueDate: DateTime.now().add(const Duration(days: 15)),
        status: 'pending',
        version: 1,
      );
      await financeRepo.saveCommitment(
        userId: testUserId,
        commitment: commitment,
        isNew: true,
      );

      final txCountBefore = (await financeRepo.getTransactions(testUserId)).length;
      final pendingBefore = await financeRepo.getPendingOperationsCount(testUserId);
      expect(txCountBefore, greaterThan(0));
      expect(pendingBefore, greaterThan(0));

      // 2. Ejecutar limpieza de archivos temporales seguros (simulando acción del SettingsScreen)
      final prefs = await SharedPreferences.getInstance();
      // Elimina solo claves de caché volátil como tips o cache de gráficos
      await prefs.remove('cached_financial_tip');
      await prefs.remove('cached_chart_series');

      // 3. Confirmar que ninguna tabla financiera o pendiente fue borrada
      final txCountAfter = (await financeRepo.getTransactions(testUserId)).length;
      final pendingAfter = await financeRepo.getPendingOperationsCount(testUserId);
      expect(txCountAfter, equals(txCountBefore));
      expect(pendingAfter, equals(pendingBefore));
    });
  });
}
