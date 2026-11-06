# Onta My Money — frontend

Flutter Web y Android con datos locales Drift y sincronización con la API.

## API por entorno

- Desarrollo Android en emulador: `flutter run` usa `http://10.0.2.2:8080`.
- Desarrollo Web: `flutter run -d chrome` usa `http://localhost:8080`.
- Desarrollo contra otra API: pasar `--dart-define=API_URL=<url>`.
- Release Android y Web: usa exclusivamente `https://onta-my-money-api.gerald.prod.page`. Un valor distinto se rechaza; el APK release también valida el parámetro durante Gradle.

```powershell
flutter pub get
flutter analyze
flutter test
flutter build web --release --dart-define=API_URL=https://onta-my-money-api.gerald.prod.page
flutter build apk --release --dart-define=API_URL=https://onta-my-money-api.gerald.prod.page
```

No incluir tokens ni credenciales en `--dart-define`: el contenido del APK y del JavaScript Web es inspeccionable. Para firmar el APK de distribución, configurar fuera del repositorio `ONTA_ANDROID_KEYSTORE`, `ONTA_ANDROID_KEYSTORE_PASSWORD`, `ONTA_ANDROID_KEY_ALIAS` y `ONTA_ANDROID_KEY_PASSWORD`. Sin estas variables, el APK release queda sin firma de distribución; no debe publicarse. El identificador de aplicación `com.example.frontend` también debe sustituirse por el definitivo antes de publicar en una tienda.

## Recordatorios

En Android se programan notificaciones locales a las 09:00 según la zona horaria del dispositivo y las preferencias del usuario. Android solicita permiso de notificación. La hora de entrega puede variar porque se usan alarmas inexactas para evitar permisos de alarma exacta. Los avisos se actualizan o cancelan al cambiar o pagar compromisos y al cerrar sesión. Un dispositivo físico debe confirmar la entrega con la aplicación cerrada, tras reiniciar el teléfono y bajo las políticas de batería del fabricante.

En Web los avisos viven en la aplicación local; no se promete entrega con el navegador cerrado. Los datos financieros y la cola Offline-First permanecen en el dispositivo cuando falla la red.
