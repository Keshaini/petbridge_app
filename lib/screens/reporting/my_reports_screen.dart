import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/report_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/status_pill.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  static String get _ownerUid => AuthService.currentUid;
  String _selectedTab = 'Active';
  String? _categoryFilter;

  Stream<List<ReportModel>> get _reports =>
      FirestoreService.getReportsForOwner(_ownerUid);

  void _openCreateReport() {
    context.push('/create-report');
  }

  Future<void> _resolveReport(ReportModel report) async {
    try {
      await FirestoreService.updateReport(report.reportId, {
        'status': 'Resolved',
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report marked as resolved'),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not resolve report: $error'),
        ),
      );
    }
  }

  Future<void> _showFilters() async {
    final result = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Filter reports',
                  style: AppTextStyles.heading2,
                ),
              ),
            ),
            for (final category in [
              'All',
              'Lost',
              'Found',
              'Injured',
            ])
              ListTile(
                title: Text(category),
                trailing:
                    (_categoryFilter == category ||
                            (category == 'All' &&
                                _categoryFilter == null))
                        ? const Icon(
                            Icons.check,
                            color: AppColors.primary,
                          )
                        : null,
                onTap: () => Navigator.pop(
                  context,
                  category == 'All' ? null : category,
                ),
              ),
          ],
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _categoryFilter = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<ReportModel>>(
          stream: _reports,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load reports.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyText,
                ),
              );
            }

            final reports = (snapshot.data ?? [])
                .where(
                  (report) =>
                      report.status.toLowerCase() ==
                      _selectedTab.toLowerCase(),
                )
                .where(
                  (report) =>
                      _categoryFilter == null ||
                      report.category.toLowerCase() ==
                          _categoryFilter!.toLowerCase(),
                )
                .toList();

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    22,
                    20,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Reports',
                          style: AppTextStyles.heading1,
                        ),
                        Row(
                          children: [
                            FilledButton.icon(
                              onPressed: _openCreateReport,
                              icon: const Icon(
                                Icons.add_rounded,
                                size: 18,
                              ),
                              label: const Text('Add report'),
                              style: FilledButton.styleFrom(
                                backgroundColor:
                                    AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _showFilters,
                              tooltip: 'Filter reports',
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    AppColors.cardBackground,
                                foregroundColor:
                                    AppColors.primary,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(
                                Icons.tune_rounded,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    22,
                    20,
                    4,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.accentPeach.withValues(
                          alpha: 0.45,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          'Active',
                          'Resolved',
                        ].map((tab) {
                          final selected =
                              tab == _selectedTab;

                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedTab = tab;
                                });
                              },
                              child: AnimatedContainer(
                                duration: const Duration(
                                  milliseconds: 180,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.transparent,
                                  borderRadius:
                                      BorderRadius.circular(11),
                                ),
                                child: Text(
                                  tab,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : AppColors
                                            .textSecondary,
                                    fontWeight:
                                        FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),

                if (snapshot.connectionState ==
                    ConnectionState.waiting)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (reports.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        _selectedTab == 'Active'
                            ? 'No active reports yet.'
                            : 'No resolved reports yet.',
                        style: AppTextStyles.bodyText,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      14,
                      20,
                      100,
                    ),
                    sliver: SliverList.builder(
                      itemCount: reports.length,
                      itemBuilder: (context, index) =>
                          _ReportCard(
                        report: reports[index],
                        onResolve: _resolveReport,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),

      bottomNavigationBar: _FloatingNavigationBar(
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/home');
              break;
            case 1:
              context.go('/map-search');
              break;
            case 2:
              context.go('/my-reports');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportModel report;
  final Future<void> Function(ReportModel) onResolve;

  const _ReportCard({
    required this.report,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final title = report.petName.isNotEmpty
        ? report.petName
        : '${report.category} pet report';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: report.photoUrl.isEmpty
                ? Container(
                    width: 76,
                    height: 76,
                    color: AppColors.accentPeach.withValues(
                      alpha: 0.5,
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      size: 32,
                      color: AppColors.primaryLight,
                    ),
                  )
                : Image.network(
                    report.photoUrl,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) =>
                            Container(
                      width: 76,
                      height: 76,
                      color:
                          AppColors.accentPeach.withValues(
                        alpha: 0.5,
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        size: 32,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.heading2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 7),
                StatusPill(
                  label: report.category.toUpperCase(),
                ),
                const SizedBox(height: 7),
                Text(
                  'Reported ${_formatDate(report.timestamp)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),

          if (report.status.toLowerCase() == 'active')
            OutlinedButton(
              onPressed: () => onResolve(report),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(
                  color: AppColors.primary,
                ),
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Resolve'),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')} ${_month(date.month)} ${date.year}';

  String _month(int month) => const [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ][month - 1];
}

class _FloatingNavigationBar extends StatelessWidget {
  final ValueChanged<int> onTap;

  const _FloatingNavigationBar({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        14,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 18,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              label: 'Home',
              onTap: () => onTap(0),
            ),
            _NavItem(
              icon: Icons.map_outlined,
              label: 'Map',
              onTap: () => onTap(1),
            ),
            _NavItem(
              icon: Icons.assignment_rounded,
              label: 'Reports',
              selected: true,
              onTap: () => onTap(2),
            ),
            _NavItem(
              icon: Icons.person_outline,
              label: 'Profile',
              onTap: () => onTap(3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.statusInjured
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 21,
              color: AppColors.primary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}