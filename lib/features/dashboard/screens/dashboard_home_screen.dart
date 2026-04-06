import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../../constant/app_colors.dart';

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("HQ Overview",  style: text.headlineMedium!.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: AppColors.primary.withOpacity(0.4),
                blurRadius: 10,
              ),
            ],
          ),),
          const SizedBox(height: 24),

          // Metric cards
          FutureBuilder(
            future: _getCounts(),
            builder: (_, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent));
              }

              final c = snapshot.data!;
              return Row(
                children: [
                  _metricCard("Total Users", c['total']!, Icons.people),
                  _metricCard("Pending", c['pending']!, Icons.pending_actions,
                      color: AppColors.accent),
                  _metricCard("Approved", c['approved']!, Icons.verified_user,
                      color: AppColors.success),
                  _metricCard("Suspended", c['suspended']!, Icons.block,
                      color: AppColors.danger),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Text(
                "Select an operation from the left panel",
                style: text.bodyMedium!.copyWith(
                  color: AppColors.textSecondary.withOpacity(0.7),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _metricCard(String label, int value, IconData icon,
      {Color color = AppColors.accent}) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                AppColors.surface.withOpacity(0.92),
                AppColors.surfaceLight.withOpacity(0.92),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.18),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: color.withOpacity(0.55), width: 1.2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 60,
                height: 2,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.75),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Future<Map<String, int>> _getCounts() async {
    final snapshot = await FirebaseFirestore.instance.collection('users').get();
    int total = snapshot.docs.length;
    int pending = 0, approved = 0, suspended = 0;

    for (var d in snapshot.docs) {
      final status = d['status'] ?? 'pending';
      if (status == 'pending') pending++;
      if (status == 'approved') approved++;
      if (status == 'suspended') suspended++;
    }

    return {
      'total': total,
      'pending': pending,
      'approved': approved,
      'suspended': suspended,
    };
  }
}
