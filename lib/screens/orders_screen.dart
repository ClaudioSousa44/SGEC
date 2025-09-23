import 'package:flutter/material.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'Todas';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Lista de encomendas de exemplo
  final List<Map<String, dynamic>> _orders = [
    {
      'id': '1',
      'recipient': 'Ana Silva',
      'date': '15/07/2024',
      'status': 'Pendente',
    },
    {
      'id': '2',
      'recipient': 'Carlos Pereira',
      'date': '14/07/2024',
      'status': 'Entregue',
    },
    {
      'id': '3',
      'recipient': 'Beatriz Costa',
      'date': '13/07/2024',
      'status': 'Pendente',
    },
    {
      'id': '4',
      'recipient': 'Daniel Santos',
      'date': '12/07/2024',
      'status': 'Entregue',
    },
    {
      'id': '5',
      'recipient': 'Fernanda Lima',
      'date': '11/07/2024',
      'status': 'Pendente',
    },
  ];

  List<Map<String, dynamic>> get _filteredOrders {
    List<Map<String, dynamic>> filtered = _orders;

    // Filtrar por status
    if (_selectedFilter != 'Todas') {
      filtered = filtered
          .where((order) => order['status'] == _selectedFilter)
          .toList();
    }

    // Filtrar por pesquisa
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((order) => order['recipient']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()))
          .toList();
    }

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
            child: Row(
              children: [
                _buildFilterButton('Todas'),
                const SizedBox(width: 12),
                _buildFilterButton('Entregues'),
                const SizedBox(width: 12),
                _buildFilterButton('Pendentes'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Lista de encomendas
          Expanded(
            child: _filteredOrders.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhuma encomenda encontrada',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF7F8C8D),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = _filteredOrders[index];
                      return _buildOrderCard(order);
                    },
                  ),
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

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final isDelivered = order['status'] == 'Entregue';

    return Container(
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
                  order['recipient'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2C3E50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Recebido em ${order['date']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF7F8C8D),
                  ),
                ),
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
                Text(
                  order['status'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDelivered
                        ? const Color(0xFF2E7D32)
                        : const Color(0xFFF57C00),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
