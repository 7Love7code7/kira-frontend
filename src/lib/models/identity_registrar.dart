import 'package:json_annotation/json_annotation.dart';

part 'identity_registrar.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class IdentityRegistrar {
  String address;
  String date;
  int id;
  String key;
  String value;

  IdentityRegistrar({this.address = "", this.date = "", this.id = 0, this.key = "", this.value = ""});

  factory IdentityRegistrar.fromJson(Map<String, dynamic> json) => _$IdentityRegistrarFromJson(json);

  Map<String, dynamic> toJson() => _$IdentityRegistrarToJson(this);
}
