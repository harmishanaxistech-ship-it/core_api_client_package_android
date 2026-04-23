// Example repository demonstrating usage of ApiService in the data layer.
import '../sources/api_service.dart';
import '../../core/models/api_response.dart';

class ApiRepository {
  final ApiService service;

  ApiRepository(this.service);

  // Fetch a JSON list from endpoint /items
  Future<ApiResponse<List<dynamic>>> fetchItems() async {
    return service.get<List<dynamic>>('/items');
  }
}
