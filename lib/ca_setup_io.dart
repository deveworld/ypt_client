import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

/// 번들된 Mozilla CA 루트를 기본 SecurityContext에 추가.
/// Windows의 Dart(BoringSSL)는 Windows Update의 루트 자동수신을 안 해서
/// 깡통 VM에서 일부 루트가 없어 TLS가 깨진다 → 완전한 루트 셋을 동봉해 보완.
/// Linux/macOS 는 시스템 루트가 정상 동작하므로 손대지 않는다.
Future<void> setupCaCerts() async {
  if (!Platform.isWindows) return;
  try {
    final data = await rootBundle.load('assets/ca/cacert.pem');
    SecurityContext.defaultContext
        .setTrustedCertificatesBytes(data.buffer.asUint8List());
  } catch (_) {
    // 중복/파싱 오류 등은 무시 (있는 루트는 그대로 유지)
  }
}
