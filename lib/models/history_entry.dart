class HistoryEntry {
  final int id;
  final DateTime timestamp;
  final String inputType;
  final String category;
  final String urgency;
  final String summary;

  const HistoryEntry({
    required this.id,
    required this.timestamp,
    required this.inputType,
    required this.category,
    required this.urgency,
    required this.summary,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'inputType': inputType,
      'category': category,
      'urgency': urgency,
      'summary': summary,
    };
  }

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    return HistoryEntry(
      id: map['id'] as int,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      inputType: map['inputType'] as String,
      category: map['category'] as String,
      urgency: map['urgency'] as String,
      summary: map['summary'] as String,
    );
  }
}
