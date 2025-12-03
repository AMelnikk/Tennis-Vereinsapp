class TeamMemberDetail {
  final String userId; // Die UID, die der Map-Key war
  final String displayName;
  final bool active;

  TeamMemberDetail({
    required this.userId,
    required this.displayName,
    required this.active,
  });

  // Factory constructor, um die denormalisierte Map zu konvertieren
  factory TeamMemberDetail.fromDenormalizedJson(
      String userId, Map<String, dynamic> json) {
    return TeamMemberDetail(
      userId: userId,
      displayName: json['displayName'] as String? ?? '',
      // Sicherstellen, dass 'active' ein bool ist oder auf false zurückfällt
      active: json['active'] as bool? ?? false,
    );
  }

  // Für das Update in Firestore (zum Speichern)
  Map<String, dynamic> toDenormalizedJson() {
    return {
      'displayName': displayName,
      'active': active,
    };
  }
}
