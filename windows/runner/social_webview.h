#ifndef RUNNER_SOCIAL_WEBVIEW_H_
#define RUNNER_SOCIAL_WEBVIEW_H_

#include <flutter/flutter_engine.h>

// 'ypt/social_webview' 메서드 채널을 등록한다.
// open({url, scheme}) 호출 시 WebView2 창을 띄우고, scheme 으로 시작하는
// 커스텀 스킴 또는 안드로이드 intent(`intent://...;scheme=<scheme>;...`)
// 리다이렉트를 가로채 그 URL 문자열로 응답한다. 창을 닫으면 null.
void SocialWebviewRegister(flutter::FlutterEngine* engine);

#endif  // RUNNER_SOCIAL_WEBVIEW_H_
