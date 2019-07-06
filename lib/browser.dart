import 'dart:io';

import 'dart:convert' as convert;
import 'package:http/http.dart' as http;
import 'package:flutter_inappbrowser/flutter_inappbrowser.dart';
import 'package:majora/user.dart';


class Browser extends InAppBrowser {
  User kUser = new User();
  @override
  void onBrowserCreated() async {
    print("\n\nBrowser Ready!\n\n");
  }

  @override
  onLoadStart(String url) async {}

  @override
  Future onLoadStop(String url) async {
    var x = (await CookieManager.getCookie("https://chat.strims.gg", "jwt"));
    kUser.jwt = x['value'];
  }

  User getNewUser() {
    return kUser;
  }

  @override
  void onLoadError(String url, int code, String message) {
    print("\n\nCan't load $url.. Error: $message\n\n");
  }

  @override
  Future onExit() async {
    var header = new Map<String, String>();
    header['Cookie'] = 'jwt=${kUser.jwt}';
    var response =
        await http.get("https://strims.gg/api/profile", headers: header);
    if (response.statusCode == 200) {
      var jsonResponse = convert.jsonDecode(response.body);
      kUser.nick = jsonResponse['username'];
    } else {
      print("Request failed with status: ${response.statusCode}.");
    }
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