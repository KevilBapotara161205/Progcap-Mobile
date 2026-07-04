class Lead {
  final String id;
  final String stage;
  final double expectedValue;
  final bool urgencyFlag;
  final bool isStuck;
  final String? notes;
  final String? anchorName;
  final String? dealerName;
  final String? dealerPhone;
  final String? dealerId;
  final String? assignedRmName;
  final DateTime? lastActivityAt;
  final DateTime? sanctionExpiryDate;
  final String nbaStatus;
  final String? nbaNotes;
  final bool kycCompleted;

  Lead({
    required this.id,
    required this.stage,
    required this.expectedValue,
    required this.urgencyFlag,
    required this.isStuck,
    this.notes,
    this.anchorName,
    this.dealerName,
    this.dealerPhone,
    this.dealerId,
    this.assignedRmName,
    this.lastActivityAt,
    this.sanctionExpiryDate,
    this.nbaStatus = 'PENDING',
    this.nbaNotes,
    this.kycCompleted = false,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    final anchor = json['anchor'];
    final dealer = json['dealer'];
    final assignedTo = json['assignedTo'];
    
    return Lead(
      id: json['_id'] ?? '',
      stage: json['stage'] ?? 'UNKNOWN',
      expectedValue: (json['expectedValue'] ?? 0).toDouble(),
      urgencyFlag: json['urgencyFlag'] ?? false,
      isStuck: json['isStuck'] ?? false,
      notes: json['notes'],
      anchorName: anchor != null && anchor is Map ? anchor['name'] : 'Unknown Anchor',
      dealerName: dealer != null && dealer is Map ? dealer['businessName'] ?? dealer['name'] : 'Unknown Dealer',
      dealerPhone: dealer != null && dealer is Map ? dealer['phone'] : null,
      dealerId: dealer != null && dealer is Map ? dealer['_id'] : null,
      assignedRmName: assignedTo != null && assignedTo is Map ? assignedTo['name'] : 'Unassigned',
      lastActivityAt: json['lastActivityAt'] != null ? DateTime.parse(json['lastActivityAt']) : null,
      sanctionExpiryDate: json['sanctionExpiryDate'] != null ? DateTime.parse(json['sanctionExpiryDate']) : null,
      nbaStatus: json['nbaStatus'] ?? 'PENDING',
      nbaNotes: json['nbaNotes'],
      kycCompleted: json['kycCompleted'] ?? false,
    );
  }
}
