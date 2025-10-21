import 'package:flutter/material.dart';

/// Representa um serviço realizado pelo policial no programa DERSO.
class Service {
  final int? id;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String period;
  final double value;
  final bool realized;
  final bool received;
  final DateTime? paymentDate;
  final int userId;
  final NotificationPreference notificationPreference;

  Service({
    this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.period,
    required this.value,
    this.realized = false,
    this.received = false,
    this.paymentDate,
    required this.userId,
    this.notificationPreference = NotificationPreference.oneHourBefore,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'startTime': startTime,
      'endTime': endTime,
      'period': period,
      'value': value,
      'realized': realized ? 1 : 0,
      'received': received ? 1 : 0,
      'paymentDate': paymentDate?.toIso8601String(),
      'userId': userId,
      'notificationPreference': notificationPreference.index,
    };
  }

  factory Service.fromMap(Map<String, dynamic> map) {
    return Service(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      period: map['period'] as String,
      value: (map['value'] as num).toDouble(),
      realized: (map['realized'] as int) == 1,
      received: (map['received'] as int? ?? 0) == 1,
      paymentDate: map['paymentDate'] != null && map['paymentDate'] != ''
          ? DateTime.parse(map['paymentDate'] as String)
          : null,
      userId: map['userId'] as int,
      notificationPreference: NotificationPreference.values[
        map['notificationPreference'] as int? ?? 0
      ],
    );
  }

  Service copyWith({
    int? id,
    DateTime? date,
    String? startTime,
    String? endTime,
    String? period,
    double? value,
    bool? realized,
    bool? received,
    DateTime? paymentDate,
    int? userId,
    NotificationPreference? notificationPreference,
  }) {
    return Service(
      id: id ?? this.id,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      period: period ?? this.period,
      value: value ?? this.value,
      realized: realized ?? this.realized,
      received: received ?? this.received,
      paymentDate: paymentDate ?? this.paymentDate,
      userId: userId ?? this.userId,
      notificationPreference: notificationPreference ?? this.notificationPreference,
    );
  }
}

enum NotificationPreference {
  oneHourBefore,
  twoHoursBefore,
  threeHoursBefore,
  oneDayBefore,
  sameDay,
}

extension NotificationPreferenceExtension on NotificationPreference {
  String get label {
    switch (this) {
      case NotificationPreference.oneHourBefore:
        return '1 hora antes';
      case NotificationPreference.twoHoursBefore:
        return '2 horas antes';
      case NotificationPreference.threeHoursBefore:
        return '3 horas antes';
      case NotificationPreference.oneDayBefore:
        return '1 dia antes';
      case NotificationPreference.sameDay:
        return 'No mesmo dia (8h)';
    }
  }

  Duration get duration {
    switch (this) {
      case NotificationPreference.oneHourBefore:
        return const Duration(hours: 1);
      case NotificationPreference.twoHoursBefore:
        return const Duration(hours: 2);
      case NotificationPreference.threeHoursBefore:
        return const Duration(hours: 3);
      case NotificationPreference.oneDayBefore:
        return const Duration(days: 1);
      case NotificationPreference.sameDay:
        return const Duration(hours: 0);
    }
  }
}