// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'identity_record.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IdentityRecord _$IdentityRecordFromJson(Map<String, dynamic> json) {
  return IdentityRecord(
      address: json['address'] as String,
      date: json['date'] as String,
      id: (json['id'] as num)?.toInt(),
      key: (json['key']) as String,
      value: json['value'] as String);
}

Map<String, dynamic> _$IdentityRecordToJson(IdentityRecord instance) => <String, dynamic>{
      'address': instance.address,
      'date': instance.date,
      'id': instance.id,
      'key': instance.key,
      'value': instance.value
    };
