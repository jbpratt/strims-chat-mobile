import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WSClient {
  String address;
  String token;
  WebSocketChannel channel;

  WSClient(this.address, {this.token});

  void updateToken(String token) {
    this.token = token;
  }

  WebSocketChannel dial() {
    print("opening channel");
    channel = IOWebSocketChannel.connect(this.address,
        headers:
            token?.isNotEmpty == true ? {'Cookie': 'jwt=${this.token}'} : {});
    return channel;
  }
}