import 'dart:convert';

class User {
  String nick;
  String jwt;

  User({this.nick, this.jwt});
}

class Chatter {
  String nick;
  List<String> features;

  Chatter({nick, features});

  factory Chatter.fromJson(Map parsedJson) {
    return Chatter(nick: parsedJson['nick'], features: parsedJson['features']);
  }
}

List<Chatter> buildChatterList(String input) {
  List<dynamic> userList = jsonDecode(input)["users"];
  List<Chatter> output = new List<Chatter>();
  userList.forEach((val) {
    output.add(parseChatter(val));
  });
  return output;
}

int getConnectionCount(String input) {
  return jsonDecode(input)['connectioncount'];
}

Chatter parseChatter(Map val) {
  String nick = val['nick'].toString();
  List<String> features = new List<String>();
  List<dynamic> tmp = val['features'];
  tmp.forEach((val) {
    features.add(val as String);
  });
  return new Chatter(nick: nick, features: features);
}
