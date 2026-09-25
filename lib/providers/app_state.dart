import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api/api_client.dart';
import '../models/models.dart';
import '../models/review_result.dart';

class AppState extends ChangeNotifier {
  final ApiClient api = ApiClient();

  bool loading = false;
  String? error;

  DashboardSummary? dashboard;

  List<MoneyTransaction> transactions = [];
  List<Commitment> commitments = [];
  List<SavingsGoal> goals = [];

  // =========================================================
  // USUARIO ACTUAL
  // =========================================================

  String? currentUserEmail;

  // =========================================================
  // HISTORIAL DE REPORTES
  // =========================================================

  List<ReviewResult> reviews = [];

  ReviewResult? get latestReview {
    if (reviews.isEmpty) {
      return null;
    }

    return reviews.first;
  }

  bool get isAuthenticated {
    return api.token != null;
  }

  // =========================================================
  // SALDO ACTUAL
  // =========================================================

  double get totalIncome {
    return transactions
        .where(
          (transaction) =>
              transaction.type.toLowerCase() ==
              'income',
        )
        .fold<double>(
          0,
          (
            total,
            transaction,
          ) {
            return total + transaction.amount;
          },
        );
  }

  double get totalExpenses {
    return transactions
        .where(
          (transaction) =>
              transaction.type.toLowerCase() ==
              'expense',
        )
        .fold<double>(
          0,
          (
            total,
            transaction,
          ) {
            return total + transaction.amount;
          },
        );
  }

  double get currentBalance {
    return totalIncome - totalExpenses;
  }

  // =========================================================
  // CLAVE DE ALMACENAMIENTO
  // =========================================================

  String _reviewStorageKey(
    String email,
  ) {
    return 'review_history_${email.trim().toLowerCase()}';
  }

  // =========================================================
  // RESTAURAR SESIÓN
  // =========================================================

  Future<void> restoreSession() async {
    final prefs =
        await SharedPreferences.getInstance();

    api.token =
        prefs.getString('token');

    currentUserEmail =
        prefs.getString(
      'current_user_email',
    );

    if (api.token == null) {
      reviews = [];
      return;
    }

    if (currentUserEmail != null) {
      await _loadReviewHistory(
        prefs,
        currentUserEmail!,
      );
    }

    try {
      await refreshAll();
    } catch (_) {
      api.token = null;

      dashboard = null;
      transactions = [];
      commitments = [];
      goals = [];

      reviews = [];
      currentUserEmail = null;

      await prefs.remove(
        'token',
      );

      await prefs.remove(
        'current_user_email',
      );

      notifyListeners();
    }
  }

  // =========================================================
  // LOGIN
  // =========================================================

  Future<void> login(
    String email,
    String password,
  ) =>
      _run(
        () async {
          final data =
              Map<String, dynamic>.from(
            await api.post(
              '/api/auth/login',
              {
                'email': email,
                'password': password,
              },
            ),
          );

          api.token =
              data['token'].toString();

          currentUserEmail =
              email.trim().toLowerCase();

          final prefs =
              await SharedPreferences
                  .getInstance();

          await prefs.setString(
            'token',
            api.token!,
          );

          await prefs.setString(
            'current_user_email',
            currentUserEmail!,
          );

          await _loadReviewHistory(
            prefs,
            currentUserEmail!,
          );

          await refreshAll(
            silent: true,
          );
        },
      );

  // =========================================================
  // REGISTRO
  // =========================================================

  Future<void> register(
    String name,
    String email,
    String password,
  ) =>
      _run(
        () async {
          await api.post(
            '/api/auth/register',
            {
              'name': name,
              'email': email,
              'password': password,
            },
          );
        },
      );

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> logout() async {
    try {
      await api.post(
        '/api/auth/logout',
      );
    } catch (_) {}

    api.token = null;

    dashboard = null;

    transactions = [];

    commitments = [];

    goals = [];

    reviews = [];

    currentUserEmail = null;

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(
      'token',
    );

    await prefs.remove(
      'current_user_email',
    );

    notifyListeners();
  }

  // =========================================================
  // REFRESCAR INFORMACIÓN
  // =========================================================

  Future<void> refreshAll({
    bool silent = false,
  }) async {
    if (!silent) {
      loading = true;
      notifyListeners();
    }

    try {
      final result =
          await Future.wait(
        [
          api.get(
            '/api/dashboard',
          ),
          api.get(
            '/api/transactions',
          ),
          api.get(
            '/api/commitments',
          ),
          api.get(
            '/api/goals',
          ),
        ],
      );

      dashboard =
          DashboardSummary.fromJson(
        Map<String, dynamic>.from(
          result[0],
        ),
      );

      transactions =
          (result[1] as List)
              .map(
                (item) =>
                    MoneyTransaction.fromJson(
                  Map<String, dynamic>.from(
                    item,
                  ),
                ),
              )
              .toList();

      commitments =
          (result[2] as List)
              .map(
                (item) =>
                    Commitment.fromJson(
                  Map<String, dynamic>.from(
                    item,
                  ),
                ),
              )
              .toList();

      goals =
          (result[3] as List)
              .map(
                (item) =>
                    SavingsGoal.fromJson(
                  Map<String, dynamic>.from(
                    item,
                  ),
                ),
              )
              .toList();

      error = null;
    } finally {
      loading = false;

      notifyListeners();
    }
  }

  // =========================================================
  // TRANSACCIONES
  // =========================================================

  Future<void> saveTransaction(
    MoneyTransaction transaction, {
    bool create = false,
  }) =>
      _run(
        () async {
          // ---------------------------------------------------
          // El monto siempre debe ser mayor que cero.
          // ---------------------------------------------------

          if (transaction.amount <= 0) {
            throw Exception(
              'El monto debe ser mayor que ₡0.',
            );
          }

          // ---------------------------------------------------
          // CALCULAR SALDO PROYECTADO
          //
          // Si estamos editando, primero devolvemos al saldo
          // el efecto de la transacción vieja.
          // ---------------------------------------------------

          double balanceBeforeNewTransaction =
              currentBalance;

          if (!create) {
            MoneyTransaction? oldTransaction;

            for (final item in transactions) {
              if (item.id == transaction.id) {
                oldTransaction = item;
                break;
              }
            }

            if (oldTransaction != null) {
              final oldType =
                  oldTransaction.type
                      .toLowerCase();

              if (oldType == 'expense') {
                balanceBeforeNewTransaction +=
                    oldTransaction.amount;
              } else if (oldType == 'income') {
                balanceBeforeNewTransaction -=
                    oldTransaction.amount;
              }
            }
          }

          // ---------------------------------------------------
          // APLICAR NUEVA TRANSACCIÓN
          // ---------------------------------------------------

          final newType =
              transaction.type.toLowerCase();

          double projectedBalance =
              balanceBeforeNewTransaction;

          if (newType == 'expense') {
            projectedBalance -=
                transaction.amount;
          } else if (newType == 'income') {
            projectedBalance +=
                transaction.amount;
          }

          // ---------------------------------------------------
          // NO PERMITIR SALDO NEGATIVO
          // ---------------------------------------------------

          if (projectedBalance < 0) {
            final available =
                balanceBeforeNewTransaction < 0
                    ? 0.0
                    : balanceBeforeNewTransaction;

            throw Exception(
              'No podés registrar este gasto. '
              'Tu saldo disponible es de '
              '₡${_formatAmount(available)}.',
            );
          }

          // ---------------------------------------------------
          // GUARDAR
          // ---------------------------------------------------

          if (create) {
            await api.post(
              '/api/transactions',
              transaction.toJson(),
            );
          } else {
            await api.put(
              '/api/transactions/${transaction.id}',
              transaction.toJson(),
            );
          }

          await refreshAll(
            silent: true,
          );
        },
      );

  // =========================================================
  // ELIMINAR TRANSACCIÓN
  // =========================================================

  Future<void> deleteTransaction(
    String id,
  ) =>
      _run(
        () async {
          MoneyTransaction? transaction;

          for (final item in transactions) {
            if (item.id == id) {
              transaction = item;
              break;
            }
          }

          // ---------------------------------------------------
          // Si elimina un ingreso, comprobamos que los gastos
          // existentes no dejen el saldo en negativo.
          // ---------------------------------------------------

          if (transaction != null &&
              transaction.type.toLowerCase() ==
                  'income') {
            final projectedBalance =
                currentBalance -
                    transaction.amount;

            if (projectedBalance < 0) {
              throw Exception(
                'No podés eliminar este ingreso porque '
                'el saldo quedaría en negativo.',
              );
            }
          }

          await api.delete(
            '/api/transactions/$id',
          );

          await refreshAll(
            silent: true,
          );
        },
      );

  // =========================================================
  // COMPROMISOS
  // =========================================================

  Future<void> saveCommitment(
    Commitment commitment, {
    bool create = false,
  }) =>
      _run(
        () async {
          if (create) {
            await api.post(
              '/api/commitments',
              commitment.toJson(),
            );
          } else {
            await api.put(
              '/api/commitments/${commitment.id}',
              commitment.toJson(),
            );
          }

          await refreshAll(
            silent: true,
          );
        },
      );

  Future<void> deleteCommitment(
    String id,
  ) =>
      _run(
        () async {
          await api.delete(
            '/api/commitments/$id',
          );

          await refreshAll(
            silent: true,
          );
        },
      );

  // =========================================================
  // METAS
  // =========================================================

  Future<void> saveGoal(
    SavingsGoal goal, {
    bool create = false,
  }) =>
      _run(
        () async {
          if (create) {
            await api.post(
              '/api/goals',
              goal.toJson(),
            );
          } else {
            await api.put(
              '/api/goals/${goal.id}',
              goal.toJson(),
            );
          }

          await refreshAll(
            silent: true,
          );
        },
      );

  Future<void> deleteGoal(
    String id,
  ) =>
      _run(
        () async {
          await api.delete(
            '/api/goals/$id',
          );

          await refreshAll(
            silent: true,
          );
        },
      );

  // =========================================================
  // DECISIÓN DEL BACKEND
  // =========================================================

  Future<void> saveDecision(
    String action,
    String note,
  ) =>
      _run(
        () async {
          await api.post(
            '/api/decisions',
            {
              'action': action,
              'note': note,
            },
          );
        },
      );

  // =========================================================
  // GUARDAR REPORTE
  // =========================================================

  Future<void> saveReviewResult(
    ReviewResult result,
  ) async {
    reviews.removeWhere(
      (item) {
        return item.createdAt ==
            result.createdAt;
      },
    );

    reviews.insert(
      0,
      result,
    );

    reviews.sort(
      (a, b) =>
          b.createdAt.compareTo(
        a.createdAt,
      ),
    );

    notifyListeners();

    final email =
        currentUserEmail;

    if (email == null) {
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    await _persistReviewHistory(
      prefs,
      email,
    );
  }

  // =========================================================
  // ELIMINAR REPORTE
  // =========================================================

  Future<void> deleteReviewResult(
    ReviewResult result,
  ) async {
    reviews.removeWhere(
      (item) {
        return item.createdAt ==
            result.createdAt;
      },
    );

    notifyListeners();

    final email =
        currentUserEmail;

    if (email == null) {
      return;
    }

    final prefs =
        await SharedPreferences.getInstance();

    await _persistReviewHistory(
      prefs,
      email,
    );
  }

  // =========================================================
  // CARGAR HISTORIAL
  // =========================================================

  Future<void> _loadReviewHistory(
    SharedPreferences prefs,
    String email,
  ) async {
    reviews = [];

    final key =
        _reviewStorageKey(
      email,
    );

    final raw =
        prefs.getString(
      key,
    );

    if (raw != null &&
        raw.trim().isNotEmpty) {
      try {
        final decoded =
            jsonDecode(raw);

        if (decoded is List) {
          reviews =
              decoded
                  .whereType<Map>()
                  .map(
                    (item) =>
                        ReviewResult.fromJson(
                      Map<String, dynamic>.from(
                        item,
                      ),
                    ),
                  )
                  .toList();
        }
      } catch (_) {
        reviews = [];
      }
    }

    // =======================================================
    // MIGRAR REPORTE VIEJO
    // =======================================================

    if (reviews.isEmpty) {
      final oldReview =
          prefs.getString(
        'latest_review',
      );

      if (oldReview != null &&
          oldReview.trim().isNotEmpty) {
        try {
          final decoded =
              jsonDecode(
            oldReview,
          );

          final review =
              ReviewResult.fromJson(
            Map<String, dynamic>.from(
              decoded,
            ),
          );

          reviews = [
            review,
          ];

          await _persistReviewHistory(
            prefs,
            email,
          );

          await prefs.remove(
            'latest_review',
          );
        } catch (_) {}
      }
    }

    reviews.sort(
      (a, b) =>
          b.createdAt.compareTo(
        a.createdAt,
      ),
    );
  }

  // =========================================================
  // GUARDAR HISTORIAL LOCAL
  // =========================================================

  Future<void> _persistReviewHistory(
    SharedPreferences prefs,
    String email,
  ) async {
    final encoded =
        jsonEncode(
      reviews
          .map(
            (review) =>
                review.toJson(),
          )
          .toList(),
    );

    await prefs.setString(
      _reviewStorageKey(
        email,
      ),
      encoded,
    );
  }

  // =========================================================
  // FORMATEAR MONTO PARA MENSAJES
  // =========================================================

  String _formatAmount(
    double amount,
  ) {
    final rounded =
        amount.round();

    final raw =
        rounded.toString();

    final buffer =
        StringBuffer();

    for (var i = 0;
        i < raw.length;
        i++) {
      final positionFromEnd =
          raw.length - i;

      buffer.write(
        raw[i],
      );

      if (positionFromEnd > 1 &&
          (positionFromEnd - 1) % 3 == 0) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }

  // =========================================================
  // CONTROL GENERAL
  // =========================================================

  Future<void> _run(
    Future<void> Function()
        function,
  ) async {
    loading = true;

    error = null;

    notifyListeners();

    try {
      await function();
    } catch (e) {
      error = e.toString();

      rethrow;
    } finally {
      loading = false;

      notifyListeners();
    }
  }
}