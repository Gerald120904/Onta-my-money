class DashboardSummary {
  final String? accountId;
  final String? accountName;
  final String? currency;
  final double openingBalance;
  final double income;
  final double expenses;
  final double balance;
  final double committed;
  final double saved;
  final double available;
  final List<CategoryTotal> byCategory;

  DashboardSummary({
    this.accountId,
    this.accountName,
    this.currency,
    this.openingBalance = 0.0,
    this.income = 0.0,
    this.expenses = 0.0,
    required this.balance,
    required this.committed,
    required this.saved,
    required this.available,
    required this.byCategory,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> j) => DashboardSummary(
        accountId: j['account_id']?.toString(),
        accountName: j['account_name']?.toString(),
        currency: j['currency']?.toString(),
        openingBalance: (j['opening_balance'] as num?)?.toDouble() ?? 0.0,
        income: (j['income'] as num?)?.toDouble() ?? 0.0,
        expenses: (j['expenses'] as num?)?.toDouble() ?? 0.0,
        balance: (j['balance'] as num).toDouble(),
        committed: (j['committed'] as num).toDouble(),
        saved: (j['saved'] as num).toDouble(),
        available: (j['available'] as num).toDouble(),
        byCategory: (j['byCategory'] as List? ?? []).map((e) => CategoryTotal.fromJson(Map<String, dynamic>.from(e))).toList(),
      );
}

class CategoryTotal {
  final String category;
  final double total;
  CategoryTotal(this.category, this.total);
  factory CategoryTotal.fromJson(Map<String, dynamic> j) => CategoryTotal(j['category'].toString(), (j['total'] as num).toDouble());
}

class Account {
  final String id;
  final String userId;
  final String name;
  final String currency; // Inmutable ISO 4217, p.ej. 'CRC', 'USD', 'EUR'
  final double initialBalance;
  final double currentBalance;
  final String? color;
  final String? icon;
  final bool isDefault;
  final bool isArchived;
  final int version;
  final String syncStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Account({
    required this.id,
    required this.userId,
    required this.name,
    required String currency,
    required this.initialBalance,
    this.currentBalance = 0.0,
    this.color,
    this.icon,
    this.isDefault = false,
    this.isArchived = false,
    this.version = 1,
    this.syncStatus = 'synced',
    this.createdAt,
    this.updatedAt,
  }) : currency = currency.toUpperCase().trim();

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'].toString(),
        userId: (j['user_id'] ?? j['userId'] ?? '').toString(),
        name: (j['name'] ?? 'Cuenta').toString(),
        currency: (j['currency'] ?? 'CRC').toString().toUpperCase(),
        initialBalance: (j['initial_balance'] ?? j['initialBalance'] ?? j['opening_balance'] ?? 0.0 as num).toDouble(),
        currentBalance: (j['current_balance'] ?? j['currentBalance'] ?? j['initial_balance'] ?? 0.0 as num).toDouble(),
        color: j['color']?.toString(),
        icon: j['icon']?.toString(),
        isDefault: (j['is_default'] == true || j['is_default'] == 1 || j['isDefault'] == true),
        isArchived: (j['is_archived'] == true || j['is_archived'] == 1 || j['isArchived'] == true),
        version: (j['version'] as num?)?.toInt() ?? 1,
        syncStatus: j['sync_status']?.toString() ?? 'synced',
        createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at'].toString()) : null,
        updatedAt: j['updated_at'] != null ? DateTime.tryParse(j['updated_at'].toString()) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'name': name,
        'currency': currency,
        'initial_balance': initialBalance,
        'current_balance': currentBalance,
        'color': color,
        'icon': icon,
        'is_default': isDefault,
        'is_archived': isArchived,
        'version': version,
      };

  Account copyWith({
    String? name,
    double? initialBalance,
    double? currentBalance,
    String? color,
    String? icon,
    bool? isDefault,
    bool? isArchived,
    int? version,
    String? syncStatus,
  }) {
    return Account(
      id: id,
      userId: userId,
      name: name ?? this.name,
      currency: currency, // Inmutable
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      isArchived: isArchived ?? this.isArchived,
      version: version ?? this.version,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

class MoneyTransaction {
  final String id, type, category, description;
  final String? accountId;
  final double amount;
  final DateTime date;
  final bool recognized;
  final String syncStatus;
  final int version;

  MoneyTransaction({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    required this.recognized,
    this.accountId,
    this.syncStatus = 'synced',
    this.version = 1,
  });

  factory MoneyTransaction.fromJson(Map<String, dynamic> j) => MoneyTransaction(
        id: j['id'].toString(),
        type: j['type'].toString(),
        category: j['category'].toString(),
        amount: (j['amount'] as num).toDouble(),
        description: j['description']?.toString() ?? '',
        date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
        recognized: (j['recognized'] as num?)?.toInt() != 0,
        accountId: (j['account_id'] ?? j['accountId'])?.toString(),
        syncStatus: j['sync_status']?.toString() ?? 'synced',
        version: (j['version'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'type': type,
        'category': category,
        'amount': amount,
        'description': description,
        'date': date.toIso8601String(),
        'recognized': recognized,
        'account_id': accountId,
        'version': version,
      };

  MoneyTransaction copyWith({
    String? type,
    String? category,
    double? amount,
    String? description,
    DateTime? date,
    bool? recognized,
    String? accountId,
    String? syncStatus,
    int? version,
  }) {
    return MoneyTransaction(
      id: id,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      date: date ?? this.date,
      recognized: recognized ?? this.recognized,
      accountId: accountId ?? this.accountId,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
    );
  }
}

class Commitment {
  final String id, title, status;
  final String? accountId;
  final double amount;
  final DateTime dueDate;
  final String syncStatus;
  final int version;

  Commitment({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.accountId,
    this.syncStatus = 'synced',
    this.version = 1,
  });

  factory Commitment.fromJson(Map<String, dynamic> j) => Commitment(
        id: j['id'].toString(),
        title: j['title'].toString(),
        amount: (j['amount'] as num).toDouble(),
        dueDate: DateTime.tryParse((j['due_date'] ?? j['dueDate'])?.toString() ?? '') ?? DateTime.now(),
        status: j['status'].toString(),
        accountId: (j['account_id'] ?? j['accountId'])?.toString(),
        syncStatus: j['sync_status']?.toString() ?? 'synced',
        version: (j['version'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'amount': amount,
        'dueDate': dueDate.toIso8601String(),
        'status': status,
        'account_id': accountId,
        'version': version,
      };

  Commitment copyWith({
    String? title,
    double? amount,
    DateTime? dueDate,
    String? status,
    String? accountId,
    String? syncStatus,
    int? version,
  }) {
    return Commitment(
      id: id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      accountId: accountId ?? this.accountId,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
    );
  }
}

class SavingsGoal {
  final String id, title;
  final String? accountId;
  final double targetAmount, savedAmount;
  final String syncStatus;
  final int version;

  SavingsGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    this.accountId,
    this.syncStatus = 'synced',
    this.version = 1,
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> j) => SavingsGoal(
        id: j['id'].toString(),
        title: j['title'].toString(),
        targetAmount: (j['target_amount'] ?? j['targetAmount'] as num).toDouble(),
        savedAmount: (j['saved_amount'] ?? j['savedAmount'] as num).toDouble(),
        accountId: (j['account_id'] ?? j['accountId'])?.toString(),
        syncStatus: j['sync_status']?.toString() ?? 'synced',
        version: (j['version'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'targetAmount': targetAmount,
        'savedAmount': savedAmount,
        'account_id': accountId,
        'version': version,
      };

  SavingsGoal copyWith({
    String? title,
    double? targetAmount,
    double? savedAmount,
    String? accountId,
    String? syncStatus,
    int? version,
  }) {
    return SavingsGoal(
      id: id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      accountId: accountId ?? this.accountId,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
    );
  }
}
