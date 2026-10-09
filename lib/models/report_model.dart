import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reportId;
  final String ownerUid;
  final String petName;
  final String category; // Lost, Found, Injured, Abandoned
  final String photoUrl;

  // New animal details
  final String animalType;
  final String breed;

  // Location details
  final GeoPoint location;
  final double locationRadius;
  final String locationLabel;

  final String description;
  final String status; // Active, Resolved
  final DateTime timestamp;
  final String? claimedBy;

  ReportModel({
    required this.reportId,
    required this.ownerUid,
    this.petName = '',
    required this.category,
    required this.photoUrl,
    this.animalType = '',
    this.breed = '',
    required this.location,
    required this.locationRadius,
    this.locationLabel = '',
    required this.description,
    required this.status,
    required this.timestamp,
    this.claimedBy,
  });

  factory ReportModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    return ReportModel(
      reportId: id,
      ownerUid: map['ownerUid'] as String? ?? '',
      petName: map['petName'] as String? ?? '',
      category: map['category'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',

      // Read the new fields safely for older reports.
      animalType: map['animalType'] as String? ?? '',
      breed: map['breed'] as String? ?? '',

      location: map['location'] is GeoPoint
          ? map['location'] as GeoPoint
          : const GeoPoint(0, 0),

      locationRadius:
          (map['locationRadius'] as num?)?.toDouble() ?? 0.0,

      locationLabel: map['locationLabel'] as String? ?? '',

      description: map['description'] as String? ?? '',
      status: map['status'] as String? ?? 'Active',

      timestamp:
          (map['timestamp'] as Timestamp?)?.toDate() ??
          DateTime.now(),

      claimedBy: map['claimedBy'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUid': ownerUid,
      'petName': petName,
      'category': category,
      'photoUrl': photoUrl,

      // Save animal details with the report.
      'animalType': animalType,
      'breed': breed,

      'location': location,
      'locationRadius': locationRadius,
      'locationLabel': locationLabel,

      'description': description,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'claimedBy': claimedBy,
    };
  }
}