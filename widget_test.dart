import 'package:flutter_test/flutter_test.dart';
import 'package:africa_link/core/app_config.dart';
void main(){
 test('AFRICA LINK identity is defined',(){
  expect(AppConfig.appName,'AFRICA LINK');
  expect(AppConfig.tagline,'Connect Africa. Build Africa.');
 });
}
