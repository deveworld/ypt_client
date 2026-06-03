import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

/// 소셜 로그인으로 얻어 YPT 교환(/user/social/sign-up-jwt)에 넘길 최소 정보.
/// providerId = 접두사(k/n/g/a) + 공급자 사용자ID. (RE: spec/SOCIAL_LOGIN.md)
class SocialCredential {
  final String accessToken;
  final String providerId;
  final String loginProvider; // 'Kakao' | 'Naver' | 'Google'
  final String email; // 미동의 시 ''

  const SocialCredential({
    required this.accessToken,
    required this.providerId,
    required this.loginProvider,
    this.email = '',
  });
}

class SocialAuthException implements Exception {
  final String message;
  const SocialAuthException(this.message);
  @override
  String toString() => message;
}

/// 사용자가 로그인을 완료하지 않고 시간이 지난 경우(취소/타임아웃).
class SocialAuthCancelled implements Exception {
  const SocialAuthCancelled();
}

/// 공급자 정의 — 값은 모두 YPT 공식 APK 리소스에서 추출(공개값).
class SocialProvider {
  final String name; // YPT loginProvider 값
  final String idPrefix; // providerId 접두사
  final String clientId;
  final String? clientSecret;
  final String redirectUri; // 등록된 커스텀 스킴 (authorize redirect_uri)
  final String redirectScheme; // 위 스킴의 scheme 부분 (딥링크 매칭)
  final String authorizeBase;
  final String tokenBase;
  final String meUrl;
  final Map<String, String> extraAuthParams; // 공급자별 추가 authorize 파라미터
  final bool tokenSendsRedirectUri; // 토큰 교환에 redirect_uri 포함 여부
  final bool tokenUsesGet; // 토큰 교환 메서드 (true=GET 쿼리, false=POST 폼)
  final Map<String, String> tokenExtraParams; // 토큰 교환 추가 파라미터

  const SocialProvider({
    required this.name,
    required this.idPrefix,
    required this.clientId,
    required this.redirectUri,
    required this.redirectScheme,
    required this.authorizeBase,
    required this.tokenBase,
    required this.meUrl,
    this.clientSecret,
    this.extraAuthParams = const {},
    this.tokenSendsRedirectUri = true,
    this.tokenUsesGet = false,
    this.tokenExtraParams = const {},
  });

  /// 카카오. keyHash는 안드로이드 SDK 전용이라 REST 흐름엔 불필요.
  static const kakao = SocialProvider(
    name: 'Kakao',
    idPrefix: 'k',
    clientId: 'da929e6e12cac448477e77644e3be131',
    redirectUri: 'kakaoda929e6e12cac448477e77644e3be131://oauth',
    redirectScheme: 'kakaoda929e6e12cac448477e77644e3be131',
    authorizeBase: 'https://kauth.kakao.com/oauth/authorize',
    tokenBase: 'https://kauth.kakao.com/oauth/token',
    meUrl: 'https://kapi.kakao.com/v2/user/me',
  );

  /// 네이버. RE 결과(NidOAuthQuery/NaverIdLoginSDK):
  /// redirect_uri = 패키지명, 콜백 스킴 = naver3rdpartylogin://authorize,
  /// authorize에 inapp_view/oauth_os/version 필수, 토큰 교환엔 redirect_uri 없음.
  static const naver = SocialProvider(
    name: 'Naver',
    idPrefix: 'n',
    clientId: '4pErv_GmX2TyYf5HhV4y',
    clientSecret: 'RUw5ntdTX7',
    redirectUri: 'com.pallo.passiontimerscoped', // NidOAuth callbackUrl = 패키지명
    redirectScheme: 'naver3rdpartylogin',
    authorizeBase: 'https://nid.naver.com/oauth2.0/authorize',
    tokenBase: 'https://nid.naver.com/oauth2.0/token',
    meUrl: 'https://openapi.naver.com/v1/nid/me',
    extraAuthParams: {
      'inapp_view': 'custom_tab',
      'oauth_os': 'android',
      'version': 'android-5.10.0',
      'locale': 'ko_KR',
    },
    tokenSendsRedirectUri: false,
    tokenUsesGet: true, // 네이버 토큰은 @GET("token")
    tokenExtraParams: {
      'oauth_os': 'android',
      'version': 'android-5.10.0',
      'locale': 'ko_KR',
    },
  );

  static const all = [kakao, naver];
}

/// 시스템 브라우저 + OS 딥링크로 공급자 OAuth(Authorization Code)를 수행.
/// 흐름: 기본 브라우저로 authorize 열기 → 커스텀 스킴 리다이렉트를 OS가
///       우리 앱으로 전달(app_links) → code 추출 → token → 사용자id → 자격증명.
class SocialAuth {
  final SocialProvider provider;
  final http.Client _client;

  SocialAuth(this.provider, {http.Client? client})
      : _client = client ?? http.Client();

  // 네이티브 WebKit 인터셉터(linux/runner/social_webview.cc)와 통신.
  static const MethodChannel _channel = MethodChannel('ypt/social_webview');

  Future<SocialCredential> authenticate() async {
    final state = _randomState();
    final code = await _obtainCode(state);
    final token = await _exchangeToken(code, state);
    final me = await _fetchMe(token);
    return SocialCredential(
      accessToken: token,
      providerId: '${provider.idPrefix}${me.id}',
      loginProvider: provider.name,
      email: me.email,
    );
  }

  String _authorizeUrl(String state) {
    final p = {
      'response_type': 'code',
      'client_id': provider.clientId,
      'redirect_uri': provider.redirectUri,
      'state': state,
      ...provider.extraAuthParams,
    };
    return Uri.parse(provider.authorizeBase)
        .replace(queryParameters: p)
        .toString();
  }

  /// 네이티브 WebKit 창을 열어 authorize를 띄우고, 우리 커스텀 스킴으로
  /// 가는 리다이렉트 URL을 그대로 받아 code를 추출. 사용자가 닫으면 취소.
  Future<String> _obtainCode(String state) async {
    final String? redirect = await _channel.invokeMethod<String>('open', {
      'url': _authorizeUrl(state),
      'scheme': provider.redirectScheme, // native가 <scheme>:// 와 intent 둘 다 매칭
    });
    if (redirect == null) throw const SocialAuthCancelled();
    String? code;
    String? err;
    if (redirect.startsWith('intent:')) {
      // 안드로이드 intent URL: ...;S.code=CODE;S.state=...;end (예: 네이버)
      code = RegExp(r'S\.code=([^;]+)').firstMatch(redirect)?.group(1);
      err = RegExp(r'S\.error\w*=([^;]+)').firstMatch(redirect)?.group(1);
    } else {
      final uri = Uri.parse(redirect);
      code = uri.queryParameters['code'];
      err = uri.queryParameters['error_description'] ??
          uri.queryParameters['error'];
    }
    if (code == null || code.isEmpty) {
      throw SocialAuthException(
          '${provider.name} authorization failed${err != null ? ': $err' : ''}');
    }
    return code;
  }

  Future<String> _exchangeToken(String code, String state) async {
    final params = {
      'grant_type': 'authorization_code',
      'client_id': provider.clientId,
      if (provider.tokenSendsRedirectUri) 'redirect_uri': provider.redirectUri,
      'code': code,
      'state': state,
      if (provider.clientSecret != null) 'client_secret': provider.clientSecret!,
      ...provider.tokenExtraParams,
    };
    final http.Response r;
    if (provider.tokenUsesGet) {
      r = await _client.get(
          Uri.parse(provider.tokenBase).replace(queryParameters: params));
    } else {
      r = await _client.post(
        Uri.parse(provider.tokenBase),
        headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
        body: params,
      );
    }
    if (r.statusCode != 200) {
      throw SocialAuthException(
          '${provider.name} token exchange failed (HTTP ${r.statusCode})');
    }
    final j = jsonDecode(utf8.decode(r.bodyBytes));
    final token = (j is Map) ? j['access_token']?.toString() : null;
    if (token == null || token.isEmpty) {
      throw SocialAuthException('${provider.name} did not return an access token');
    }
    return token;
  }

  Future<_ProviderUser> _fetchMe(String token) async {
    final r = await _client.get(
      Uri.parse(provider.meUrl),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (r.statusCode != 200) {
      throw SocialAuthException(
          '${provider.name} profile fetch failed (HTTP ${r.statusCode})');
    }
    final j = jsonDecode(utf8.decode(r.bodyBytes));
    return _parseMe(j);
  }

  _ProviderUser _parseMe(dynamic j) {
    if (j is! Map) throw SocialAuthException('${provider.name} profile malformed');
    switch (provider.name) {
      case 'Naver':
        final res = j['response']; // {response:{id,email,...}}
        if (res is Map) {
          return _ProviderUser(
              id: res['id']?.toString() ?? '',
              email: res['email']?.toString() ?? '');
        }
        break;
      case 'Kakao':
      default:
        final acc = j['kakao_account']; // {id, kakao_account:{email?}}
        final email = (acc is Map) ? (acc['email']?.toString() ?? '') : '';
        return _ProviderUser(id: j['id']?.toString() ?? '', email: email);
    }
    return _ProviderUser(id: j['id']?.toString() ?? '', email: '');
  }

  String _randomState() {
    final r = Random.secure();
    return List.generate(16, (_) => r.nextInt(16).toRadixString(16)).join();
  }

  void close() => _client.close();
}

class _ProviderUser {
  final String id;
  final String email;
  const _ProviderUser({required this.id, required this.email});
}
