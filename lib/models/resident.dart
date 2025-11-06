/// Modelo de dados para Morador
class Resident {
  final int id;
  final String name;
  final String? cpf;
  final String? email;
  final String? phone;
  final int unitId; // ID da unidade (bloco + apartamento)

  Resident({
    required this.id,
    required this.name,
    this.cpf,
    this.email,
    this.phone,
    required this.unitId,
  });

  factory Resident.fromJson(Map<String, dynamic> json) {
    return Resident(
      id: json['id'] as int? ?? json['id_morador'] as int,
      name: json['nome'] as String? ?? json['name'] as String,
      cpf: json['cpf'] as String?,
      email: json['email'] as String?,
      phone: json['telefone'] as String? ?? json['phone'] as String?,
      unitId: json['id_unidade'] as int? ?? json['unitId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': name,
      'cpf': cpf,
      'email': email,
      'telefone': phone,
      'id_unidade': unitId,
    };
  }
}
