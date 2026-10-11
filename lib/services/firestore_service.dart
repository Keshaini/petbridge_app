
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/report_model.dart';

class FirestoreService {
  static final CollectionReference<Map<String, dynamic>> _reportsRef =
      FirebaseFirestore.instance.collection('reports');

  // ---------------------------------------------------------------------------
  // CREATE: Add a new report to Firestore.
  // ---------------------------------------------------------------------------
  static Future<String> createReport(
    Map<String, dynamic> reportData,
  ) async {
    final docRef = await _reportsRef.add(reportData);
    return docRef.id;
  }

  // ---------------------------------------------------------------------------
  // READ: Get one report by its Firestore document ID.
  // ---------------------------------------------------------------------------
  static Future<ReportModel?> getReport(String reportId) async {
    final doc = await _reportsRef.doc(reportId).get();

    if (!doc.exists || doc.data() == null) {
      return null;
    }

    return ReportModel.fromMap(doc.data()!, doc.id);
  }

  // ---------------------------------------------------------------------------
  // REAL-TIME READ: Watch one report for changes.
  // Used by the shelter report-detail screen.
  // ---------------------------------------------------------------------------
  static Stream<ReportModel?> watchReport(String reportId) {
    return _reportsRef.doc(reportId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return ReportModel.fromMap(doc.data()!, doc.id);
    });
  }

  // ---------------------------------------------------------------------------
  // REAL-TIME READ: Get all active reports, newest first.
  // Used by the shelter dashboard and active report feeds.
  // ---------------------------------------------------------------------------
  static Stream<List<ReportModel>> getActiveReports() {
    return _reportsRef
        .where('status', isEqualTo: 'Active')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // ---------------------------------------------------------------------------
  // REAL-TIME READ: Get reports submitted by a particular user.
  // ---------------------------------------------------------------------------
  static Stream<List<ReportModel>> getReportsForOwner(
    String ownerUid,
  ) {
    return _reportsRef
        .where('ownerUid', isEqualTo: ownerUid)
        .snapshots()
        .map((snapshot) {
      final reports = snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data(), doc.id))
          .toList();

      reports.sort(
        (a, b) => b.timestamp.compareTo(a.timestamp),
      );

      return reports;
    });
  }

  // ---------------------------------------------------------------------------
  // UPDATE: Update selected fields in a report.
  // ---------------------------------------------------------------------------
  static Future<void> updateReport(
    String reportId,
    Map<String, dynamic> updatedFields,
  ) async {
    await _reportsRef.doc(reportId).update(updatedFields);
  }

  // ---------------------------------------------------------------------------
  // CLAIM: Assign an active report to a shelter.
  // A transaction prevents two shelters from claiming it simultaneously.
  // ---------------------------------------------------------------------------
  static Future<void> claimReport({
    required String reportId,
    required String shelterUid,
  }) async {
    if (shelterUid.isEmpty || shelterUid == 'guest') {
      throw Exception('Please log in before claiming a report.');
    }

    final docRef = _reportsRef.doc(reportId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('This report no longer exists.');
      }

      final data = snapshot.data()!;
      final status = data['status'] as String? ?? 'Active';
      final claimedBy = data['claimedBy'] as String? ?? '';

      if (status != 'Active') {
        throw Exception('This report is no longer active.');
      }

      if (claimedBy.isNotEmpty && claimedBy != shelterUid) {
        throw Exception('This report has already been claimed.');
      }

      transaction.update(docRef, {
        'claimedBy': shelterUid,
        'claimedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---------------------------------------------------------------------------
  // RELEASE: Allow the shelter that claimed a report to release it.
  // ---------------------------------------------------------------------------
  static Future<void> releaseClaim({
    required String reportId,
    required String shelterUid,
  }) async {
    if (shelterUid.isEmpty || shelterUid == 'guest') {
      throw Exception('Please log in before releasing a claim.');
    }

    final docRef = _reportsRef.doc(reportId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('This report no longer exists.');
      }

      final data = snapshot.data()!;
      final claimedBy = data['claimedBy'] as String? ?? '';

      if (claimedBy != shelterUid) {
        throw Exception(
          'Only the shelter that claimed this report can release it.',
        );
      }

      transaction.update(docRef, {
        'claimedBy': '',
        'claimedAt': FieldValue.delete(),
      });
    });
  }

  // ---------------------------------------------------------------------------
  // RESOLVE: Mark an active report as resolved.
  // Only the shelter that claimed it may resolve it.
  // ---------------------------------------------------------------------------
  static Future<void> resolveReport({
    required String reportId,
    required String shelterUid,
  }) async {
    if (shelterUid.isEmpty || shelterUid == 'guest') {
      throw Exception('Please log in before resolving a report.');
    }

    final docRef = _reportsRef.doc(reportId);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists || snapshot.data() == null) {
        throw Exception('This report no longer exists.');
      }

      final data = snapshot.data()!;
      final claimedBy = data['claimedBy'] as String? ?? '';
      final status = data['status'] as String? ?? 'Active';

      if (status != 'Active') {
        throw Exception('This report is no longer active.');
      }

      if (claimedBy != shelterUid) {
        throw Exception('Claim this report before resolving it.');
      }

      transaction.update(docRef, {
        'status': 'Resolved',
        'resolvedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---------------------------------------------------------------------------
  // DELETE: Delete a report by its document ID.
  // ---------------------------------------------------------------------------
  static Future<void> deleteReport(String reportId) async {
    await _reportsRef.doc(reportId).delete();
  }

  // ---------------------------------------------------------------------------
  // DUPLICATE CHECK: Look for a report with the same category created within
  // the previous two hours.
  // ---------------------------------------------------------------------------
  static Future<ReportModel?> checkForDuplicate(
    String category,
  ) async {
    final cutoff = DateTime.now().subtract(
      const Duration(hours: 2),
    );

    final snapshot = await _reportsRef
        .where('category', isEqualTo: category)
        .where(
          'timestamp',
          isGreaterThan: Timestamp.fromDate(cutoff),
        )
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final doc = snapshot.docs.first;

    return ReportModel.fromMap(doc.data(), doc.id);
  }
}
