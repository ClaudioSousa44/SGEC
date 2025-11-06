/// Modelo de dados para Unidade (Bloco + Apartamento)
class Unit {
  final int id;
  final String block;
  final String apartment;
  final String? description; // Ex: "Apto 101 - Bloco A"

  Unit({
    required this.id,
    required this.block,
    required this.apartment,
    this.description,
  });

  factory Unit.fromJson(Map<String, dynamic> json) {
    final block = json['bloco'] as String? ?? json['block'] as String;
    final apartment = (json['apartamento'] as String?) ??
        (json['apartment'] as String?) ??
        (json['apto'] as String? ?? '');

    return Unit(
      id: json['id'] as int? ?? json['id_unidade'] as int,
      block: block,
      apartment: apartment,
      description: json['descricao'] as String? ??
          (json['description'] as String?) ??
          '$block - $apartment',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bloco': block,
      'apartamento': apartment,
      'descricao': description,
    };
  }

  // Método para exibir a unidade formatada
  String get displayName {
    return description ?? '$block - $apartment';
  }
}
