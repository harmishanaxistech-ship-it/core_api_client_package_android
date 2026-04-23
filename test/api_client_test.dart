import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:core_api_client_package/core/network/api_client.dart';
import 'package:core_api_client_package/data/sources/api_service.dart';
import 'package:core_api_client_package/data/repositories/api_repository.dart';
import 'package:core_api_client_package/core/models/api_response.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  setUpAll(() {
    // Register fallback values for commonly used param types if needed
    registerFallbackValue([]);
    registerFallbackValue({});
  });

  test('ApiRepository.fetchItems returns list on success', () async {
    final mock = MockApiClient();

    when(() => mock.get<List<dynamic>>(
          '/items',
          queryParameters: any(named: 'queryParameters'),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => ApiResponse.success([{'id': 1, 'name': 'Item1'}]));

    final service = ApiService(client: mock);
    final repo = ApiRepository(service);

    final res = await repo.fetchItems();

    expect(res.success, isTrue);
    expect(res.data, isNotNull);
    expect(res.data!.length, 1);
  });

  test('ApiService.get returns failure when client fails', () async {
    final mock = MockApiClient();

    when(() => mock.get<List<dynamic>>(
          '/items',
          queryParameters: any(named: 'queryParameters'),
          headers: any(named: 'headers'),
        )).thenAnswer((_) async => ApiResponse.failure(Exception('network error')));

    final service = ApiService(client: mock);
    final res = await service.get<List<dynamic>>('/items');

    expect(res.success, isFalse);
    expect(res.error, isNotNull);
  });
}
