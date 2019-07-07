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
  List<Chatter> output = [];
  for (int i = 0; i < userList.length; i++) {
    Chatter newChatter = new Chatter();
    newChatter.nick = userList[i]['nick'];
    output.add(newChatter);
  }

  // sort chatter list
  output.sort((a,b) => a.nick.compareTo(b.nick));
  return output;
}

int getConnectionCount(String input) {
  return jsonDecode(input)['connectioncount'];
}