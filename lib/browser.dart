import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class Browser extends InAppBrowser {
  CookieManager cm = CookieManager();

  @override
  void onBrowserCreated() {
    print('\n\nBrowser Ready!\n\n');
  }

  @override
  void onLoadStart(Uri? url) {}

  @override
  void onLoadStop(Uri? url) {
    print('\nloading stopped\n');
  }

  Future<Cookie?> getCookie(String name) async {
    return cm.getCookie(url: Uri.parse('https://chat.strims.gg'), name: name);
  }

  @override
  void onLoadError(Uri? url, int code, String message) {
    print("\n\nCan't load $url.. Error: $message\n\n");
  }

  @override
  void onExit() {
    print('\n\nBrowser closed!\n\n');
  }

//  @override
//  void shouldOverrideUrlLoading(String url) {
//    webViewController.loadUrl(url: url);
//  }

//  @override
//  void onLoadResource(
//      WebResourceResponse response, WebResourceRequest request) {}

  @override
  void onConsoleMessage(ConsoleMessage consoleMessage) {
    print(consoleMessage.message);
  }
}
