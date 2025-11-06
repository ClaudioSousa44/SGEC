import '../models/resident.dart';
import '../models/unit.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

/// Serviço para gerenciar requisições relacionadas a moradores e unidades
class ResidentsService {
  /// Busca todos os moradores
  static Future<List<Resident>> getResidents() async {
    try {
      final token = await StorageService.getToken();

      final response = await ApiService.get(
        'moradores',
        token: token,
      );

      // Verificar se os dados estão em 'data' ou diretamente na resposta
      List<dynamic> residentsData;
      if (response.containsKey('data')) {
        if (response['data'] is List) {
          residentsData = response['data'] as List;
        } else {
          residentsData = [];
        }
      } else if (response.containsKey('moradores') &&
          response['moradores'] is List) {
        residentsData = response['moradores'] as List;
      } else {
        residentsData = [];
      }

      return residentsData
          .map((json) => Resident.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiException('Erro ao buscar moradores: ${e.toString()}');
    }
  }

  /// Busca todas as unidades (blocos e apartamentos)
  static Future<List<Unit>> getUnits() async {
    try {
      final token = await StorageService.getToken();

      final response = await ApiService.get(
        'unidades',
        token: token,
      );

      // Verificar se os dados estão em 'data' ou diretamente na resposta
      List<dynamic> unitsData;
      if (response.containsKey('data')) {
        if (response['data'] is List) {
          unitsData = response['data'] as List;
        } else {
          unitsData = [];
        }
      } else if (response.containsKey('unidades') &&
          response['unidades'] is List) {
        unitsData = response['unidades'] as List;
      } else {
        unitsData = [];
      }

      return unitsData
          .map((json) => Unit.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw ApiException('Erro ao buscar unidades: ${e.toString()}');
    }
  }

  /// Busca unidades por bloco
  static Future<List<Unit>> getUnitsByBlock(String block) async {
    try {
      final allUnits = await getUnits();
      return allUnits.where((unit) => unit.block == block).toList();
    } catch (e) {
      throw ApiException('Erro ao buscar unidades por bloco: ${e.toString()}');
    }
  }

  /// Busca moradores por unidade
  static Future<List<Resident>> getResidentsByUnit(int unitId) async {
    try {
      final allResidents = await getResidents();
      return allResidents
          .where((resident) => resident.unitId == unitId)
          .toList();
    } catch (e) {
      throw ApiException(
          'Erro ao buscar moradores por unidade: ${e.toString()}');
    }
  }
}
