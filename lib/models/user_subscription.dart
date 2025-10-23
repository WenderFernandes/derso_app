class UserSubscription {
  final int? id;
  final int userId;
  final String planId;
  final DateTime startDate;
  final DateTime endDate;
  final SubscriptionStatus status;
  final String? purchaseToken;
  final DateTime? canceledAt;

  UserSubscription({
    this.id,
    required this.userId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.purchaseToken,
    this.canceledAt,
  });

  bool get isActive {
    return status == SubscriptionStatus.active && 
           DateTime.now().isBefore(endDate);
  }

  bool get isExpired {
    return DateTime.now().isAfter(endDate);
  }

  int get remainingDays {
    if (isExpired) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'planId': planId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status.index,
      'purchaseToken': purchaseToken,
      'canceledAt': canceledAt?.toIso8601String(),
    };
  }

  factory UserSubscription.fromMap(Map<String, dynamic> map) {
    return UserSubscription(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      planId: map['planId'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      status: SubscriptionStatus.values[map['status'] as int],
      purchaseToken: map['purchaseToken'] as String?,
      canceledAt: map['canceledAt'] != null && map['canceledAt'] != ''
          ? DateTime.parse(map['canceledAt'] as String)
          : null,
    );
  }

  UserSubscription copyWith({
    int? id,
    int? userId,
    String? planId,
    DateTime? startDate,
    DateTime? endDate,
    SubscriptionStatus? status,
    String? purchaseToken,
    DateTime? canceledAt,
  }) {
    return UserSubscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      canceledAt: canceledAt ?? this.canceledAt,
    );
  }
}

enum SubscriptionStatus {
  active,
  expired,
  canceled,
}