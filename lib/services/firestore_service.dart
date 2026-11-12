import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/report_model.dart';

/// A possible duplicate: the existing report and why it matched.
class DuplicateMatch {
  final ReportModel report;
  final String reason;

  const DuplicateMatch({required this.report, required this.reason});
}

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
  // Sorted in Dart so no composite Firestore index is required.
  // Used by Home, the shelter dashboard and active report feeds.
  // ---------------------------------------------------------------------------
  static Stream<List<ReportModel>> getActiveReports() {
    return _reportsRef
        .where('status', isEqualTo: 'Active')
        .snapshots()
        .map((snapshot) {
      final reports = snapshot.docs
          .map((doc) => ReportModel.fromMap(doc.data(), doc.id))
          .toList();

      reports.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return reports;
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
  // DUPLICATE CHECK (FR2): compares a new report with the ACTIVE reports.
  // A match is any of:
  //   1. the same photo (identical file hash)
  //   2. the same pet name (ignoring case and spaces)
  //   3. the same category within [maxKm] and the last [window]
  // Uses a single equality filter, so no composite index is needed.
  // ---------------------------------------------------------------------------
  static Future<DuplicateMatch?> findDuplicate({
    required String category,
    required String petName,
    required String photoHash,
    required GeoPoint location,
    double maxKm = 0.5,
    Duration window = const Duration(hours: 24),
  }) async {
    final snapshot =
        await _reportsRef.where('status', isEqualTo: 'Active').get();

    final name = petName.trim().toLowerCase();
    final cutoff = DateTime.now().subtract(window);

    ReportModel? sameName;
    ReportModel? nearby;
    double nearbyKm = double.infinity;

    for (final doc in snapshot.docs) {
      final report = ReportModel.fromMap(doc.data(), doc.id);

      // 1. Same photo: the strongest signal, so return straight away.
      if (photoHash.isNotEmpty && report.photoHash == photoHash) {
        return DuplicateMatch(
          report: report,
          reason: 'The same photo is already used in an active report '
              '(${report.category}, ${_ago(report.timestamp)}).',
        );
      }

      // 2. Same pet name.
      if (sameName == null &&
          name.isNotEmpty &&
          report.petName.trim().toLowerCase() == name) {
        sameName = report;
      }

      // 3. Same category, close by, recently.
      if (report.category == category && report.timestamp.isAfter(cutoff)) {
        final km = _distanceKm(location, report.location);

        if (km <= maxKm && km < nearbyKm) {
          nearbyKm = km;
          nearby = report;
        }
      }
    }

    if (sameName != null) {
      return DuplicateMatch(
        report: sameName,
        reason: 'A report for "${sameName.petName}" is already active '
            '(${sameName.category}, ${_ago(sameName.timestamp)}).',
      );
    }

    if (nearby != null) {
      return DuplicateMatch(
        report: nearby,
        reason: 'A similar ${nearby.category} report was submitted '
            '${_ago(nearby.timestamp)}, about ${_formatKm(nearbyKm)} away.',
      );
    }

    return null;
  }

  // Older callers: category and time window only. Also index-free now.
  static Future<ReportModel?> checkForDuplicate(String category) async {
    final cutoff = DateTime.now().subtract(const Duration(hours: 2));

    final snapshot = await _reportsRef
        .where('category', isEqualTo: category)
        .where('status', isEqualTo: 'Active')
        .get();

    for (final doc in snapshot.docs) {
      final report = ReportModel.fromMap(doc.data(), doc.id);
      if (report.timestamp.isAfter(cutoff)) return report;
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------
  static double _distanceKm(GeoPoint a, GeoPoint b) {
    const earthRadiusKm = 6371.0;

    final dLat = _radians(b.latitude - a.latitude);
    final dLng = _radians(b.longitude - a.longitude);

    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(_radians(a.latitude)) *
            math.cos(_radians(b.latitude)) *
            math.pow(math.sin(dLng / 2), 2);

    return 2 * earthRadiusKm * math.asin(math.sqrt(h));
  }

  static double _radians(double degrees) => degrees * math.pi / 180;

  static String _formatKm(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  static String _ago(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.isNegative || diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  // ---------------------------------------------------------------------------
  // CHAT
  // ---------------------------------------------------------------------------

  static CollectionReference<Map<String, dynamic>> chatMessagesRef(
    String reportId,
  ) {
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(reportId)
        .collection('messages');
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> getChatMessages(
    String reportId,
  ) {
    return chatMessagesRef(reportId)
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  static Future<void> sendChatMessage({
    required String reportId,
    required String senderId,
    required String text,
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) return;

    final chatRef =
        FirebaseFirestore.instance.collection('chats').doc(reportId);

    await chatRef.set({
      'reportId': reportId,
      'lastMessage': cleanText,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await chatMessagesRef(reportId).add({
      'senderId': senderId,
      'text': cleanText,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>?> getUserProfile(
    String uid,
  ) async {
    if (uid.isEmpty || uid == 'guest') return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    return doc.data();
  }
}