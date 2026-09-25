class DashboardSummary {
  final double balance;
  final double committed;
  final double saved;
  final double available;
  final List<CategoryTotal> byCategory;
  DashboardSummary({required this.balance,required this.committed,required this.saved,required this.available,required this.byCategory});
  factory DashboardSummary.fromJson(Map<String,dynamic> j)=>DashboardSummary(
    balance:(j['balance'] as num).toDouble(),
    committed:(j['committed'] as num).toDouble(),
    saved:(j['saved'] as num).toDouble(),
    available:(j['available'] as num).toDouble(),
    byCategory:(j['byCategory'] as List? ?? []).map((e)=>CategoryTotal.fromJson(Map<String,dynamic>.from(e))).toList(),
  );
}

class CategoryTotal {
  final String category;
  final double total;
  CategoryTotal(this.category,this.total);
  factory CategoryTotal.fromJson(Map<String,dynamic> j)=>CategoryTotal(j['category'].toString(),(j['total'] as num).toDouble());
}

class MoneyTransaction {
  final String id,type,category,description;
  final double amount;
  final DateTime date;
  final bool recognized;
  MoneyTransaction({required this.id,required this.type,required this.category,required this.amount,required this.description,required this.date,required this.recognized});
  factory MoneyTransaction.fromJson(Map<String,dynamic> j)=>MoneyTransaction(
    id:j['id'].toString(), type:j['type'].toString(), category:j['category'].toString(),
    amount:(j['amount'] as num).toDouble(), description:j['description']?.toString() ?? '',
    date:DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
    recognized:(j['recognized'] as num?)?.toInt()!=0,
  );
  Map<String,dynamic> toJson()=>{'type':type,'category':category,'amount':amount,'description':description,'date':date.toIso8601String(),'recognized':recognized};
}

class Commitment {
  final String id,title,status;
  final double amount;
  final DateTime dueDate;
  Commitment({required this.id,required this.title,required this.amount,required this.dueDate,required this.status});
  factory Commitment.fromJson(Map<String,dynamic> j)=>Commitment(
    id:j['id'].toString(), title:j['title'].toString(), amount:(j['amount'] as num).toDouble(),
    dueDate:DateTime.tryParse(j['due_date']?.toString() ?? '') ?? DateTime.now(), status:j['status'].toString(),
  );
  Map<String,dynamic> toJson()=>{'title':title,'amount':amount,'dueDate':dueDate.toIso8601String(),'status':status};
}

class SavingsGoal {
  final String id,title;
  final double targetAmount,savedAmount;
  SavingsGoal({required this.id,required this.title,required this.targetAmount,required this.savedAmount});
  factory SavingsGoal.fromJson(Map<String,dynamic> j)=>SavingsGoal(
    id:j['id'].toString(),title:j['title'].toString(),targetAmount:(j['target_amount'] as num).toDouble(),savedAmount:(j['saved_amount'] as num).toDouble(),
  );
  Map<String,dynamic> toJson()=>{'title':title,'targetAmount':targetAmount,'savedAmount':savedAmount};
}
