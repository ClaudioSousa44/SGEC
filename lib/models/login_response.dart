class LoginResponse {
  final String? token;
  final User? user;
  final String? message;
  final bool success;

  LoginResponse({
    this.token,
    this.user,
    this.message,
    required this.success,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    // Log detalhado da resposta
    print('🔍 LoginResponse.fromJson - Analisando resposta:');
    print('   JSON completo: $json');
    print('   Chaves disponíveis: ${json.keys.toList()}');
    
    // Verificar se os dados estão dentro de um campo 'data'
    Map<String, dynamic>? data;
    if (json.containsKey('data') && json['data'] is Map<String, dynamic>) {
      data = json['data'] as Map<String, dynamic>;
      print('   ✅ Campo "data" encontrado: ${data.keys.toList()}');
    } else {
      print('   ⚠️ Campo "data" não encontrado ou não é Map');
    }

    // Verificar sucesso: pode vir como 'status' == "success" ou 'success' == true
    final status = json['status'] as String?;
    final successBool = json['success'] as bool?;
    final success = status == 'success' ||
        successBool == true ||
        (data != null && status != 'error');
    
    print('   Status: $status');
    print('   Success bool: $successBool');
    print('   Success calculado: $success');

    // Buscar token em múltiplos lugares possíveis
    String? token;
    
    // Tentar 1: data.token
    if (data != null && data.containsKey('token')) {
      token = data['token'] as String?;
      print('   ✅ Token encontrado em data.token: ${token != null ? "${token.substring(0, token.length > 20 ? 20 : token.length)}..." : "null"}');
    }
    
    // Tentar 2: json.token
    if (token == null && json.containsKey('token')) {
      token = json['token'] as String?;
      print('   ✅ Token encontrado em json.token: ${token != null ? "${token.substring(0, token.length > 20 ? 20 : token.length)}..." : "null"}');
    }
    
    // Tentar 3: data.access_token
    if (token == null && data != null && data.containsKey('access_token')) {
      token = data['access_token'] as String?;
      print('   ✅ Token encontrado em data.access_token: ${token != null ? "${token.substring(0, token.length > 20 ? 20 : token.length)}..." : "null"}');
    }
    
    // Tentar 4: json.access_token
    if (token == null && json.containsKey('access_token')) {
      token = json['access_token'] as String?;
      print('   ✅ Token encontrado em json.access_token: ${token != null ? "${token.substring(0, token.length > 20 ? 20 : token.length)}..." : "null"}');
    }
    
    if (token == null) {
      print('   ❌ Token NÃO encontrado em nenhum lugar!');
      print('   Verificando todos os campos disponíveis...');
      if (data != null) {
        print('   Campos em data: ${data.keys.toList()}');
        data.forEach((key, value) {
          if (key.toLowerCase().contains('token') || key.toLowerCase().contains('auth')) {
            print('     ⚠️ Campo suspeito "$key": $value');
          }
        });
      }
    }

    // Buscar dados do usuário
    User? user;
    if (data != null) {
      // Se os dados estão diretamente no 'data', criar User a partir deles
      if (data.containsKey('id_funcionario') || data.containsKey('id')) {
        user = User.fromJson(data);
      } else if (data.containsKey('user') &&
          data['user'] is Map<String, dynamic>) {
        user = User.fromJson(data['user'] as Map<String, dynamic>);
      }
    } else if (json.containsKey('user') &&
        json['user'] is Map<String, dynamic>) {
      user = User.fromJson(json['user'] as Map<String, dynamic>);
    }

    return LoginResponse(
      token: token,
      user: user,
      message: json['message'] as String?,
      success: success,
    );
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String? role;
  final String? cpf;
  final String? telefone;
  final String? celular;
  final String? endereco;
  final String? numero;
  final String? complemento;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final String? cep;
  final String? turnoInicio;
  final String? turnoFim;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.role,
    this.cpf,
    this.telefone,
    this.celular,
    this.endereco,
    this.numero,
    this.complemento,
    this.bairro,
    this.cidade,
    this.estado,
    this.cep,
    this.turnoInicio,
    this.turnoFim,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // A API retorna id_funcionario, nome, tipo_usuario
    // Mas também pode retornar id, name, role
    return User(
      id: json['id_funcionario'] as int? ?? json['id'] as int,
      name: json['nome'] as String? ?? json['name'] as String,
      email: json['email'] as String,
      role: json['tipo_usuario'] as String? ?? json['role'] as String?,
      cpf: json['cpf'] as String?,
      telefone: json['telefone'] as String?,
      celular: json['celular'] as String?,
      endereco: json['endereco'] as String?,
      numero: json['numero'] as String?,
      complemento: json['complemento'] as String?,
      bairro: json['bairro'] as String?,
      cidade: json['cidade'] as String?,
      estado: json['estado'] as String?,
      cep: json['cep'] as String?,
      turnoInicio: json['turno_inicio'] as String?,
      turnoFim: json['turno_fim'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'cpf': cpf,
      'telefone': telefone,
      'celular': celular,
      'endereco': endereco,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
      'cep': cep,
      'turno_inicio': turnoInicio,
      'turno_fim': turnoFim,
    };
  }

  // Método auxiliar para formatar o endereço completo
  String get enderecoCompleto {
    final parts = <String>[];
    if (endereco != null && endereco!.isNotEmpty) parts.add(endereco!);
    if (numero != null && numero!.isNotEmpty) parts.add('nº $numero');
    if (complemento != null && complemento!.isNotEmpty) parts.add(complemento!);
    if (bairro != null && bairro!.isNotEmpty) parts.add(bairro!);
    if (cidade != null && cidade!.isNotEmpty) parts.add(cidade!);
    if (estado != null && estado!.isNotEmpty) parts.add(estado!);
    if (cep != null && cep!.isNotEmpty) parts.add('CEP: $cep');
    return parts.join(', ');
  }

  // Método auxiliar para formatar o turno
  String get turnoFormatado {
    if (turnoInicio != null && turnoFim != null) {
      return '${_formatTime(turnoInicio!)} - ${_formatTime(turnoFim!)}';
    }
    return 'Não informado';
  }

  String _formatTime(String time) {
    // Formata TIME do MySQL (HH:MM:SS) para HH:MM
    if (time.contains(':')) {
      final parts = time.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
    }
    return time;
  }
}
