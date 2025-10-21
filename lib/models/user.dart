class User {
  final int? id;
  final String name;
  final String nickName;
  final String matricula;
  final String cpf;
  final String email;
  final String password;
  final DateTime? trialStartDate;
  final bool isPremium;

  User({
    this.id,
    required this.name,
    required this.nickName,
    required this.matricula,
    required this.cpf,
    required this.email,
    required this.password,
    this.trialStartDate,
    this.isPremium = false,
  });

  bool get isTrialActive {
    if (isPremium) return true;
    if (trialStartDate == null) return true;
    
    final daysSinceStart = DateTime.now().difference(trialStartDate!).inDays;
    return daysSinceStart <= 10;
  }

  int get remainingTrialDays {
    if (isPremium) return -1;
    if (trialStartDate == null) return 10;
    
    final daysSinceStart = DateTime.now().difference(trialStartDate!).inDays;
    final remaining = 10 - daysSinceStart;
    return remaining > 0 ? remaining : 0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nickName': nickName,
      'matricula': matricula,
      'cpf': cpf,
      'email': email,
      'password': password,
      'trialStartDate': trialStartDate?.toIso8601String(),
      'isPremium': isPremium ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      nickName: map['nickName'] as String,
      matricula: map['matricula'] as String,
      cpf: map['cpf'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
      trialStartDate: map['trialStartDate'] != null && map['trialStartDate'] != ''
          ? DateTime.parse(map['trialStartDate'] as String)
          : null,
      isPremium: (map['isPremium'] as int? ?? 0) == 1,
    );
  }

  User copyWith({
    int? id,
    String? name,
    String? nickName,
    String? matricula,
    String? cpf,
    String? email,
    String? password,
    DateTime? trialStartDate,
    bool? isPremium,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      nickName: nickName ?? this.nickName,
      matricula: matricula ?? this.matricula,
      cpf: cpf ?? this.cpf,
      email: email ?? this.email,
      password: password ?? this.password,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}