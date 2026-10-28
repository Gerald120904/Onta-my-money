class ReviewResult {
  final DateTime start;
  final DateTime end;

  final String periodTitle;
  final String periodSubtitle;

  final List<String> transactionIds;

  final String decision;

  /// Información adicional de la decisión.
  ///
  /// Ejemplos:
  ///
  /// Reducir gasto:
  /// {
  ///   'category': 'Ocio',
  ///   'targetAmount': 15000,
  ///   'periodType': 'weeks',
  ///   'periodValue': 4,
  /// }
  ///
  /// Posponer compra:
  /// {
  ///   'purchaseName': 'Audífonos',
  ///   'purchaseAmount': 45000,
  ///   'targetDate': '2026-10-30T00:00:00.000',
  /// }
  final Map<String, dynamic> decisionDetails;

  final DateTime createdAt;

  const ReviewResult({
    required this.start,
    required this.end,
    required this.periodTitle,
    required this.periodSubtitle,
    required this.transactionIds,
    required this.decision,
    this.decisionDetails = const <String, dynamic>{},
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
      'periodTitle': periodTitle,
      'periodSubtitle': periodSubtitle,
      'transactionIds': transactionIds,
      'decision': decision,
      'decisionDetails': decisionDetails,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReviewResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawDetails = json['decisionDetails'];

    Map<String, dynamic> details = {};

    if (rawDetails is Map) {
      details = Map<String, dynamic>.from(
        rawDetails,
      );
    }

    return ReviewResult(
      start: DateTime.parse(
        json['start'].toString(),
      ),
      end: DateTime.parse(
        json['end'].toString(),
      ),
      periodTitle: json['periodTitle']?.toString() ?? '',
      periodSubtitle: json['periodSubtitle']?.toString() ?? '',
      transactionIds: (json['transactionIds'] as List? ?? [])
          .map(
            (item) => item.toString(),
          )
          .toList(),
      decision: json['decision']?.toString() ?? 'Mantener mi plan',
      decisionDetails: details,
      createdAt: DateTime.parse(
        json['createdAt'].toString(),
      ),
    );
  }
}
