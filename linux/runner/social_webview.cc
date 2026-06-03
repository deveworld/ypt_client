#include "social_webview.h"

#include <gtk/gtk.h>
#include <webkit2/webkit2.h>
#include <string.h>

// 한 번의 OAuth 세션 상태. open() 호출당 하나.
typedef struct {
  FlMethodCall* call;   // 응답해야 할 보류 중인 open() 호출
  GtkWidget* window;
  char* scheme;         // 가로챌 리다이렉트 prefix (예: "kakaoda929...:")
  gboolean responded;
} OAuthSession;

// 정확히 한 번만 응답한다(성공=리다이렉트 URL, 취소=null).
static void session_respond(OAuthSession* s, const char* uri_or_null) {
  if (s->responded) {
    return;
  }
  s->responded = TRUE;
  g_autoptr(FlValue) result = uri_or_null != nullptr
                                  ? fl_value_new_string(uri_or_null)
                                  : fl_value_new_null();
  fl_method_call_respond_success(s->call, result, nullptr);
}

// 시그널 핸들러 안에서 창을 바로 부수면 재진입 크래시 → 다음 틱에 닫는다.
static gboolean destroy_window_idle(gpointer user_data) {
  GtkWidget* window = GTK_WIDGET(user_data);
  gtk_widget_destroy(window);
  return G_SOURCE_REMOVE;
}

// 모든 탐색을 가로채는 지점. 커스텀 스킴 리다이렉트를 에러 나기 전에 잡는다.
static gboolean on_decide_policy(WebKitWebView* web_view,
                                 WebKitPolicyDecision* decision,
                                 WebKitPolicyDecisionType type,
                                 gpointer user_data) {
  OAuthSession* s = static_cast<OAuthSession*>(user_data);
  if (type == WEBKIT_POLICY_DECISION_TYPE_NAVIGATION_ACTION ||
      type == WEBKIT_POLICY_DECISION_TYPE_NEW_WINDOW_ACTION) {
    WebKitNavigationPolicyDecision* nav =
        WEBKIT_NAVIGATION_POLICY_DECISION(decision);
    WebKitNavigationAction* action =
        webkit_navigation_policy_decision_get_navigation_action(nav);
    WebKitURIRequest* req = webkit_navigation_action_get_request(action);
    const char* uri = webkit_uri_request_get_uri(req);
    gboolean matched = FALSE;
    if (uri != nullptr) {
      // (1) 직접 커스텀 스킴:  "<scheme>://..."   (예: 카카오)
      char* direct = g_strconcat(s->scheme, "://", nullptr);
      // (2) 안드로이드 intent URL:  "intent://...;scheme=<scheme>;..."  (예: 네이버)
      char* needle = g_strconcat("scheme=", s->scheme, nullptr);
      if (g_str_has_prefix(uri, direct) ||
          (g_str_has_prefix(uri, "intent:") && strstr(uri, needle) != nullptr)) {
        matched = TRUE;
      }
      g_free(direct);
      g_free(needle);
    }
    if (matched) {
      webkit_policy_decision_ignore(decision);  // 커스텀/intent 스킴 로드 차단
      session_respond(s, uri);
      if (s->window != nullptr) {
        g_idle_add(destroy_window_idle, s->window);
      }
      return TRUE;  // 처리됨
    }
  }
  return FALSE;  // 나머지는 기본 처리(정상 로드)
}

// 창이 사라질 때(사용자 닫기 포함) — 아직 응답 안 했으면 취소(null).
static void on_window_destroy(GtkWidget* widget, gpointer user_data) {
  OAuthSession* s = static_cast<OAuthSession*>(user_data);
  session_respond(s, nullptr);
  g_object_unref(s->call);
  g_free(s->scheme);
  g_free(s);
}

static void handle_open(FlMethodCall* method_call) {
  FlValue* args = fl_method_call_get_args(method_call);
  const char* url = nullptr;
  const char* scheme = nullptr;
  if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
    FlValue* v_url = fl_value_lookup_string(args, "url");
    FlValue* v_scheme = fl_value_lookup_string(args, "scheme");
    if (v_url != nullptr && fl_value_get_type(v_url) == FL_VALUE_TYPE_STRING) {
      url = fl_value_get_string(v_url);
    }
    if (v_scheme != nullptr &&
        fl_value_get_type(v_scheme) == FL_VALUE_TYPE_STRING) {
      scheme = fl_value_get_string(v_scheme);
    }
  }
  if (url == nullptr || scheme == nullptr) {
    fl_method_call_respond_error(method_call, "bad_args",
                                 "url and scheme are required", nullptr,
                                 nullptr);
    return;
  }

  OAuthSession* s = g_new0(OAuthSession, 1);
  s->call = FL_METHOD_CALL(g_object_ref(method_call));
  s->scheme = g_strdup(scheme);
  s->responded = FALSE;

  GtkWidget* window = gtk_window_new(GTK_WINDOW_TOPLEVEL);
  s->window = window;
  gtk_window_set_title(GTK_WINDOW(window), "Login");
  gtk_window_set_default_size(GTK_WINDOW(window), 480, 720);

  WebKitWebView* webview = WEBKIT_WEB_VIEW(webkit_web_view_new());
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(webview));

  g_signal_connect(webview, "decide-policy", G_CALLBACK(on_decide_policy), s);
  g_signal_connect(window, "destroy", G_CALLBACK(on_window_destroy), s);

  webkit_web_view_load_uri(webview, url);
  gtk_widget_show_all(window);
  gtk_window_present(GTK_WINDOW(window));
}

static void method_call_cb(FlMethodChannel* channel, FlMethodCall* method_call,
                           gpointer user_data) {
  const char* method = fl_method_call_get_name(method_call);
  if (strcmp(method, "open") == 0) {
    handle_open(method_call);
  } else {
    fl_method_call_respond_not_implemented(method_call, nullptr);
  }
}

void social_webview_register(FlBinaryMessenger* messenger) {
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  FlMethodChannel* channel = fl_method_channel_new(
      messenger, "ypt/social_webview", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(channel, method_call_cb, nullptr,
                                            nullptr);
  // channel 은 앱 생명주기 동안 유지(의도적으로 unref 안 함).
}
