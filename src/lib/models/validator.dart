import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:kira_auth/utils/colors.dart';

enum ValidatorStatus { UNDEFINED, ACTIVE, INACTIVE, PAUSED }

@JsonSerializable(fieldRename: FieldRename.snake)
class Validator {
  final String address;
  final String valkey;
  final String pubkey;
  final String moniker;
  final String website;
  final String social;
  final String identity;
  final double commission;
  final String status;
  final int rank;
  final int streak;
  final int mischance;
  final int top;
  bool isFavorite;

  String get getReducedAddress => address.replaceRange(10, address.length - 7, '....');

  Validator({
    this.address = "",
    this.valkey = "",
    this.pubkey = "",
    this.moniker = "",
    this.website = "",
    this.social = "",
    this.identity = "",
    this.commission = 0,
    this.status = "",
    this.top = 0,
    this.rank = 0,
    this.streak = 0,
    this.mischance = 0,
    this.isFavorite = false}) {
    assert(this.address != null ||
        this.valkey != null ||
        this.pubkey != null ||
        this.moniker != null ||
        this.status != null);
  }

  ValidatorStatus getStatus() {
    switch (status) {
      case "ACTIVE":
        return ValidatorStatus.ACTIVE;
      case "INACTIVE":
        return ValidatorStatus.INACTIVE;
      case "PAUSED":
        return ValidatorStatus.PAUSED;
      default:
        return ValidatorStatus.UNDEFINED;
    }
  }

  Color getStatusColor() {
    switch (getStatus()) {
      case ValidatorStatus.ACTIVE:
        return KiraColors.green3;
      case ValidatorStatus.INACTIVE:
        return KiraColors.kGrayColor;
      case ValidatorStatus.PAUSED:
        return KiraColors.orange3;
      default:
        return KiraColors.danger;
    }
  }

  Color getCommissionColor() {
    if (commission >= 0.75)
      return KiraColors.green3;
    if (commission >= 0.5)
      return KiraColors.orange3;
    if (commission >= 0.25)
      return KiraColors.kGrayColor;
    return KiraColors.danger;
  }

  String checkUnknownWith(String field) {
    var value = field == "website"
        ? website : field == "social"
        ? social : field == "identity"
        ? identity : "";
    return value.isEmpty ? "Unknown" : value;
  }

  static Validator fromJson(Map<String, dynamic> data) {
    return Validator(
      address: data['address'],
      valkey: data['valkey'],
      pubkey: data['pubkey'],
      moniker: data['moniker'],
      website: data['website'] ?? "",
      social: data['social'] ?? "",
      identity: data['identity'] ?? "",
      commission: double.parse(data['commission'] ?? "0"),
      status: data['status'],
      rank: data['rank'] != null ? int.parse(data['rank']) : 0,
      top: data['top'] != null ? int.parse(data['top']) : 0,
      streak: data['streak'] != null ? int.parse(data['streak']) : 0,
      mischance: data['mischance'] != null ? int.parse(data['mischance']) : 0,
    );
  }
}
