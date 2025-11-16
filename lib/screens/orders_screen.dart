import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/orders_service.dart';
import 'order_details_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Todas';
  final TextEditingController _searchController = TextEditingController();

  List<Order> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Mapear o filtro selecionado para o status esperado pela API
      String? statusFilter;
      if (_selectedFilter == 'Entregues') {
        statusFilter = 'Entregue';
      } else if (_selectedFilter == 'Pendentes') {
        statusFilter = 'Aguardando retirada';
      }
      // Se for 'Todas', statusFilter fica null para buscar todas

      final orders = await OrdersService.getOrders(
        status: statusFilter,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      if (!mounted) return;

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshOrders() async {
    await _loadOrders();
  }

  List<Order> get _filteredOrders {
    // A filtragem por status já é feita pela API
    // Apenas fazer filtro local de pesquisa se necessário
    List<Order> filtered = _orders;

    // Filtrar por pesquisa localmente (caso a API não suporte ou como backup)
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((order) =>
              order.recipient
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              order.orderNumber
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    // Também aplicar filtro de status localmente como backup
    // (caso a API não tenha filtrado corretamente)
    if (_selectedFilter != 'Todas') {
      final statusToFilter =
          _selectedFilter == 'Entregues' ? 'Entregue' : 'Aguardando retirada';
      filtered = filtered
          .where((order) =>
              order.status.toLowerCase() == statusToFilter.toLowerCase())
          .toList();
    }

    // Ordenar por data (mais recente primeiro)
    filtered.sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Encomendas',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Focar na barra de pesquisa
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            icon: const Icon(
              Icons.search,
              color: Color(0xFF2C3E50),
            ),
          ),
          IconButton(
            onPressed: () {
              // Implementar configurações
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Configurações em breve!'),
                ),
              );
            },
            icon: const Icon(
              Icons.settings,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  // Debounce: buscar após 500ms sem digitar
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_searchQuery == value && mounted) {
                      _loadOrders();
                    }
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Pesquisar encomendas',
                  hintStyle: TextStyle(
                    color: Color(0xFF7F8C8D),
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Color(0xFF7F8C8D),
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),

          // Filtros
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterButton('Todas'),
                  const SizedBox(width: 12),
                  _buildFilterButton('Pendentes'),
                  const SizedBox(width: 12),
                  _buildFilterButton('Entregues'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Lista de encomendas
          Expanded(
            child: _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String filter) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = filter;
        });
        _loadOrders();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          filter,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF7F8C8D),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildOrdersList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFF7F8C8D),
            ),
            const SizedBox(height: 16),
            Text(
              'Erro ao carregar encomendas',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7F8C8D),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadOrders,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
              ),
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    if (_filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Color(0xFF7F8C8D),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma encomenda encontrada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Puxe para baixo para atualizar',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF7F8C8D),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      key: _refreshIndicatorKey,
      onRefresh: _refreshOrders,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _filteredOrders.length,
        itemBuilder: (context, index) {
          final order = _filteredOrders[index];
          return _buildOrderCard(order);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final isDelivered = order.isDelivered;

    return GestureDetector(
      onTap: () {
        _navigateToOrderDetails(order);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ícone do pacote
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2,
                color: Color(0xFF2196F3),
                size: 24,
              ),
            ),

            const SizedBox(width: 16),

            // Informações da encomenda
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.recipient,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2C3E50),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.block} - ${order.apartment} | Recebido em ${order.formattedDate}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7F8C8D),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  if (order.orderNumber.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Rastreamento: ${order.orderNumber}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF7F8C8D),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ],
              ),
            ),

            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDelivered
                    ? const Color(0xFFE8F5E8)
                    : const Color(0xFFFFF3CD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDelivered
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFFFC107),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      order.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDelivered
                            ? const Color(0xFF2E7D32)
                            : const Color(0xFFF57C00),
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Ícone de seta para indicar que é clicável
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF7F8C8D),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToOrderDetails(Order order) {
    // Converter Order para Map para compatibilidade com OrderDetailsScreen
    final orderMap = {
      'id': order.id.toString(),
      'orderNumber': order.orderNumber,
      'recipient': order.recipient,
      'date': order.formattedDate,
      'status': order.status,
      'block': order.block,
      'apartment': order.apartment,
      'receivedBy': order.receivedBy,
      'receivedDate': order.receivedDate?.toString() ?? order.date.toString(),
      'observations': order.observations,
      'transportCompany': order.transportCompany,
      'trackingCode': order.trackingCode,
      'photoUrl': order.photoUrl,
    };

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(order: orderMap),
      ),
    )
        .then((_) {
      // Recarregar encomendas quando voltar da tela de detalhes
      // (caso o status tenha sido alterado)
      _loadOrders();
    });
  }
}
