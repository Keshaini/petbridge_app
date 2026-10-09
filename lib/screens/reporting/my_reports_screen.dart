
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../models/report_model.dart';
import '../../services/firestore_service.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('My Reports'),
          backgroundColor: AppColors.background,
        ),
        body: const Center(
          child: Text('Please log in to view your reports.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Reports'),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: StreamBuilder<List<ReportModel>>(
        stream: FirestoreService.getReportsForOwner(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Unable to load your reports.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        // Rebuild the screen to retry the stream.
                        context.go('/my-reports');
                      },
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            );
          }

          final reports = snapshot.data ?? [];

          if (reports.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.pets_outlined,
                      size: 64,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No reports yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Reports you submit will appear here.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/create-report'),
                      icon: const Icon(Icons.add),
                      label: const Text('Create a report'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              // Firestore streams update automatically.
              await Future<void>.delayed(
                const Duration(milliseconds: 300),
              );
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final report = reports[index];

                return Card(
                  color: AppColors.cardBackground,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(
                      color: AppColors.border,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: report.photoUrl.trim().isNotEmpty
                          ? Image.network(
                              report.photoUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _reportPlaceholder(),
                            )
                          : _reportPlaceholder(),
                    ),
                    title: Text(
                      report.petName.trim().isNotEmpty
                          ? report.petName
                          : '${report.animalType} report',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            report.status,
                            style: TextStyle(
                              color: report.status.toLowerCase() ==
                                      'resolved'
                                  ? Colors.green.shade700
                                  : AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (report.locationLabel.trim().isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              report.locationLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push(
                        '/report-detail/${report.reportId}',
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _reportPlaceholder() {
    return Container(
      width: 64,
      height: 64,
      color: AppColors.accentPeach,
      alignment: Alignment.center,
      child: const Icon(
        Icons.pets,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }
}