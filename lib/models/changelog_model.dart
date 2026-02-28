/// Model for an app update entry in the changelog
class ChangelogEntry {
  final String version;
  final String date;
  final String title;
  final List<ChangeItem> changes;

  ChangelogEntry({
    required this.version,
    required this.date,
    required this.title,
    required this.changes,
  });

  factory ChangelogEntry.fromJson(Map<String, dynamic> json) {
    return ChangelogEntry(
      version: json['version'] ?? '',
      date: json['date'] ?? '',
      title: json['title'] ?? '',
      changes: (json['changes'] as List? ?? [])
          .map((i) => ChangeItem.fromJson(i))
          .toList(),
    );
  }
}

/// Model for a specific change within a version
class ChangeItem {
  final String type; // 'feature', 'fix', 'improvement'
  final String description;

  ChangeItem({required this.type, required this.description});

  factory ChangeItem.fromJson(Map<String, dynamic> json) {
    return ChangeItem(
      type: json['type'] ?? 'feature',
      description: json['description'] ?? '',
    );
  }
}
