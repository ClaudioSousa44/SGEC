import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import '../models/order.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// Serviço para gerenciar requisições relacionadas a encomendas
class OrdersService {
  /// Busca todas as encomendas
  ///
  /// Parâmetros opcionais:
  /// - status: Filtrar por status ('Pendente', 'Entregue', etc)
  /// - search: Buscar por destinatário ou número de rastreamento
  static Future<List<Order>> getOrders({
    String? status,
    String? search,
  }) async {
    try {
      final token = await StorageService.getToken();

      // Construir query parameters
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty && status != 'Todas') {
        queryParams['status'] = status;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }

      final response = await ApiService.get(
        'encomendas',
        token: token,
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      // Verificar se os dados estão em 'data' ou diretamente na resposta
      List<dynamic> ordersData;
      if (response.containsKey('data')) {
        if (response['data'] is List) {
          ordersData = response['data'] as List;
        } else {
          ordersData = [];
        }
      } else if (response.containsKey('encomendas') &&
          response['encomendas'] is List) {
        ordersData = response['encomendas'] as List;
      } else {
        ordersData = [];
      }

      return ordersData
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiException('Erro ao buscar encomendas: ${e.toString()}');
    }
  }

  /// Busca uma encomenda específica por ID
  static Future<Order> getOrderById(int id) async {
    try {
      final token = await StorageService.getToken();

      final response = await ApiService.get(
        'encomendas/$id',
        token: token,
      );

      // Verificar se os dados estão em 'data'
      Map<String, dynamic> orderData;
      if (response.containsKey('data') && response['data'] is Map) {
        orderData = response['data'] as Map<String, dynamic>;
      } else {
        orderData = response;
      }

      return Order.fromJson(orderData);
    } catch (e) {
      throw ApiException('Erro ao buscar encomenda: ${e.toString()}');
    }
  }

  /// Atualiza o status de uma encomenda
  ///
  /// status pode ser: 'Entregue', 'Pendente', etc
  static Future<Order> updateOrderStatus(int orderId, String status) async {
    try {
      final token = await StorageService.getToken();

      final response = await ApiService.put(
        'encomendas/$orderId/status',
        {
          'status': status,
        },
        token: token,
      );

      // Verificar se os dados estão em 'data'
      Map<String, dynamic> orderData;
      if (response.containsKey('data') && response['data'] is Map) {
        orderData = response['data'] as Map<String, dynamic>;
      } else {
        orderData = response;
      }

      return Order.fromJson(orderData);
    } catch (e) {
      throw ApiException(
          'Erro ao atualizar status da encomenda: ${e.toString()}');
    }
  }

  /// Marca uma encomenda como entregue
  static Future<Order> markAsDelivered(int orderId) async {
    return await updateOrderStatus(orderId, 'Entregue');
  }

  /// Confirma a entrega enviando a assinatura para o backend
  static Future<Order> confirmDeliveryWithSignature({
    required int orderId,
    required Uint8List signatureBytes,
  }) async {
    try {
      final token = await StorageService.getToken();
      final user = await StorageService.getUser();

      if (user == null) {
        throw ApiException('Usuário não autenticado.');
      }

      final payload = {
        'id_porteiro_entrega': user.id,
        'assinatura': 'data:image/png;base64,${base64Encode(signatureBytes)}',
      };

      final response = await ApiService.post(
        'encomendas/$orderId/entrega',
        payload,
        token: token,
      );

      Map<String, dynamic> orderData;
      if (response.containsKey('data') && response['data'] is Map) {
        orderData = response['data'] as Map<String, dynamic>;
      } else {
        orderData = response;
      }

      return Order.fromJson(orderData);
    } catch (e) {
      throw ApiException('Erro ao confirmar entrega: ${e.toString()}');
    }
  }

  /// Cria uma nova encomenda (se necessário)
  static Future<Order> createOrder(Map<String, dynamic> orderData) async {
    try {
      final token = await StorageService.getToken();

      final response = await ApiService.post(
        'encomendas',
        orderData,
        token: token,
      );

      // Verificar se os dados estão em 'data'
      Map<String, dynamic> newOrderData;
      if (response.containsKey('data') && response['data'] is Map) {
        newOrderData = response['data'] as Map<String, dynamic>;
      } else {
        newOrderData = response;
      }

      return Order.fromJson(newOrderData);
    } catch (e) {
      throw ApiException('Erro ao criar encomenda: ${e.toString()}');
    }
  }

  /// Cria uma nova encomenda com foto
  static Future<Order> createOrderWithPhoto(
    Map<String, dynamic> orderData,
    File photoFile,
  ) async {
    try {
      print('📦 OrdersService.createOrderWithPhoto - Iniciando...');
      print('   Dados da encomenda: $orderData');
      print('   Arquivo de foto: ${photoFile.path}');
      print('   Arquivo existe: ${await photoFile.exists()}');
      
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) {
        print('❌ Token não encontrado ou vazio');
        print('   Verificando se usuário está salvo...');
        final user = await StorageService.getUser();
        if (user == null) {
          print('   Usuário também não está salvo');
          throw ApiException(
            'Você não está logado. Por favor, faça login novamente.',
          );
        } else {
          print('   Usuário encontrado: ${user.name}');
          throw ApiException(
            'Token de autenticação não encontrado. Por favor, faça login novamente.',
          );
        }
      }
      print('   Token encontrado: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');

      // Converter campos para String (necessário para multipart)
      // IMPORTANTE: null não deve ser enviado (backend trata como undefined)
      final fields = <String, String>{};
      orderData.forEach((key, value) {
        if (value != null) {
          // Converter para string apenas se não for null
          final stringValue = value.toString();
          // Sempre adicionar campos obrigatórios, mesmo se vazios
          // Campos opcionais (codigo_rastreio, descricao) só adicionar se não vazios
          if (key == 'codigo_rastreio' || key == 'descricao') {
            // Campos opcionais: só enviar se tiver valor
            if (stringValue.isNotEmpty) {
              fields[key] = stringValue;
            }
          } else {
            // Campos obrigatórios: sempre enviar
            fields[key] = stringValue;
          }
        }
        // Se value for null, não adicionar ao fields (será undefined no backend)
      });
      print('═══════════════════════════════════════════════════════════');
      print('📦 PAYLOAD - Dados da Encomenda');
      print('═══════════════════════════════════════════════════════════');
      print('📋 Dados originais (orderData):');
      orderData.forEach((key, value) {
        if (value == null) {
          print('   $key: null');
        } else {
          print('   $key: "$value" (${value.runtimeType})');
        }
      });
      print('📤 Campos que serão enviados (fields):');
      fields.forEach((key, value) {
        print('   $key: "$value"');
      });
      final omittedFields = orderData.keys.where((k) => 
        orderData[k] == null || 
        (orderData[k] != null && orderData[k].toString().isEmpty && (k == 'codigo_rastreio' || k == 'descricao'))
      ).toList();
      if (omittedFields.isNotEmpty) {
        print('⚠️ Campos omitidos (não serão enviados): $omittedFields');
      }
      print('═══════════════════════════════════════════════════════════');

      print('📤 Enviando requisição multipart...');
      final response = await ApiService.postMultipart(
        'encomendas',
        fields,
        token: token,
        fileFieldName: 'foto',
        file: photoFile,
      );
      print('✅ Resposta recebida: ${response.keys}');

      // Verificar se os dados estão em 'data'
      Map<String, dynamic> newOrderData;
      if (response.containsKey('data') && response['data'] is Map) {
        newOrderData = response['data'] as Map<String, dynamic>;
        print('   Dados extraídos de response["data"]');
      } else {
        newOrderData = response;
        print('   Usando resposta completa como dados');
      }

      print('📋 Criando objeto Order a partir dos dados...');
      final order = Order.fromJson(newOrderData);
      print('✅ Order criado com sucesso! ID: ${order.id}');
      
      return order;
    } catch (e, stackTrace) {
      print('❌ ERRO em OrdersService.createOrderWithPhoto:');
      print('   Tipo: ${e.runtimeType}');
      print('   Mensagem: ${e.toString()}');
      print('   Stack Trace: $stackTrace');
      throw ApiException('Erro ao criar encomenda com foto: ${e.toString()}');
    }
  }
}
