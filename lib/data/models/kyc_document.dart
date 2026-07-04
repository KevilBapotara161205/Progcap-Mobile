class KycDocument {
  final String id;
  final String leadId;
  final String docType;
  final String status;
  final String? s3Url;
  final String? verificationNotes;

  KycDocument({
    required this.id,
    required this.leadId,
    required this.docType,
    required this.status,
    this.s3Url,
    this.verificationNotes,
  });

  factory KycDocument.fromJson(Map<String, dynamic> json) {
    return KycDocument(
      id: json['_id'] ?? '',
      leadId: json['lead'] ?? '',
      docType: json['docType'] ?? 'UNKNOWN',
      status: json['status'] ?? 'PENDING',
      s3Url: json['s3Url'],
      verificationNotes: json['verificationNotes'],
    );
  }
}
