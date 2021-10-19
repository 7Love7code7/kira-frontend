import 'package:json_annotation/json_annotation.dart';

part 'identity_record_verify.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class IdentityRecordVerify {
  int id;
  String address;
  String verifier;
  List<int> recordIds;
  String tip;
  String lastRecordEditDate;

  IdentityRecordVerify(
      {this.id = 0,
      this.address = "",
      this.verifier = "",
      this.recordIds = null,
      this.tip = "",
      this.lastRecordEditDate = ""});

  factory IdentityRecordVerify.fromJson(Map<String, dynamic> json) => _$IdentityRecordVerifyFromJson(json);

  Map<String, dynamic> toJson() => _$IdentityRecordVerifyToJson(this);
}
