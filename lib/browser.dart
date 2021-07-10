import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';

class Browser extends InAppBrowser {
  CookieManager cm = CookieManager();

  @override
  void onBrowserCreated() async {
    print('\n\nBrowser Ready!\n\n');
  }

  @override
  Future<void> onLoadStart(String url) async {}

  @override
  Future onLoadStop(String url) async {
    print('\nloading stopped\n');
  }

  Future<Cookie> getCookie(String name) async {
    return await cm.getCookie(url: 'https://chat.strims.gg', name: name);
  }

  @override
  void onLoadError(String url, int code, String message) {
    print("\n\nCan't load $url.. Error: $message\n\n");
  }

  @override
  Future<void> onExit() async {
    print('\n\nBrowser closed!\n\n');
  }

  @override
  void shouldOverrideUrlLoading(String url) {
    webViewController.loadUrl(url: url);
  }

//  @override
//  void onLoadResource(
//      WebResourceResponse response, WebResourceRequest request) {}

  @override
  void onConsoleMessage(ConsoleMessage consoleMessage) {}
}
