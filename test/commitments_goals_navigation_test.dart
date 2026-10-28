import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:donde_se_fue_mi_plata/core/theme/app_theme.dart';
import 'package:donde_se_fue_mi_plata/core/utils/formatters.dart';
import 'package:donde_se_fue_mi_plata/data/local/app_database.dart';
import 'package:donde_se_fue_mi_plata/data/repositories/finance_repository.dart';
import 'package:donde_se_fue_mi_plata/models/models.dart';
import 'package:donde_se_fue_mi_plata/providers/app_state.dart';
import 'package:donde_se_fue_mi_plata/screens/commitments_screen.dart';
import 'package:donde_se_fue_mi_plata/screens/dashboard_screen.dart';
import 'package:donde_se_fue_mi_plata/screens/goals_screen.dart';
import 'package:donde_se_fue_mi_plata/screens/more_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FinanceRepository financeRepo;
  late AppState appState;

  const testUserId = 'user_nav_test_123';
  const testUserEmail = 'usuario@ejemplo.com';
  const testUserName = 'Usuario Test';

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'token_test_123',
      'user_id': testUserId,
      'user_email': testUserEmail,
      'current_user_name': testUserName,
      'user_opening_balance': 200000.0,
      'auto_sync_enabled': false,
    });

    db = AppDatabase.inMemory(NativeDatabase.memory());
    financeRepo = FinanceRepository(db);

    await financeRepo.saveUser(
      id: testUserId,
      name: testUserName,
      email: testUserEmail,
      token: 'token_test_123',
      openingBalance: 200000.0,
      isCurrent: true,
    );

    // Cuenta CRC por defecto
    await financeRepo.saveAccount(
      userId: testUserId,
      account: Account(
        id: 'acc_crc_main',
        userId: testUserId,
        name: 'Cuenta Principal Colones',
        currency: 'CRC',
        initialBalance: 200000.0,
        isDefault: true,
      ),
      isNew: true,
    );

    // Cuenta USD secundaria
    await financeRepo.saveAccount(
      userId: testUserId,
      account: Account(
        id: 'acc_usd_savings',
        userId: testUserId,
        name: 'Ahorro Dólares',
        currency: 'USD',
        initialBalance: 1500.0,
        isDefault: false,
      ),
      isNew: true,
    );

    // Cuenta EUR terciaria
    await financeRepo.saveAccount(
      userId: testUserId,
      account: Account(
        id: 'acc_eur_trip',
        userId: testUserId,
        name: 'Viaje Europa Euros',
        currency: 'EUR',
        initialBalance: 800.0,
        isDefault: false,
      ),
      isNew: true,
    );

    appState = AppState(customDb: db);
    appState.currentUserId = testUserId;
    appState.currentUserEmail = testUserEmail;
    appState.currentUserName = testUserName;
    appState.api.token = 'token_test_123';
    appState.autoSyncEnabled = false;

    await appState.restoreSession();
    appState.autoSyncEnabled = false;
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

  group('1. NAVEGACIÓN DESDE MORESCREEN Y DASHBOARDSCREEN', () {
    testWidgets(
        '1.1 Opciones visibles en MoreScreen abren CommitmentsScreen y GoalsScreen',
        (tester) async {
      await tester.pumpWidget(buildTestApp(MoreScreen(state: appState)));
      await tester.pumpAndSettle();

      // Verificar existencia de las dos opciones en Más
      expect(find.text('Dinero comprometido'), findsOneWidget);
      expect(find.text('Ahorro'), findsOneWidget);

      // Abrir Dinero comprometido
      await tester.tap(find.text('Dinero comprometido'));
      await tester.pumpAndSettle();
      expect(find.byType(CommitmentsScreen), findsOneWidget);
      expect(find.text('Compromisos'), findsOneWidget);

      // Regresar
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(CommitmentsScreen), findsNothing);

      // Abrir Ahorro
      await tester.tap(find.text('Ahorro'));
      await tester.pumpAndSettle();
      expect(find.byType(GoalsScreen), findsOneWidget);
      expect(find.text('Separá dinero para tus metas antes de gastarlo.'),
          findsOneWidget);

      // Regresar
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(GoalsScreen), findsNothing);
    });

    testWidgets(
        '1.2 Tarjetas en DashboardScreen (Inicio) abren CommitmentsScreen y GoalsScreen al tocar',
        (tester) async {
      await tester.pumpWidget(
          buildTestApp(DashboardScreen(state: appState, onReview: () {})));
      await tester.pumpAndSettle();

      // Verificar que las tarjetas existen en Inicio
      expect(find.text('Dinero comprometido'), findsOneWidget);
      expect(find.text('Ahorro reservado'), findsOneWidget);
      expect(find.text('Disponible real'), findsOneWidget);

      // Tocar tarjeta Dinero comprometido
      await tester.tap(find.text('Dinero comprometido'));
      await tester.pumpAndSettle();
      expect(find.byType(CommitmentsScreen), findsOneWidget);

      // Regresar a Inicio
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(CommitmentsScreen), findsNothing);

      // Tocar tarjeta Ahorro reservado
      await tester.tap(find.text('Ahorro reservado'));
      await tester.pumpAndSettle();
      expect(find.byType(GoalsScreen), findsOneWidget);

      // Regresar a Inicio
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(GoalsScreen), findsNothing);
    });
  });

  group('2. ADMINISTRACIÓN (CRUD) OFFLINE-FIRST DE COMPROMISOS Y METAS', () {
    test(
        '2.1 Crear, editar y eliminar compromiso persiste en Drift y encola sync',
        () async {
      // 1. CREAR COMPROMISO
      final commitment = Commitment(
        id: 'com_alquiler_1',
        title: 'Alquiler del mes',
        amount: 85000.0,
        dueDate: DateTime.now().add(const Duration(days: 5)),
        status: 'pending',
        accountId: appState.activeAccount?.id,
      );

      await appState.saveCommitment(commitment, create: true);

      // Verificar estado en memoria
      expect(appState.commitments.length, 1);
      expect(appState.commitments.first.title, 'Alquiler del mes');
      expect(appState.commitments.first.amount, 85000.0);
      expect(appState.committedAmount, 85000.0);

      // Verificar persistencia en Drift SQLite
      final localComs = await financeRepo.getCommitments(testUserId);
      expect(localComs.length, 1);
      expect(localComs.first.title, 'Alquiler del mes');

      // Verificar cola de sincronización
      final pendingOps = await financeRepo.getPendingOperations(testUserId);
      final comOps =
          pendingOps.where((op) => op.entityType == 'commitment').toList();
      expect(comOps.length, 1);
      expect(comOps.first.action, 'create');

      // 2. EDITAR COMPROMISO
      final createdCom = appState.commitments.first;
      final updatedCom = createdCom.copyWith(
        amount: 90000.0,
        title: 'Alquiler con cochera',
      );
      await appState.saveCommitment(updatedCom, create: false);

      expect(appState.commitments.first.amount, 90000.0);
      expect(appState.commitments.first.title, 'Alquiler con cochera');
      expect(appState.committedAmount, 90000.0);

      // 3. ELIMINAR COMPROMISO
      await appState.deleteCommitment(createdCom.id);
      expect(appState.commitments.isEmpty, true);
      expect(appState.committedAmount, 0.0);

      final opsAfterDelete = await financeRepo.getPendingOperations(testUserId);
      final delOps = opsAfterDelete
          .where((op) => op.entityType == 'commitment' && op.action == 'delete')
          .toList();
      expect(delOps.length, 1);
    });

    test(
        '2.2 Crear, editar y eliminar meta de ahorro persiste en Drift y encola sync',
        () async {
      // 1. CREAR META
      final goal = SavingsGoal(
        id: 'goal_viaje_1',
        title: 'Fondo de Emergencia',
        targetAmount: 300000.0,
        savedAmount: 50000.0,
        accountId: appState.activeAccount?.id,
      );

      await appState.saveGoal(goal, create: true);

      // Verificar estado en memoria
      expect(appState.goals.length, 1);
      expect(appState.goals.first.title, 'Fondo de Emergencia');
      expect(appState.goals.first.savedAmount, 50000.0);
      expect(appState.savedAmount, 50000.0);

      // Verificar persistencia en Drift
      final localGoals = await financeRepo.getGoals(testUserId);
      expect(localGoals.length, 1);
      expect(localGoals.first.title, 'Fondo de Emergencia');

      // Verificar cola de sincronización
      final pendingOps = await financeRepo.getPendingOperations(testUserId);
      final goalOps =
          pendingOps.where((op) => op.entityType == 'goal').toList();
      expect(goalOps.length, 1);
      expect(goalOps.first.action, 'create');

      // 2. EDITAR META
      final createdGoal = appState.goals.first;
      final updatedGoal = createdGoal.copyWith(
        savedAmount: 75000.0,
      );
      await appState.saveGoal(updatedGoal, create: false);

      expect(appState.goals.first.savedAmount, 75000.0);
      expect(appState.savedAmount, 75000.0);

      // 3. ELIMINAR META
      await appState.deleteGoal(createdGoal.id);
      expect(appState.goals.isEmpty, true);
      expect(appState.savedAmount, 0.0);

      final opsAfterDelete = await financeRepo.getPendingOperations(testUserId);
      final delOps = opsAfterDelete
          .where((op) => op.entityType == 'goal' && op.action == 'delete')
          .toList();
      expect(delOps.length, 1);
    });
  });

  group('3. DISPONIBLE REAL EN INICIO: CÁLCULO PRECISO SIN DUPLICACIONES', () {
    test('3.1 Disponible real = Saldo actual - Comprometido - Ahorrado',
        () async {
      // Saldo inicial cuenta CRC: 200.000
      expect(appState.currentBalance, 200000.0);
      expect(appState.committedAmount, 0.0);
      expect(appState.savedAmount, 0.0);
      expect(appState.availableBalance, 200000.0);

      // Agregar ingreso de 50.000
      await appState.saveTransaction(
        MoneyTransaction(
          id: 'tx_inc_1',
          type: 'income',
          category: 'Salario',
          amount: 50000.0,
          description: 'Quincena',
          date: DateTime.now(),
          recognized: true,
          accountId: appState.activeAccount?.id,
        ),
        create: true,
      );

      // Agregar gasto de 20.000
      await appState.saveTransaction(
        MoneyTransaction(
          id: 'tx_exp_1',
          type: 'expense',
          category: 'Supermercado',
          amount: 20000.0,
          description: 'Compras',
          date: DateTime.now(),
          recognized: true,
          accountId: appState.activeAccount?.id,
        ),
        create: true,
      );

      // Saldo actual = 200.000 + 50.000 - 20.000 = 230.000
      expect(appState.currentBalance, 230000.0);

      // Agregar compromiso de 40.000
      await appState.saveCommitment(
        Commitment(
          id: 'com_servicios_1',
          title: 'Electricidad e Internet',
          amount: 40000.0,
          dueDate: DateTime.now().add(const Duration(days: 3)),
          status: 'pending',
          accountId: appState.activeAccount?.id,
        ),
        create: true,
      );

      // Agregar meta de ahorro con 30.000 reservados
      await appState.saveGoal(
        SavingsGoal(
          id: 'goal_ahorro_1',
          title: 'Ahorro vacaciones',
          targetAmount: 100000.0,
          savedAmount: 30000.0,
          accountId: appState.activeAccount?.id,
        ),
        create: true,
      );

      // Disponible real = 230.000 - 40.000 - 30.000 = 160.000
      expect(appState.committedAmount, 40000.0);
      expect(appState.savedAmount, 30000.0);
      expect(appState.availableBalance, 160000.0);

      // Marcar compromiso como pagado ('paid') libera el dinero comprometido
      final paidCommitment =
          appState.commitments.first.copyWith(status: 'paid');
      await appState.saveCommitment(paidCommitment, create: false);

      // Al estar 'paid', no descuenta de disponible real
      expect(appState.committedAmount, 0.0);
      // Disponible real = 230.000 - 0 - 30.000 = 200.000
      expect(appState.availableBalance, 200000.0);
    });

    test('3.2 Gastos que intenten consumir dinero reservado son bloqueados',
        () async {
      // Saldo actual = 200.000
      expect(appState.currentBalance, 200000.0);

      // Reservar 60.000 en compromiso pendiente
      await appState.saveCommitment(
        Commitment(
          id: 'com_seguro_1',
          title: 'Seguro anual',
          amount: 60000.0,
          dueDate: DateTime.now().add(const Duration(days: 7)),
          status: 'pending',
          accountId: appState.activeAccount?.id,
        ),
        create: true,
      );

      // Reservar 40.000 en meta de ahorro
      await appState.saveGoal(
        SavingsGoal(
          id: 'goal_estudio_1',
          title: 'Curso de Especialización',
          targetAmount: 80000.0,
          savedAmount: 40000.0,
          accountId: appState.activeAccount?.id,
        ),
        create: true,
      );

      // Disponible real = 200.000 - 60.000 - 40.000 = 100.000
      expect(appState.committedAmount, 60000.0);
      expect(appState.savedAmount, 40000.0);
      expect(appState.availableBalance, 100000.0);

      // Intentar gastar 110.000 (consume 10.000 del dinero reservado) DEBE fallar
      expect(
        () => appState.saveTransaction(
          MoneyTransaction(
            id: 'tx_gasto_excesivo',
            type: 'expense',
            category: 'Lujos',
            amount: 110000.0,
            description: 'Compra no permitida',
            date: DateTime.now(),
            recognized: true,
            accountId: appState.activeAccount?.id,
          ),
          create: true,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Tu disponible real es de ₡100.000'),
          ),
        ),
      );

      // Un gasto dentro del disponible real (80.000 <= 100.000) debe proceder
      await appState.saveTransaction(
        MoneyTransaction(
          id: 'tx_gasto_valido',
          type: 'expense',
          category: 'Servicios',
          amount: 80000.0,
          description: 'Gasto permitido',
          date: DateTime.now(),
          recognized: true,
          accountId: appState.activeAccount?.id,
        ),
        create: true,
      );

      // Saldo actual = 200.000 - 80.000 = 120.000
      expect(appState.currentBalance, 120000.0);
      // Disponible real = 120.000 - 60.000 - 40.000 = 20.000
      expect(appState.availableBalance, 20000.0);
    });

    test(
        '3.3 Edición de movimientos existentes no duplica descuento ni consume reservas',
        () async {
      // Estado: Saldo 200.000, disponible 200.000
      expect(appState.availableBalance, 200000.0);

      // Registrar gasto de 50.000
      await appState.saveTransaction(
        MoneyTransaction(
          id: 'tx_para_editar',
          type: 'expense',
          category: 'Reparaciones',
          amount: 50000.0,
          description: 'Reparación inicial',
          date: DateTime.now(),
          recognized: true,
          accountId: appState.activeAccount?.id,
        ),
        create: true,
      );

      // Saldo = 150.000, disponible = 150.000
      expect(appState.currentBalance, 150000.0);
      expect(appState.availableBalance, 150000.0);

      // Editar el gasto de 50.000 a 70.000:
      // Debe sumar 50.000 antes de restar 70.000 (disponible antes: 200.000, nuevo: 130.000)
      final existingTx = appState.transactions.first;
      await appState.saveTransaction(
        existingTx.copyWith(amount: 70000.0, description: 'Reparación final'),
        create: false,
      );

      expect(appState.currentBalance, 130000.0);
      expect(appState.availableBalance, 130000.0);

      // Intentar editarlo a 250.000 (supera los 200.000 disponibles del balance base)
      expect(
        () => appState.saveTransaction(
          existingTx.copyWith(amount: 250000.0),
          create: false,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test(
        '3.4 Flujo de marcar compromiso como pagado y registrar gasto correspondiente sin duplicación',
        () async {
      // Compromiso de 70.000 pendiente
      await appState.saveCommitment(
        Commitment(
          id: 'com_marchamo_1',
          title: 'Marchamo Vehicular',
          amount: 70000.0,
          dueDate: DateTime.now().add(const Duration(days: 2)),
          status: 'pending',
          accountId: appState.activeAccount?.id,
        ),
        create: true,
      );

      // Saldo 200.000, comprometido 70.000, disponible 130.000
      expect(appState.currentBalance, 200000.0);
      expect(appState.committedAmount, 70000.0);
      expect(appState.availableBalance, 130000.0);

      // 1. Usuario marca el compromiso como pagado
      final marchamo = appState.commitments.first;
      await appState.saveCommitment(
        marchamo.copyWith(status: 'paid'),
        create: false,
      );

      // El dinero comprometido se libera automáticamente: disponible vuelve a 200.000
      expect(appState.committedAmount, 0.0);
      expect(appState.availableBalance, 200000.0);

      // 2. Usuario registra el gasto real correspondiente al marchamo
      await appState.saveTransaction(
        MoneyTransaction(
          id: 'tx_pago_marchamo',
          type: 'expense',
          category: 'Vehículo',
          amount: 70000.0,
          description: 'Pago real de marchamo',
          date: DateTime.now(),
          recognized: true,
          accountId: appState.activeAccount?.id,
        ),
        create: true,
      );

      // Saldo actual = 130.000, disponible real = 130.000 (no duplicó la deducción)
      expect(appState.currentBalance, 130000.0);
      expect(appState.committedAmount, 0.0);
      expect(appState.availableBalance, 130000.0);
    });

    testWidgets(
        '3.5 Saldo histórico real en DashboardScreen incluye saldo inicial y movimientos de meses anteriores',
        (tester) async {
      // Saldo inicial cuenta: 200.000 CRC
      final now = DateTime.now();
      final pastDate = DateTime(now.year, now.month - 2, 10);

      // Movimiento de hace dos meses: Ingreso de 100.000
      await appState.saveTransaction(
        MoneyTransaction(
          id: 'tx_past_inc',
          type: 'income',
          category: 'Honorarios Pasados',
          amount: 100000.0,
          description: 'Trabajo mes anterior',
          date: pastDate,
          recognized: true,
          accountId: appState.activeAccount?.id,
        ),
        create: true,
      );

      // Movimiento de hace dos meses: Gasto de 40.000
      await appState.saveTransaction(
        MoneyTransaction(
          id: 'tx_past_exp',
          type: 'expense',
          category: 'Mantenimiento',
          amount: 40000.0,
          description: 'Gasto mes anterior',
          date: pastDate,
          recognized: true,
          accountId: appState.activeAccount?.id,
        ),
        create: true,
      );

      // Movimientos del mes actual: Ingreso 30.000, Gasto 10.000
      await appState.saveTransaction(
        MoneyTransaction(
          id: 'tx_cur_inc',
          type: 'income',
          category: 'Salario',
          amount: 30000.0,
          description: 'Salario actual',
          date: now,
          recognized: true,
          accountId: appState.activeAccount?.id,
        ),
        create: true,
      );

      await appState.saveTransaction(
        MoneyTransaction(
          id: 'tx_cur_exp',
          type: 'expense',
          category: 'Supermercado',
          amount: 10000.0,
          description: 'Super actual',
          date: now,
          recognized: true,
          accountId: appState.activeAccount?.id,
        ),
        create: true,
      );

      // Saldo histórico total = 200.000 + 100.000 - 40.000 + 30.000 - 10.000 = 280.000
      expect(appState.currentBalance, 280000.0);

      await tester.pumpWidget(
          buildTestApp(DashboardScreen(state: appState, onReview: () {})));
      await tester.pumpAndSettle();

      // En la tarjeta de saldo actual, debe mostrarse el saldo histórico real: ₡280.000
      expect(find.text('₡280.000'), findsWidgets);

      // En los detalles mensuales separados:
      // Ingreso del mes = ₡30.000, Gasto del mes = ₡10.000
      expect(find.text('Ingreso: ₡30.000'), findsOneWidget);
      expect(find.text('Gasto: ₡10.000'), findsOneWidget);
    });
  });

  group('4. MULTI-DIVISA Y RESPETO DE CUENTA ACTIVA (CRC, USD, EUR)', () {
    test('4.1 Cuenta activa CRC formatea en colones y aísla sus importes',
        () async {
      final crcAccount =
          appState.accounts.firstWhere((a) => a.currency == 'CRC');
      await appState.setActiveAccount(crcAccount);

      expect(appState.activeCurrency, 'CRC');
      expect(CurrencyFormatter.activeCurrency, 'CRC');
      expect(CurrencyFormatter.format(150000), '₡150.000');
    });

    test(
        '4.2 Cambiar a cuenta USD aísla metas y compromisos en USD sin mezclar con CRC',
        () async {
      final usdAccount =
          appState.accounts.firstWhere((a) => a.currency == 'USD');
      await appState.setActiveAccount(usdAccount);

      expect(appState.activeCurrency, 'USD');
      expect(CurrencyFormatter.activeCurrency, 'USD');
      expect(CurrencyFormatter.format(1500.50), '\$1,500.50');

      // Crear compromiso en USD
      await appState.saveCommitment(
        Commitment(
          id: 'com_usd_software',
          title: 'Suscripción Cloud',
          amount: 50.0,
          dueDate: DateTime.now().add(const Duration(days: 10)),
          status: 'pending',
          accountId: usdAccount.id,
        ),
        create: true,
      );

      // Solo compromisos de esta cuenta deben mostrarse
      expect(appState.commitments.length, 1);
      expect(appState.commitments.first.amount, 50.0);
      expect(appState.committedAmount, 50.0);

      // Regresar a cuenta CRC: el compromiso en USD NO debe mezclarse con CRC
      final crcAccount =
          appState.accounts.firstWhere((a) => a.currency == 'CRC');
      await appState.setActiveAccount(crcAccount);

      expect(appState.activeCurrency, 'CRC');
      final crcCommitments = appState.commitments
          .where((c) => c.accountId == crcAccount.id)
          .toList();
      expect(crcCommitments.any((c) => c.id == 'com_usd_software'), false);
    });

    test('4.3 Cuenta EUR: formateo en euros y aislamiento de balances',
        () async {
      final eurAccount =
          appState.accounts.firstWhere((a) => a.currency == 'EUR');
      await appState.setActiveAccount(eurAccount);

      expect(appState.activeCurrency, 'EUR');
      expect(CurrencyFormatter.activeCurrency, 'EUR');
      expect(CurrencyFormatter.format(850.50), '€850.50');
      expect(appState.currentBalance, 800.0);

      // Agregar gasto en EUR
      await appState.saveTransaction(
        MoneyTransaction(
          id: 'tx_eur_tren',
          type: 'expense',
          category: 'Transporte',
          amount: 150.50,
          description: 'Billete de tren',
          date: DateTime.now(),
          recognized: true,
          accountId: eurAccount.id,
        ),
        create: true,
      );

      expect(appState.currentBalance, 649.50);

      // Cambiar a cuenta CRC: no debe verse afectado por el gasto en EUR
      final crcAccount =
          appState.accounts.firstWhere((a) => a.currency == 'CRC');
      await appState.setActiveAccount(crcAccount);

      expect(appState.activeCurrency, 'CRC');
      expect(appState.currentBalance, 200000.0);
    });
  });

  group('5. GOALS SCREEN: BOTÓN «+ APORTAR» Y PERSISTENCIA OFFLINE-FIRST', () {
    testWidgets(
        '5.1 Botón + Aportar suma ahorro a la meta, descuenta disponible real y persiste sin movimientos ficticios',
        (tester) async {
      // Meta con objetivo 100.000 y ahorro inicial 20.000
      await appState.saveGoal(
        SavingsGoal(
          id: 'goal_viaje_japon',
          title: 'Viaje a Japón',
          targetAmount: 100000.0,
          savedAmount: 20000.0,
          accountId: appState.activeAccount?.id,
        ),
        create: true,
      );

      expect(appState.savedAmount, 20000.0);
      expect(appState.availableBalance, 180000.0);
      final initialTxCount = appState.transactions.length;

      await tester.pumpWidget(buildTestApp(GoalsScreen(state: appState)));
      await tester.pumpAndSettle();

      // Botón «+ Aportar» debe existir en la tarjeta de la meta
      expect(find.text('+ Aportar'), findsOneWidget);

      // Tocar «+ Aportar»
      await tester.tap(find.text('+ Aportar'));
      await tester.pumpAndSettle();

      // Modal de aporte con disponible real informado
      expect(find.text('Aportar a Viaje a Japón'), findsOneWidget);
      expect(find.text('Disponible real: ₡180.000'), findsOneWidget);

      // Ingresar monto de aporte: 30.000
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Monto a aportar'), '30000');
      await tester.pumpAndSettle();

      // Confirmar aporte
      await tester.tap(find.widgetWithText(FilledButton, 'Aportar'));
      await tester.pumpAndSettle();

      // Validar que el ahorro acumulado de la meta subió a 50.000
      expect(appState.goals.first.savedAmount, 50000.0);
      expect(appState.savedAmount, 50000.0);
      // Disponible real disminuyó a 150.000
      expect(appState.availableBalance, 150000.0);

      // NO debe haber creado ninguna transacción ni movimiento ficticio
      expect(appState.transactions.length, initialTxCount);
      final localTx = await financeRepo.getTransactions(testUserId);
      expect(localTx.length, initialTxCount);

      // Persistencia en Drift comprobada
      final localGoals = await financeRepo.getGoals(testUserId);
      expect(localGoals.first.savedAmount, 50000.0);

      // Operación encolada en sincronización
      final pendingOps = await financeRepo.getPendingOperations(testUserId);
      final updateGoalOps = pendingOps
          .where((op) => op.entityType == 'goal' && op.action == 'update')
          .toList();
      expect(updateGoalOps.isNotEmpty, true);
    });

    testWidgets(
        '5.2 Aporte que supera el disponible real es bloqueado por la validación',
        (tester) async {
      // Saldo 200.000, meta con 190.000 reservados -> disponible real = 10.000
      await appState.saveGoal(
        SavingsGoal(
          id: 'goal_tope',
          title: 'Ahorro Límite',
          targetAmount: 300000.0,
          savedAmount: 190000.0,
          accountId: appState.activeAccount?.id,
        ),
        create: true,
      );

      expect(appState.availableBalance, 10000.0);

      await tester.pumpWidget(buildTestApp(GoalsScreen(state: appState)));
      await tester.pumpAndSettle();

      await tester.tap(find.text('+ Aportar'));
      await tester.pumpAndSettle();

      // Intentar aportar 25.000 cuando solo hay 10.000 disponible
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Monto a aportar'), '25000');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Aportar'));
      await tester.pumpAndSettle();

      // La validación en pantalla bloquea el aporte
      expect(find.text('Supera el disponible real (₡10.000)'), findsOneWidget);
      // El ahorro en la meta NO cambió
      expect(appState.goals.first.savedAmount, 190000.0);
    });
  });
}
