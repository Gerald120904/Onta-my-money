import 'dart:convert';

enum ConflictResolutionStrategy {
  clientWins,
  serverWins,
  merge,
}

class EntityConflict {
  final String id;
  final String userId;
  final String entityType;
  final String entityId;
  final int baseVersion;
  final int serverVersion;
  final Map<String, dynamic> clientPayload;
  final Map<String, dynamic> serverPayload;
  final String status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  EntityConflict({
    required this.id,
    required this.userId,
    required this.entityType,
    required this.entityId,
    required this.baseVersion,
    required this.serverVersion,
    required this.clientPayload,
    required this.serverPayload,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  factory EntityConflict.fromDb({
    required String id,
    required String userId,
    required String entityType,
    required String entityId,
    required int baseVersion,
    required int serverVersion,
    required String clientPayloadJson,
    required String serverPayloadJson,
    required String status,
    required DateTime createdAt,
    DateTime? resolvedAt,
  }) {
    Map<String, dynamic> cPayload = {};
    Map<String, dynamic> sPayload = {};
    try {
      cPayload =
          Map<String, dynamic>.from(jsonDecode(clientPayloadJson) as Map);
    } catch (_) {}
    try {
      sPayload =
          Map<String, dynamic>.from(jsonDecode(serverPayloadJson) as Map);
    } catch (_) {}

    return EntityConflict(
      id: id,
      userId: userId,
      entityType: entityType,
      entityId: entityId,
      baseVersion: baseVersion,
      serverVersion: serverVersion,
      clientPayload: cPayload,
      serverPayload: sPayload,
      status: status,
      createdAt: createdAt,
      resolvedAt: resolvedAt,
    );
  }
}
