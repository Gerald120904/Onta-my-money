import 'dart:io';

Future<void> main() async {
  final webDir = Directory('build/web');
  if (!webDir.existsSync()) {
    print('Error: build/web no existe');
    exit(1);
  }

  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8090);
  print('Servidor Web estático corriendo en http://localhost:8090');

  await for (final HttpRequest request in server) {
    var path = request.uri.path;
    if (path == '/' || path.isEmpty) path = '/index.html';

    var filePath = 'build/web$path';
    var file = File(filePath);

    if (!file.existsSync()) {
      // Fallback a index.html para SPA
      filePath = 'build/web/index.html';
      file = File(filePath);
    }

    final ext = filePath.split('.').last.toLowerCase();
    final contentType = _getContentType(ext);

    request.response.headers.contentType = contentType;
    // Permisivo para ServiceWorker y OPFS WebAssembly
    request.response.headers.set('Cross-Origin-Opener-Policy', 'same-origin');
    request.response.headers.set('Cross-Origin-Embedder-Policy', 'credentialless');

    await request.response.addStream(file.openRead());
    await request.response.close();
  }
}

ContentType _getContentType(String ext) {
  switch (ext) {
    case 'html':
      return ContentType.html;
    case 'js':
      return ContentType('application', 'javascript');
    case 'json':
      return ContentType.json;
    case 'wasm':
      return ContentType('application', 'wasm');
    case 'css':
      return ContentType('text', 'css');
    case 'png':
      return ContentType('image', 'png');
    case 'svg':
      return ContentType('image', 'svg+xml');
    default:
      return ContentType.binary;
  }
}
