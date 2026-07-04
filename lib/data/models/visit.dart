class Visit {
  final String id;
  final String leadId;
  final String dealerId;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String geofenceStatus;
  final int? visitDuration;
  final String? notes;

  Visit({
    required this.id,
    required this.leadId,
    required this.dealerId,
    required this.checkInTime,
    this.checkOutTime,
    required this.geofenceStatus,
    this.visitDuration,
    this.notes,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    return Visit(
      id: json['_id'] ?? '',
      leadId: json['lead'] is Map ? json['lead']['_id'] : json['lead'] ?? '',
      dealerId: json['dealer'] is Map ? json['dealer']['_id'] : json['dealer'] ?? '',
      checkInTime: DateTime.parse(json['checkInTime']),
      checkOutTime: json['checkOutTime'] != null ? DateTime.parse(json['checkOutTime']) : null,
      geofenceStatus: json['geofenceStatus'] ?? 'UNKNOWN',
      visitDuration: json['visitDuration'],
      notes: json['notes'],
    );
  }
}
