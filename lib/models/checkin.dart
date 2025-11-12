import 'package:uuid/uuid.dart';

class Checkin {
  final String id;
  final DateTime? nextCheckinTime;
  final DateTime? lastCompletedAt;
  final Map<String, dynamic>? responses;
  
  Checkin({
    String? id,
    this.nextCheckinTime,
    this.lastCompletedAt,
    this.responses,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // Store as milliseconds since epoch to preserve local time
      'nextCheckinTime': nextCheckinTime?.millisecondsSinceEpoch,
      'lastCompletedAt': lastCompletedAt?.millisecondsSinceEpoch,
      'responses': responses,
    };
  }

  factory Checkin.fromJson(Map<String, dynamic> json) {
    return Checkin(
      id: json['id'],
      nextCheckinTime: json['nextCheckinTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['nextCheckinTime'] is int
                ? json['nextCheckinTime']
                : int.parse(json['nextCheckinTime'].toString())
            )
          : null,
      lastCompletedAt: json['lastCompletedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['lastCompletedAt'] is int
                ? json['lastCompletedAt']
                : int.parse(json['lastCompletedAt'].toString())
            )
          : null,
      responses: json['responses'] != null
          ? Map<String, dynamic>.from(json['responses'])
          : null,
    );
  }

  Checkin copyWith({
    DateTime? nextCheckinTime,
    DateTime? lastCompletedAt,
    Map<String, dynamic>? responses,
  }) {
    return Checkin(
      id: id,
      nextCheckinTime: nextCheckinTime ?? this.nextCheckinTime,
      lastCompletedAt: lastCompletedAt ?? this.lastCompletedAt,
      responses: responses ?? this.responses,
    );
  }
}
