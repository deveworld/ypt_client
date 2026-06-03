import Cocoa
import FlutterMacOS
import WebKit

class MainFlutterWindow: NSWindow {
  private var socialWebview: SocialWebview?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // 소셜 로그인 인터셉터 채널 (Linux/Windows 와 동일한 'ypt/social_webview')
    let social = SocialWebview()
    self.socialWebview = social
    let channel = FlutterMethodChannel(
      name: "ypt/social_webview",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { call, result in
      if call.method == "open",
        let args = call.arguments as? [String: Any],
        let url = args["url"] as? String,
        let scheme = args["scheme"] as? String
      {
        social.open(url: url, scheme: scheme, result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}

/// WKWebView로 공급자 authorize를 띄우고, 커스텀 스킴(`<scheme>://`) 또는
/// 안드로이드 intent(`intent://...;scheme=<scheme>;...`) 리다이렉트를
/// 로드 전에 가로채 그 URL로 응답한다. 사용자가 창을 닫으면 nil.
class SocialWebview: NSObject, WKNavigationDelegate, NSWindowDelegate {
  private var result: FlutterResult?
  private var window: NSWindow?
  private var scheme: String = ""
  private var responded = false

  func open(url: String, scheme: String, result: @escaping FlutterResult) {
    self.result = result
    self.scheme = scheme
    self.responded = false

    let webView = WKWebView(
      frame: NSRect(x: 0, y: 0, width: 480, height: 720),
      configuration: WKWebViewConfiguration())
    webView.navigationDelegate = self

    let win = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 480, height: 720),
      styleMask: [.titled, .closable],
      backing: .buffered, defer: false)
    win.title = "Login"
    win.contentView = webView
    win.center()
    win.isReleasedWhenClosed = false
    win.delegate = self
    self.window = win
    win.makeKeyAndOrderFront(nil)
    NSApp.activate(ignoringOtherApps: true)

    if let u = URL(string: url) {
      webView.load(URLRequest(url: u))
    } else {
      respond(nil)
      closeWindow()
    }
  }

  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    let urlStr = navigationAction.request.url?.absoluteString ?? ""
    if urlStr.hasPrefix("\(scheme)://")
      || (urlStr.hasPrefix("intent:") && urlStr.contains("scheme=\(scheme)"))
    {
      decisionHandler(.cancel)
      respond(urlStr)
      closeWindow()
    } else {
      decisionHandler(.allow)
    }
  }

  func windowWillClose(_ notification: Notification) {
    respond(nil)  // 사용자가 닫음(취소)
    window = nil
  }

  private func respond(_ value: String?) {
    if responded { return }
    responded = true
    result?(value)
    result = nil
  }

  private func closeWindow() {
    let w = window
    window = nil
    w?.delegate = nil  // windowWillClose 재진입 방지
    w?.close()
  }
}
