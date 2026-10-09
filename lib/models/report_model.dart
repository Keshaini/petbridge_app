import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reportId;
  final String ownerUid;
  final String petName;
  final String category;
  final String animalType;
  final String photoUrl;
  final GeoPoint location;
  final String locationLabel;
  final double locationRadius;
  final String description;
  final String status;
  final DateTime timestamp;
  final String claimedBy;

  const ReportModel({
    required this.reportId,
    required this.ownerUid,
    this.petName = '',
    required this.category,
    this.animalType = '',
    required this.photoUrl,
    required this.location,
    this.locationLabel = '',
    required this.locationRadius,
    required this.description,
    required this.status,
    required this.timestamp,
    this.claimedBy = '',
  });

  factory ReportModel.fromMap(
    Map<String, dynamic> map,
    String documentId,
  ) {
    final rawLocation = map['location'];

    return ReportModel(
      reportId: documentId,
      ownerUid: map['ownerUid'] as String? ?? '',
      petName: map['petName'] as String? ?? '',
      category: map['category'] as String? ?? '',
      animalType: map['animalType'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      location: rawLocation is GeoPoint
          ? rawLocation
          : const GeoPoint(6.8649, 79.8997),
      locationLabel: map['locationLabel'] as String? ?? '',
      locationRadius: (map['locationRadius'] as num?)?.toDouble() ?? 0.5,
      description: map['description'] as String? ?? '',
      status: map['status'] as String? ?? 'Active',
      timestamp: map['timestamp'] is Timestamp
          ? (map['timestamp'] as Timestamp).toDate()
          : map['timestamp'] is DateTime
              ? map['timestamp'] as DateTime
              : DateTime.now(),
      claimedBy: map['claimedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUid': ownerUid,
      'petName': petName,
      'category': category,
      'animalType': animalType,
      'photoUrl': photoUrl,
      'location': location,
      'locationLabel': locationLabel,
      'locationRadius': locationRadius,
      'description': description,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'claimedBy': claimedBy,
    };
  }
}