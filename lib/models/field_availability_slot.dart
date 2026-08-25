class FieldAvailabilitySlot {
  const FieldAvailabilitySlot({
    required this.date,
    required this.startsAt,
    required this.endsAt,
    required this.isAvailable,
  });

  factory FieldAvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return FieldAvailabilitySlot(
      date: json['date']?.toString() ?? '',
      startsAt: json['startsAt']?.toString() ?? '',
      endsAt: json['endsAt']?.toString() ?? '',
      isAvailable: json['isAvailable'] == true,
    );
  }

  final String date;
  final String startsAt;
  final String endsAt;
  final bool isAvailable;

  String get key => '$date|$startsAt|$endsAt';
  String get timeKey => '$startsAt|$endsAt';
}

class AvailabilityTimeRange {
  const AvailabilityTimeRange({required this.startsAt, required this.endsAt});

  final String startsAt;
  final String endsAt;

  String get key => '$startsAt|$endsAt';
}
