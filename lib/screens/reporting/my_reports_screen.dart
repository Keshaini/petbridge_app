import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../constants/app_colors.dart';
import '../../models/report_model.dart';
import '../../services/firestore_service.dart';

class MyReportsScreen extends StatelessWidget {
  const MyReportsScreen({super.key});

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'My Reports',
        style: TextStyle(fontWeight: FontWeight.w800),
      ),
      centerTitle: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: AppColors.textPrimary,
        ),
        tooltip: 'Go back',
        onPressed: () => _goBack(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context),
        body: const Center(
          child: Text('Please log in to view your reports.'),
        ),
        bottomNavigationBar: _buildBottomNav(context),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      bottomNavigationBar: _buildBottomNav(context),
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
                      onPressed: () => context.go('/my-reports'),
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
              child: CircularProgressIndicator(color: AppColors.primary),
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
              await Future<void>.delayed(const Duration(milliseconds: 300));
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
                    side: const BorderSide(color: AppColors.border),
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
                      style: const TextStyle(fontWeight: FontWeight.w700),
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
                              color: report.status.toLowerCase() == 'resolved'
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.primary,
                          ),
                          tooltip: 'Edit report',
                          onPressed: () => context
                              .push('/edit-report/${report.reportId}'),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      context.push('/report-detail/${report.reportId}');
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

  // ---------------------------------------------------------------------
  // Bottom navigation (same pattern as the Profile screen). Reports = 2.
  // ---------------------------------------------------------------------
  Widget _buildBottomNav(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navItem(
              Icons.home_outlined,
              'Home',
              false,
              () => context.go('/home'),
            ),
            _navItem(
              Icons.explore_outlined,
              'Map',
              false,
              () => context.go('/map-search'),
            ),
            _navItem(
              Icons.assignment_outlined,
              'Reports',
              true,
              () => context.go('/my-reports'),
            ),
            _navItem(
              Icons.person_outline_rounded,
              'Profile',
              false,
              () => context.go('/profile'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(
    IconData icon,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    const activeColor = Color(0xFF5A311A);
    const inactiveColor = Color(0xFF9E8E84);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: active ? 18 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFDE1CC) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                color: active ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
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