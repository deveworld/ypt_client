#include "social_webview.h"

#include <windows.h>
#include <wrl.h>
#include <WebView2.h>

#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

#include <map>
#include <memory>
#include <string>

using Microsoft::WRL::Callback;
using Microsoft::WRL::ComPtr;

namespace {

std::wstring Utf8ToWide(const std::string& s) {
  if (s.empty()) return std::wstring();
  int n = MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), nullptr, 0);
  std::wstring w(n, 0);
  MultiByteToWideChar(CP_UTF8, 0, s.data(), (int)s.size(), w.data(), n);
  return w;
}

std::string WideToUtf8(const std::wstring& w) {
  if (w.empty()) return std::string();
  int n = WideCharToMultiByte(CP_UTF8, 0, w.data(), (int)w.size(), nullptr, 0,
                              nullptr, nullptr);
  std::string s(n, 0);
  WideCharToMultiByte(CP_UTF8, 0, w.data(), (int)w.size(), s.data(), n, nullptr,
                      nullptr);
  return s;
}

std::wstring UserDataFolder() {
  wchar_t temp[MAX_PATH];
  DWORD n = GetTempPathW(MAX_PATH, temp);
  std::wstring folder(temp, n);
  folder += L"ypt_client_webview2";
  CreateDirectoryW(folder.c_str(), nullptr);
  return folder;
}

// uri 가 우리 리다이렉트인지: "<scheme>://..." 또는 intent URL("intent://...;scheme=<scheme>;...")
bool MatchesRedirect(const std::wstring& uri, const std::wstring& scheme) {
  if (uri.rfind(scheme + L"://", 0) == 0) return true;
  if (uri.rfind(L"intent:", 0) == 0 &&
      uri.find(L"scheme=" + scheme) != std::wstring::npos) {
    return true;
  }
  return false;
}

// open() 한 번당 하나. 창과 WebView2 의 수명을 관리.
struct OAuthSession {
  std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result;
  std::wstring scheme;
  HWND hwnd = nullptr;
  ComPtr<ICoreWebView2Controller> controller;
  ComPtr<ICoreWebView2> webview;
  EventRegistrationToken nav_token = {};
  bool responded = false;

  void Respond(const std::wstring* uri) {
    if (responded) return;
    responded = true;
    if (uri != nullptr) {
      result->Success(flutter::EncodableValue(WideToUtf8(*uri)));
    } else {
      result->Success(flutter::EncodableValue());  // null
    }
  }
};

// hwnd → 세션 (UI 스레드 단일, 콜백도 UI 스레드라 락 불필요).
// shared_ptr 라서 보류 중인 콜백이 세션을 잡고 있으면 창이 닫혀도 안전.
std::map<HWND, std::shared_ptr<OAuthSession>> g_sessions;

LRESULT CALLBACK SocialWndProc(HWND hwnd, UINT msg, WPARAM wparam,
                               LPARAM lparam) {
  auto it = g_sessions.find(hwnd);
  std::shared_ptr<OAuthSession> session =
      (it != g_sessions.end()) ? it->second : nullptr;
  switch (msg) {
    case WM_SIZE:
      if (session && session->controller) {
        RECT bounds;
        GetClientRect(hwnd, &bounds);
        session->controller->put_Bounds(bounds);
      }
      return 0;
    case WM_CLOSE:
      DestroyWindow(hwnd);
      return 0;
    case WM_NCDESTROY:
      if (session) {
        session->Respond(nullptr);  // 아직 응답 안 했으면 취소(null)
        if (session->controller) session->controller->Close();
        g_sessions.erase(hwnd);
      }
      return 0;
  }
  return DefWindowProc(hwnd, msg, wparam, lparam);
}

void OpenOAuth(
    const std::string& url_utf8, const std::string& scheme_utf8,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  auto session = std::make_shared<OAuthSession>();
  session->result = std::move(result);
  session->scheme = Utf8ToWide(scheme_utf8);
  std::wstring url = Utf8ToWide(url_utf8);

  HINSTANCE hinst = GetModuleHandle(nullptr);
  static bool registered = false;
  const wchar_t* kClass = L"YptSocialWebview";
  if (!registered) {
    WNDCLASS wc = {};
    wc.lpfnWndProc = SocialWndProc;
    wc.hInstance = hinst;
    wc.lpszClassName = kClass;
    wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
    RegisterClass(&wc);
    registered = true;
  }

  HWND hwnd = CreateWindowEx(0, kClass, L"Login", WS_OVERLAPPEDWINDOW,
                             CW_USEDEFAULT, CW_USEDEFAULT, 500, 760, nullptr,
                             nullptr, hinst, nullptr);
  if (!hwnd) {
    session->Respond(nullptr);
    return;
  }
  session->hwnd = hwnd;
  g_sessions[hwnd] = session;
  ShowWindow(hwnd, SW_SHOW);

  std::wstring udf = UserDataFolder();
  HRESULT hr = CreateCoreWebView2EnvironmentWithOptions(
      nullptr, udf.c_str(), nullptr,
      Callback<ICoreWebView2CreateCoreWebView2EnvironmentCompletedHandler>(
          [session, url](HRESULT res,
                         ICoreWebView2Environment* env) -> HRESULT {
            if (FAILED(res) || env == nullptr) {
              if (session->hwnd) DestroyWindow(session->hwnd);
              return res;
            }
            env->CreateCoreWebView2Controller(
                session->hwnd,
                Callback<
                    ICoreWebView2CreateCoreWebView2ControllerCompletedHandler>(
                    [session, url](HRESULT res2,
                                   ICoreWebView2Controller* controller)
                        -> HRESULT {
                      if (FAILED(res2) || controller == nullptr) {
                        if (session->hwnd) DestroyWindow(session->hwnd);
                        return res2;
                      }
                      session->controller = controller;
                      RECT bounds;
                      GetClientRect(session->hwnd, &bounds);
                      controller->put_Bounds(bounds);
                      ComPtr<ICoreWebView2> webview;
                      controller->get_CoreWebView2(&webview);
                      session->webview = webview;
                      webview->add_NavigationStarting(
                          Callback<
                              ICoreWebView2NavigationStartingEventHandler>(
                              [session](
                                  ICoreWebView2* sender,
                                  ICoreWebView2NavigationStartingEventArgs* args)
                                  -> HRESULT {
                                LPWSTR uri = nullptr;
                                args->get_Uri(&uri);
                                if (uri != nullptr) {
                                  std::wstring u(uri);
                                  CoTaskMemFree(uri);
                                  if (MatchesRedirect(u, session->scheme)) {
                                    args->put_Cancel(TRUE);
                                    session->Respond(&u);
                                    if (session->hwnd) {
                                      PostMessage(session->hwnd, WM_CLOSE, 0, 0);
                                    }
                                  }
                                }
                                return S_OK;
                              })
                              .Get(),
                          &session->nav_token);
                      webview->Navigate(url.c_str());
                      return S_OK;
                    })
                    .Get());
            return S_OK;
          })
          .Get());

  if (FAILED(hr)) {
    // WebView2 런타임 미설치 등 → 창 닫고 취소
    if (session->hwnd) DestroyWindow(session->hwnd);
  }
}

}  // namespace

void SocialWebviewRegister(flutter::FlutterEngine* engine) {
  // FlutterEngine::messenger() 는 앱 래퍼(코어)에 있어 PluginRegistrar 불필요.
  auto channel =
      std::make_shared<flutter::MethodChannel<flutter::EncodableValue>>(
          engine->messenger(), "ypt/social_webview",
          &flutter::StandardMethodCodec::GetInstance());
  channel->SetMethodCallHandler(
      [channel](
          const flutter::MethodCall<flutter::EncodableValue>& call,
          std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
              result) {
        if (call.method_name() != "open") {
          result->NotImplemented();
          return;
        }
        std::string url, scheme;
        const auto* args =
            std::get_if<flutter::EncodableMap>(call.arguments());
        if (args != nullptr) {
          auto u = args->find(flutter::EncodableValue("url"));
          auto s = args->find(flutter::EncodableValue("scheme"));
          if (u != args->end()) {
            if (const auto* p = std::get_if<std::string>(&u->second)) url = *p;
          }
          if (s != args->end()) {
            if (const auto* p = std::get_if<std::string>(&s->second))
              scheme = *p;
          }
        }
        if (url.empty() || scheme.empty()) {
          result->Error("bad_args", "url and scheme are required");
          return;
        }
        OpenOAuth(url, scheme, std::move(result));
      });
}
