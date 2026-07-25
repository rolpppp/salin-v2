// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'split_participant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SplitParticipant _$SplitParticipantFromJson(Map<String, dynamic> json) =>
    _SplitParticipant(
      id: json['id'] as String,
      splitId: json['splitId'] as String,
      contactId: json['contactId'] as String,
      shareMinor: (json['shareMinor'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$SplitParticipantToJson(_SplitParticipant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'splitId': instance.splitId,
      'contactId': instance.contactId,
      'shareMinor': instance.shareMinor,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
