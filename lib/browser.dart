import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';

class Browser extends InAppBrowser {
  @override
  void onBrowserCreated() async {
    print("\n\nBrowser Ready!\n\n");
  }

  @override
  onLoadStart(String url) async {}

  @override
  Future onLoadStop(String url) async {
    print("\nloading stopped\n");
  }

  Future<Map<String, dynamic>> getCookie(String name) async {
    return await CookieManager.getCookie("https://chat.strims.gg", name);
  }

  @override
  void onLoadError(String url, int code, String message) {
    print("\n\nCan't load $url.. Error: $message\n\n");
  }

  @override
  void onExit() async {
    print("\n\nBrowser closed!\n\n");
  }

  @override
  void shouldOverrideUrlLoading(String url) {
    this.webViewController.loadUrl(url);
  }

  @override
  void onLoadResource(
      WebResourceResponse response, WebResourceRequest request) {}

  @override
  void onConsoleMessage(ConsoleMessage consoleMessage) {}
}
