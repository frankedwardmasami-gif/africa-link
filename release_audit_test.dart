import 'package:flutter_test/flutter_test.dart';
import 'package:africa_link/core/app_config.dart';

void main() {
  test('release identity and configuration contract', () {
    expect(AppConfig.appName, 'AFRICA LINK');
    expect(AppConfig.tagline, 'Connect Africa. Build Africa.');
    expect(AppConfig.supabaseUrl, isA<String>());
    expect(AppConfig.supabaseAnonKey, isA<String>());
  });
}
