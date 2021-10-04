import 'package:dart_ipify/dart_ipify.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:latlong/latlong.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class P2PNode {
  final String id;
  final String ip;
  final int port;
  final int ping;
  final bool connected;
  final List<String> peers;
  LatLng position;

  P2PNode({
    this.id = "",
    this.ip = "",
    this.port = 0,
    this.ping = 0,
    this.connected = false,
    this.peers}) {
    assert(this.id != null || this.ip != null);
    getGeo();
  }

  void getGeo() async {
    var geo = await Ipify.geo('at_zAfeiHrbepaqUiAo5C6LuN033k936', ip: ip);
    position = new LatLng(geo.location.lat, geo.location.lng);
    print('>>>>>>>>> ' + id);
    print(geo.location);
  }

  static P2PNode fromJson(Map<String, dynamic> data) {
    return P2PNode(
      id: data['id'],
      ip: data['ip'],
      port: data['port'] != null ? int.parse(data['port']) : 0,
      ping: data['ping'] != null ? int.parse(data['ping']) : 0,
      connected: data['connected'],
      peers: data['peers'] ?? List.empty(),
    );
  }
}
