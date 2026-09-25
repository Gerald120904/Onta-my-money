import 'package:flutter_test/flutter_test.dart';
import 'package:donde_se_fue_mi_plata/core/utils/formatters.dart';

void main() {
  test('formatea montos en colones', () {
    expect(money(65000), contains('65'));
  });
}
