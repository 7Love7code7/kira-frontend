import 'package:json_annotation/json_annotation.dart';

part 'identity_record.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class IdentityRecord {
  String address;
  String date;
  int id;
  String key;
  String value;

  IdentityRecord({this.address = "", this.date = "", this.id = 0, this.key = "", this.value = ""});

  factory IdentityRecord.fromJson(Map<String, dynamic> json) => _$IdentityRecordFromJson(json);

  Map<String, dynamic> toJson() => _$IdentityRecordToJson(this);
}
