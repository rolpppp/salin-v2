import 'package:freezed_annotation/freezed_annotation.dart';

part 'split_participant.freezed.dart';
part 'split_participant.g.dart';

@freezed
abstract class SplitParticipant with _$SplitParticipant {
  const factory SplitParticipant({
    required String id,
    required String splitId,
    required String contactId,
    required int shareMinor,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SplitParticipant;

  factory SplitParticipant.fromJson(Map<String, dynamic> json) => _$SplitParticipantFromJson(json);
}
