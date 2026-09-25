import 'dart:io';
import 'package:webfilteringdatabase/webfilteringdatabase.dart';

Future<void> main() async {
  final client = WebFilteringDatabaseClient(
      apiKey: Platform.environment['AQ_API_KEY'] ?? '');
  try {
    print(await client.classify('example.com'));
  } finally {
    client.close();
  }
}
