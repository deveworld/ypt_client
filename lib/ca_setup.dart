import 'ca_setup_stub.dart' if (dart.library.io) 'ca_setup_io.dart' as impl;

/// 번들된 CA 루트를 신뢰 목록에 추가 (Windows TLS 루트 누락 보완). 웹=no-op.
Future<void> setupCaCerts() => impl.setupCaCerts();
