// Tiny static server for previewing build/web: dart run tool/serve.dart
import 'dart:io';

Future<void> main() async {
  final root = Directory('build/web').absolute.path;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, int.tryParse(Platform.environment['PORT'] ?? '') ?? 8765);
  const types = {
    'html': 'text/html', 'js': 'application/javascript', 'mjs': 'application/javascript',
    'json': 'application/json', 'css': 'text/css', 'png': 'image/png', 'wasm': 'application/wasm',
    'otf': 'font/otf', 'ttf': 'font/ttf', 'ico': 'image/x-icon',
  };
  stdout.writeln('serving $root on http://localhost:8765');
  await for (final req in server) {
    var path = Uri.decodeComponent(req.uri.path);
    if (path == '/') path = '/index.html';
    var f = File('$root$path');
    if (!f.existsSync()) f = File('$root/index.html');
    final ext = f.path.split('.').last;
    req.response.headers.contentType = ContentType.parse(types[ext] ?? 'application/octet-stream');
    await req.response.addStream(f.openRead());
    await req.response.close();
  }
}
