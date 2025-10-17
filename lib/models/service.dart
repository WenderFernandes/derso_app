/// Representa um serviço realizado pelo policial no programa DERSO.
class Service {
  final int? id;
  final DateTime date; // Data do serviço
  final String startTime; // Hora inicial (HH:mm)
  final String endTime; // Hora final (HH:mm)
  final String period; // manhã, tarde ou noite
  final double value; // Valor único do serviço
  final bool realized; // Se o serviço foi realizado
  final DateTime? paymentDate; // Data em que o serviço foi pago, caso exista
  final int userId; // Chave estrangeira para o usuário que criou o serviço

  Service({
    this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.period,
    required this.value,
    required this.realized,
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
      paymentDate: map['paymentDate'] != null && map['paymentDate'] != ''
          ? DateTime.parse(map['paymentDate'] as String)
          : null,
      userId: map['userId'] as int,
    );
  }
}