import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reportId;
  final String ownerUid;
  final String category; // Lost, Found, Injured, Abandoned
  final String photoUrl;
  final GeoPoint location;
  final double locationRadius;
  final String description;
  final String status; // Active, Resolved
  final DateTime timestamp;
  final String? claimedBy;

  ReportModel({
    required this.reportId,
    required this.ownerUid,
    required this.category,
    required this.photoUrl,
    required this.location,
    required this.locationRadius,
    required this.description,
    required this.status,
    required this.timestamp,
    this.claimedBy,
  });

  factory ReportModel.fromMap(Map<String, dynamic> map, String id) {
    return ReportModel(
      reportId: id,
      ownerUid: map['ownerUid'] ?? '',
      category: map['category'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      location: map['location'] ?? const GeoPoint(0, 0),
      locationRadius: (map['locationRadius'] ?? 0).toDouble(),
      description: map['description'] ?? '',
      status: map['status'] ?? 'Active',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      claimedBy: map['claimedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerUid': ownerUid,
      'category': category,
      'photoUrl': photoUrl,
      'location': location,
      'locationRadius': locationRadius,
      'description': description,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'claimedBy': claimedBy,
    };
  }
}