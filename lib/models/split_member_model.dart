import '../utils/safe_parse.dart';

class SplitMemberModel {
  const SplitMemberModel({
    required this.id,
    required this.groupId,
    required this.ownerUserId,
    required this.displayName,
    this.contactRef,
    this.linkedUserId,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String groupId;
  final String ownerUserId;
  final String displayName;
  final String? contactRef;
  final String? linkedUserId;
  final bool isActive;
  final DateTime createdAt;

  factory SplitMemberModel.fromJson(Map<String, dynamic> json) {
    return SplitMemberModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      ownerUserId: json['owner_user_id'] as String,
      displayName: (json['display_name'] as String?) ?? '',
      contactRef: json['contact_ref'] as String?,
      linkedUserId: json['linked_user_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: parseDateTimeOrDefault(json['created_at']),
    );
  }
}

