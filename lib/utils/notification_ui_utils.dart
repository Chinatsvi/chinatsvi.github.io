bool shouldShowAppealButton({
  required String? type,
  Map<String, dynamic>? data,
}) {
  final normalizedType = (type ?? '').toLowerCase();
  final dataMap = data ?? const <String, dynamic>{};
  final notificationPayload = dataMap['data'] is Map
      ? Map<String, dynamic>.from(dataMap['data'] as Map)
      : dataMap;

  final isModerationAppealType = normalizedType == 'communityviolation' ||
      normalizedType == 'content_removed' ||
      normalizedType == 'post_removed';

  final requiresActionRaw = notificationPayload['requiresAction'] ??
      dataMap['requiresAction'];
  final requiresAction = requiresActionRaw == true ||
      requiresActionRaw.toString().toLowerCase() == 'true';

  final hasPostReference =
      (notificationPayload['postId']?.toString().isNotEmpty ?? false) ||
      (notificationPayload['contentId']?.toString().isNotEmpty ?? false) ||
      (dataMap['postId']?.toString().isNotEmpty ?? false) ||
      (dataMap['contentId']?.toString().isNotEmpty ?? false);

  return isModerationAppealType && requiresAction && hasPostReference;
}
