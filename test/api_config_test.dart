import 'package:flutter_test/flutter_test.dart';
import 'package:donde_se_fue_mi_plata/core/api/api_client.dart';

void main() {
  test('Release Android y Web usan solo HTTPS de producción', () {
    for (final isWeb in [true, false]) {
      expect(
        ApiConfig.resolveBaseUrl(
          isRelease: true, isWeb: isWeb, isAndroid: !isWeb,
          configuredUrl: '',
        ),
        isWeb ? '' : ApiConfig.productionUrl,
      );
      for (final invalid in [
        'http://localhost:8080',
        'http://10.0.2.2:8080',
        'https://onta-my-money-api.gerald.blitz.cloud',
      ]) {
        expect(() => ApiConfig.resolveBaseUrl(
          isRelease: true, isWeb: isWeb, isAndroid: !isWeb,
          configuredUrl: invalid,
        ), throwsStateError);
      }
    }
  });

  test('Desarrollo conserva endpoints locales explícitos', () {
    expect(ApiConfig.resolveBaseUrl(
      isRelease: false, isWeb: false, isAndroid: true,
      configuredUrl: '',
    ), 'http://10.0.2.2:8080');
    expect(ApiConfig.resolveBaseUrl(
      isRelease: false, isWeb: true, isAndroid: false,
      configuredUrl: '',
    ), 'http://localhost:8080');
  });
}
