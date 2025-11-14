import 'package:flutter/material.dart';
import '../models/resident.dart';
import '../models/unit.dart';
import '../services/residents_service.dart';
import '../services/orders_service.dart';
import '../services/storage_service.dart';

class ManualRegisterScreen extends StatefulWidget {
  const ManualRegisterScreen({super.key});

  @override
  State<ManualRegisterScreen> createState() => _ManualRegisterScreenState();
}

class _ManualRegisterScreenState extends State<ManualRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _trackingCodeController = TextEditingController();

  List<Resident> _residents = [];
  List<Unit> _units = [];
  List<Unit> _filteredUnits = [];

  Resident? _selectedResident;
  String? _selectedBlock;
  Unit? _selectedUnit;

  bool _isLoadingResidents = true;
  bool _isLoadingUnits = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _trackingCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingResidents = true;
      _isLoadingUnits = true;
    });

    try {
      final residents = await ResidentsService.getResidents();
      final units = await ResidentsService.getUnits();

      setState(() {
        _residents = residents;
        _units = units;
        _filteredUnits = units;
        _isLoadingResidents = false;
        _isLoadingUnits = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingResidents = false;
        _isLoadingUnits = false;
      });

      // Mostrar erro se houver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar dados: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF5722),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onBlockChanged(String? block) {
    setState(() {
      _selectedBlock = block;
      _selectedUnit = null; // Resetar unidade quando mudar o bloco

      if (block != null) {
        _filteredUnits = _units.where((unit) => unit.block == block).toList();
      } else {
        _filteredUnits = _units;
      }
    });
  }

  void _onUnitChanged(Unit? unit) {
    setState(() {
      _selectedUnit = unit;
      // Não desmarcar morador ao selecionar unidade
      // Apenas atualizar a unidade selecionada
    });
  }

  void _onResidentChanged(Resident? resident) {
    setState(() {
      _selectedResident = resident;
      // Se selecionar um morador, preencher automaticamente a unidade
      if (resident != null) {
        final unit = _units.firstWhere(
          (u) => u.id == resident.unitId,
          orElse: () => _units.first,
        );
        _selectedUnit = unit;
        _selectedBlock = unit.block;
        _onBlockChanged(unit.block);
      }
    });
  }

  // Obter lista única de blocos
  List<String> get _blocks {
    final blocks = _units.map((u) => u.block).toSet().toList();
    blocks.sort();
    return blocks;
  }

  // Obter moradores da unidade selecionada
  List<Resident> get _residentsInUnit {
    if (_selectedUnit == null) return _residents;
    return _residents.where((r) => r.unitId == _selectedUnit!.id).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Color(0xFF2C3E50),
          ),
        ),
        title: const Text(
          'Cadastro Manual',
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Select de Morador
              const Text(
                'Morador',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              _isLoadingResidents
                  ? const SizedBox(
                      height: 48,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                      ),
                      child: DropdownButtonFormField<Resident>(
                        value: _selectedResident,
                        decoration: InputDecoration(
                          hintText: 'Selecione o morador',
                          hintStyle: const TextStyle(
                            color: Color(0xFF7F8C8D),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2196F3),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: _residents.map((resident) {
                          return DropdownMenuItem<Resident>(
                            value: resident,
                            child: Text(resident.name),
                          );
                        }).toList(),
                        onChanged: _onResidentChanged,
                        validator: (value) {
                          if (value == null) {
                            return 'Morador é obrigatório';
                          }
                          return null;
                        },
                      ),
                    ),

              const SizedBox(height: 20),

              // Select de Bloco
              const Text(
                'Bloco',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              _isLoadingUnits
                  ? const SizedBox(
                      height: 48,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                      ),
                      child: DropdownButtonFormField<String>(
                        value: _selectedBlock,
                        decoration: InputDecoration(
                          hintText: 'Selecione o bloco',
                          hintStyle: const TextStyle(
                            color: Color(0xFF7F8C8D),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2196F3),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: _blocks.map((block) {
                          return DropdownMenuItem<String>(
                            value: block,
                            child: Text(block),
                          );
                        }).toList(),
                        onChanged: _onBlockChanged,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Bloco é obrigatório';
                          }
                          return null;
                        },
                      ),
                    ),

              const SizedBox(height: 20),

              // Select de Apartamento (Unidade)
              const Text(
                'Apartamento',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              _isLoadingUnits
                  ? const SizedBox(
                      height: 48,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Theme(
                      data: Theme.of(context).copyWith(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                      ),
                      child: DropdownButtonFormField<Unit>(
                        value: _selectedUnit,
                        decoration: InputDecoration(
                          hintText: _selectedBlock == null
                              ? 'Selecione primeiro o bloco'
                              : 'Selecione o apartamento',
                          hintStyle: const TextStyle(
                            color: Color(0xFF7F8C8D),
                            fontSize: 14,
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8F9FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFFE0E0E0),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF2196F3),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: _filteredUnits.map((unit) {
                          return DropdownMenuItem<Unit>(
                            value: unit,
                            child: Text(unit.apartment),
                          );
                        }).toList(),
                        onChanged:
                            _selectedBlock != null ? _onUnitChanged : null,
                        validator: (value) {
                          if (value == null) {
                            return 'Apartamento é obrigatório';
                          }
                          return null;
                        },
                      ),
                    ),

              const SizedBox(height: 20),

              // Campo Descrição da Encomenda
              const Text(
                'Descrição da Encomenda',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ex: Caixa média da Amazon',
                  hintStyle: const TextStyle(
                    color: Color(0xFF7F8C8D),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF2196F3),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Descrição é obrigatória';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              const Text(
                'Código de Rastreamento (opcional)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C3E50),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _trackingCodeController,
                decoration: InputDecoration(
                  hintText: 'Ex: BR1234567890BR',
                  hintStyle: const TextStyle(
                    color: Color(0xFF7F8C8D),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFE0E0E0),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFF2196F3),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),

              const Spacer(),

              // Botão Salvar Encomenda
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2196F3),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Salvar Encomenda',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveOrder() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedResident == null || _selectedUnit == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, selecione o morador e a unidade'),
            backgroundColor: Color(0xFFFF5722),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      final user = await StorageService.getUser();
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuário não autenticado. Faça login novamente.'),
              backgroundColor: Color(0xFFFF5722),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      try {
        // Criar dados da encomenda
        final orderData = {
          'codigo_rastreio': _trackingCodeController.text.trim().isEmpty
              ? null
              : _trackingCodeController.text.trim(),
          'descricao': _descriptionController.text.trim(),
          'id_porteiro_recebimento': user.id,
          'id_morador_destinatario': _selectedResident!.id,
        };

        // Salvar encomenda via API
        await OrdersService.createOrder(orderData);

        // Fechar loading
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Mostrar mensagem de sucesso
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Encomenda cadastrada com sucesso!'),
              backgroundColor: Color(0xFF4CAF50),
              duration: Duration(seconds: 3),
            ),
          );
        }

        // Voltar para a tela anterior após 1 segundo
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
      } catch (e) {
        // Fechar loading
        if (mounted) {
          Navigator.of(context).pop();
        }

        // Mostrar erro
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao cadastrar encomenda: ${e.toString()}'),
              backgroundColor: const Color(0xFFFF5722),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}
