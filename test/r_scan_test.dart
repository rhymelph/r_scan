import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:r_scan/r_scan.dart';

void main() {
  const MethodChannel channel = MethodChannel('r_scan');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {});
}
