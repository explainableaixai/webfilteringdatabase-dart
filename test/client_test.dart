import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:webfilteringdatabase/webfilteringdatabase.dart';

void main() {
  test('decodes a successful response', () async {
    final mock = MockClient((request) async {
      expect(request.url.path, contains('moderate.php'));
      return http.Response('{"ok":true}', 200);
    });
    final client = WebFilteringDatabaseClient(
        apiKey: 'test', baseUrl: 'https://example.test/api', httpClient: mock);
    final result = await client.classify('example.com');
    expect(result['ok'], isTrue);
  });
}
