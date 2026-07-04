class NbaInsight {
  final String id;
  final String title;
  final String description;
  final String type; // WARNING, SUCCESS, DANGER
  final String actionText;
  final String? leadId;
  final String? dealerId;
  final String? dealerName;
  final String? stage;
  final num? expectedValue;
  final String nbaStatus;
  final String nbaNotes;
  final bool kycCompleted;

  NbaInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.actionText,
    this.leadId,
    this.dealerId,
    this.dealerName,
    this.stage,
    this.expectedValue,
    this.nbaStatus = 'PENDING',
    this.nbaNotes = '',
    this.kycCompleted = false,
  });

  factory NbaInsight.fromJson(Map<String, dynamic> json) {
    return NbaInsight(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'SUCCESS',
      actionText: json['actionText'] ?? 'Action',
      leadId: json['leadId'],
      dealerId: json['dealerId'],
      dealerName: json['dealerName'],
      stage: json['stage'],
      expectedValue: json['expectedValue'],
      nbaStatus: json['nbaStatus'] ?? 'PENDING',
      nbaNotes: json['nbaNotes'] ?? '',
      kycCompleted: json['kycCompleted'] ?? false,
    );
  }
}
