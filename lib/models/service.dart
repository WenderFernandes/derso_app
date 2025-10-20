/// Representa um serviço realizado pelo policial no programa DERSO.
class Service {
  final int? id;
  final DateTime date;
  final String startTime;
  final String endTime;
  final String period;
  final double value;
  final bool realized;
  final bool received; // Nova flag para controle de recebimento
  final DateTime? paymentDate;
  final int userId;

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
    );
  }
}