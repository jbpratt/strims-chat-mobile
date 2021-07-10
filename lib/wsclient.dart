import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WSClient {
  WSClient(this.address, {this.auth = ''});

  String address;
  String auth;
  late WebSocketChannel channel;

  String get token {
    return auth;
  }

  set token(String token) {
    auth = token;
  }

  WebSocketChannel dial() {
    //print('opening channel');
    return IOWebSocketChannel.connect(address,
        headers: auth.isNotEmpty ? {'Cookie': 'jwt=$auth'} : {});
  }
}
