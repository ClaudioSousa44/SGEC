/// Configurações da API
///
/// Aqui você pode configurar a URL base da API e outras configurações globais
class ApiConfig {
  // TODO: Substitua pela URL base da sua API
  static const String baseUrl = 'http://localhost:3000/';

  // Timeout padrão para requisições (em segundos)
  static const int timeoutSeconds = 30;

  // Endpoints da API
  static const String loginEndpoint = 'auth/login';

  // Endpoints de Encomendas
  static const String ordersEndpoint = 'encomendas';
  static const String ordersListEndpoint = 'encomendas/listar';
  static const String orderUpdateStatusEndpoint = 'encomendas/status';

  // Endpoints de Moradores e Unidades
  static const String residentsEndpoint = 'moradores';
  static const String unitsEndpoint = 'unidades';
}
