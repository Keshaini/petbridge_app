import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';

class FirestoreService {
  static final CollectionReference _reportsRef =
      FirebaseFirestore.instance.collection('reports');

  // CREATE
  static Future<String> createReport(Map<String, dynamic> reportData) async {
    final docRef = await _reportsRef.add(reportData);
    return docRef.id;
  }

  // READ — single report
  static Future<ReportModel?> getReport(String reportId) async {
    final doc = await _reportsRef.doc(reportId).get();
    if (!doc.exists) return null;
    return ReportModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  // READ — all active reports (for Home/Map feed)
  static Stream<List<ReportModel>> getActiveReports() {
    return _reportsRef.where('status', isEqualTo: 'Active').snapshots().map((
      snapshot,
    ) {
      final reports = snapshot.docs
          .map(
            (doc) =>
                ReportModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
      reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return reports;
    });
  }

  static Stream<List<ReportModel>> getReportsForOwner(String ownerUid) {
    return _reportsRef
        .where('ownerUid', isEqualTo: ownerUid)
        .snapshots()
        .map((snapshot) {
      final reports = snapshot.docs
          .map((doc) =>
              ReportModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return reports;
    });
  }

  // UPDATE — e.g. mark as resolved, or edit fields
  static Future<void> updateReport(
      String reportId, Map<String, dynamic> updatedFields) async {
    await _reportsRef.doc(reportId).update(updatedFields);
  }

  // DELETE
  static Future<void> deleteReport(String reportId) async {
    await _reportsRef.doc(reportId).delete();
  }

  // Duplicate check — simple version: look for same category within a time window
  static Future<ReportModel?> checkForDuplicate(String category) async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 2));
    final snapshot = await _reportsRef
        .where('category', isEqualTo: category)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(cutoff))
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return ReportModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}
