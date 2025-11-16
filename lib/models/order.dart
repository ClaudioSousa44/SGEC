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
  final String? photoUrl;

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
    this.photoUrl,
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
      date: _firstValidDate([
            json['data_recebimento'],
            json['receivedDate'],
            json['date'],
            json['data'],
          ]) ??
          DateTime.now(),
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
          ? _parseIsoDate(json['data_recebimento'])
          : json['receivedDate'] != null
              ? _parseIsoDate(json['receivedDate'])
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
      photoUrl: json['foto'] as String? ??
          json['photo'] as String? ??
          json['photo_url'] as String? ??
          json['foto_url'] as String?,
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
      'foto_url': photoUrl,
    };
  }

  // Método auxiliar para parse de datas em formato brasileiro
  static DateTime _parseDate(String dateStr) {
    try {
      // Tentar formato DD/MM/YYYY HH:mm:ss ou DD/MM/YYYY
      if (dateStr.contains('/')) {
        // Separar data e hora se existir
        final dateTimeParts = dateStr.split(' ');
        final datePart = dateTimeParts[0]; // "DD/MM/YYYY"
        final timePart = dateTimeParts.length > 1 ? dateTimeParts[1] : null; // "HH:mm:ss"
        
        final dateParts = datePart.split('/');
        if (dateParts.length == 3) {
          final day = int.parse(dateParts[0]);
          final month = int.parse(dateParts[1]);
          final year = int.parse(dateParts[2]);
          
          if (timePart != null) {
            // Parse da hora HH:mm:ss
            final timeParts = timePart.split(':');
            if (timeParts.length >= 3) {
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              final second = int.parse(timeParts[2]);
              return DateTime(year, month, day, hour, minute, second);
            } else if (timeParts.length == 2) {
              final hour = int.parse(timeParts[0]);
              final minute = int.parse(timeParts[1]);
              return DateTime(year, month, day, hour, minute);
            }
          }
          
          // Apenas data, sem hora
          return DateTime(year, month, day);
        }
      }
      // Tentar parse ISO
      return DateTime.parse(dateStr);
    } catch (e) {
      return DateTime.now();
    }
  }

  static DateTime? _parseIsoDate(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      final trimmedValue = value.trim();
      if (trimmedValue.isEmpty) {
        return null;
      }

      try {
        return DateTime.parse(trimmedValue);
      } catch (_) {
        // Tentar formatos alternativos (como DD/MM/YYYY)
        return _parseDate(trimmedValue);
      }
    }

    return null;
  }

  static DateTime? _firstValidDate(List<dynamic> candidates) {
    for (final candidate in candidates) {
      final parsed = _parseIsoDate(candidate);
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
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
