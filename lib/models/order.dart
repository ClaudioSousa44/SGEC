/// Modelo de dados para Encomenda
class Order {
  final int id;
  final String orderNumber;
  final String recipient;
  final DateTime date;
  final String status;
  final String block;
  final String apartment;
  final String? receivedBy;
  final DateTime? receivedDate;
  final String? observations;
  final String? transportCompany;
  final String? trackingCode;

  Order({
    required this.id,
    required this.orderNumber,
    required this.recipient,
    required this.date,
    required this.status,
    required this.block,
    required this.apartment,
    this.receivedBy,
    this.receivedDate,
    this.observations,
    this.transportCompany,
    this.trackingCode,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as int? ?? json['id_encomenda'] as int,
      orderNumber: json['numero_rastreamento'] as String? ??
          json['orderNumber'] as String? ??
          json['numero'] as String? ??
          '',
      recipient: json['destinatario'] as String? ??
          json['recipient'] as String? ??
          json['nome_destinatario'] as String? ??
          '',
      date: json['data_recebimento'] != null
          ? DateTime.parse(json['data_recebimento'] as String)
          : json['date'] != null
              ? DateTime.parse(json['date'] as String)
              : json['data'] != null
                  ? _parseDate(json['data'] as String)
                  : DateTime.now(),
      status: json['status'] as String? ?? 'Pendente',
      block: json['bloco'] as String? ?? json['block'] as String? ?? '',
      apartment: json['apartamento'] as String? ??
          json['apartment'] as String? ??
          json['apto'] as String? ??
          '',
      receivedBy: json['recebido_por'] as String? ??
          json['receivedBy'] as String? ??
          json['funcionario'] as String?,
      receivedDate: json['data_recebimento'] != null
          ? DateTime.parse(json['data_recebimento'] as String)
          : json['receivedDate'] != null
              ? DateTime.parse(json['receivedDate'] as String)
              : null,
      observations: json['observacoes'] as String? ??
          json['observations'] as String? ??
          json['observacao'] as String?,
      transportCompany: json['transportadora'] as String? ??
          json['transportCompany'] as String? ??
          json['empresa'] as String?,
      trackingCode: json['codigo_rastreamento'] as String? ??
          json['trackingCode'] as String? ??
          json['codigo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero_rastreamento': orderNumber,
      'destinatario': recipient,
      'data_recebimento': date.toIso8601String(),
      'status': status,
      'bloco': block,
      'apartamento': apartment,
      'recebido_por': receivedBy,
      'data_entrega': receivedDate?.toIso8601String(),
      'observacoes': observations,
      'transportadora': transportCompany,
      'codigo_rastreamento': trackingCode,
    };
  }

  // Método auxiliar para parse de datas em formato brasileiro
  static DateTime _parseDate(String dateStr) {
    try {
      // Tentar formato DD/MM/YYYY
      if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
      // Tentar parse ISO
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime.now();
    }
  }

  // Método auxiliar para formatar data
  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Método auxiliar para verificar se está entregue
  bool get isDelivered =>
      status.toLowerCase() == 'entregue' || status.toLowerCase() == 'delivered';

  // Método auxiliar para verificar se está pendente
  bool get isPending =>
      status.toLowerCase() == 'pendente' || status.toLowerCase() == 'pending';
}
