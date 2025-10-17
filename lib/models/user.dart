/// Representa um policial cadastrado no aplicativo DERSO.
class User {
  final int? id;
  final String name;
  final String nickName;
  final String matricula;
  final String cpf;
  final String email;
  final String password;

  User({
    this.id,
    required this.name,
    required this.nickName,
    required this.matricula,
    required this.cpf,
    required this.email,
    required this.password,
  });

  // Converte o usuário em um mapa para ser salvo no banco de dados SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'nickName': nickName,
      'matricula': matricula,
      'cpf': cpf,
      'email': email,
      'password': password,
    };
  }

  // Cria uma instância de User a partir de um mapa retornado pelo banco.
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      name: map['name'] as String,
      nickName: map['nickName'] as String,
      matricula: map['matricula'] as String,
      cpf: map['cpf'] as String,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }
}