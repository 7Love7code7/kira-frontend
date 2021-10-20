// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity_record_verify.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IdentityRecordVerify _$IdentityRecordVerifyFromJson(Map<String, dynamic> json) {
  return IdentityRecordVerify(
    id: json['id'] as int,
    address: json['address'] as String,
    verifier: json['verifier'] as String,
    recordIds: json['recordIds'] as List<int>,
    tip: json['tip'] as String,
    lastRecordEditDate: json['lastRecordEditDate'] as String,
  );
}

Map<String, dynamic> _$IdentityRecordVerifyToJson(IdentityRecordVerify instance) => <String, dynamic>{
      'id': instance.id,
      'address': instance.address,
      'verifier': instance.verifier,
      'recordIds': instance.recordIds,
      'tip': instance.tip,
      'lastRecordEditDate': instance.lastRecordEditDate
    };
