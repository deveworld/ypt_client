#ifndef RUNNER_SOCIAL_WEBVIEW_H_
#define RUNNER_SOCIAL_WEBVIEW_H_

#include <flutter_linux/flutter_linux.h>

// 'ypt/social_webview' 메서드 채널을 등록한다.
// Dart에서 open({url, scheme}) 호출 시 WebKitGTK 창을 띄우고,
// scheme 으로 시작하는 첫 탐색(=OAuth 커스텀 스킴 리다이렉트)을 가로채
// 그 URL 문자열로 응답한다. 사용자가 창을 닫으면 null 로 응답.
void social_webview_register(FlBinaryMessenger* messenger);

#endif  // RUNNER_SOCIAL_WEBVIEW_H_
