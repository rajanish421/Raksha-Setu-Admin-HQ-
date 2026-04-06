import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:raksha_setu_admin/features/dashboard/services/get_user_fcm_token.dart';
import 'package:raksha_setu_admin/features/dashboard/services/send_notification_services.dart';
import 'package:raksha_setu_admin/features/notification/services/notification_services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../constant/app_colors.dart';
import '../services/log_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  int _selectedTab = 2; // 0=All,1=Approved,2=Pending,3=Suspended
  String _search = '';
  int _currentPage = 0;
  static const int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text("User Management", style: text.headlineMedium),
          Row(
            children: [
              Text(
                "User Management",
                style: text.headlineMedium!.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 30,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "HQ Controlled",
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tabs
          Row(
            children: [
              _buildTab("All Users", 0),
              const SizedBox(width: 8),
              _buildTab("Approved", 1),
              const SizedBox(width: 8),
              _buildTab("Pending", 2),
              const SizedBox(width: 8),
              _buildTab("Suspended", 3),
            ],
          ),
          const SizedBox(height: 16),

          // Search
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                border: Border.all(color: Colors.white12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                  prefixIcon: Icon(Icons.search, color: Colors.white70),
                  hintText: "Search by name, phone, role, service no...",
                  hintStyle: TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                ),
                onChanged: (v) {
                  setState(() {
                    _search = v.trim().toLowerCase();
                    _currentPage = 0;
                  });
                },
              ),
            ),
          ),

          // Row(
          //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
          //   children: [
          //     Text(
          //       _tabTitle(),
          //       style: text.bodyLarge!.copyWith(
          //         fontWeight: FontWeight.w600,
          //         color: AppColors.textSecondary,
          //       ),
          //     ),
          //     SizedBox(
          //       width: 260,
          //       child: TextField(
          //         decoration: const InputDecoration(
          //           prefixIcon: Icon(Icons.search),
          //           hintText: "Search by name, phone or service no.",
          //         ),
          //         onChanged: (v) {
          //           setState(() {
          //             _search = v.trim().toLowerCase();
          //             _currentPage = 0;
          //           });
          //         },
          //       ),
          //     ),
          //   ],
          // ),
          const SizedBox(height: 16),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  );
                }

                final allDocs = snapshot.data!.docs;

                // 1) filter by tab
                List<QueryDocumentSnapshot> filtered = allDocs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final status = (data['status'] ?? '')
                      .toString()
                      .toLowerCase();
                  switch (_selectedTab) {
                    case 1:
                      return status == 'approved';
                    case 2:
                      return status == 'pending';
                    case 3:
                      return status == 'suspended';
                    default:
                      return true; // all users
                  }
                }).toList();

                // 2) search filter
                if (_search.isNotEmpty) {
                  filtered = filtered.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final name = (data['fullName'] ?? '')
                        .toString()
                        .toLowerCase();
                    final phone = (data['phone'] ?? '')
                        .toString()
                        .toLowerCase();
                    final serviceNo = (data['serviceNumber'] ?? '')
                        .toString()
                        .toLowerCase();
                    final role = (data['role'] ?? '').toString().toLowerCase();

                    return name.contains(_search) ||
                        phone.contains(_search) ||
                        serviceNo.contains(_search) ||
                        role.contains(_search);
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Text("No users found.", style: text.bodyLarge),
                  );
                }

                // 3) pagination
                final totalPages = (filtered.length / _pageSize).ceil().clamp(
                  1,
                  9999,
                );
                if (_currentPage >= totalPages) {
                  _currentPage = totalPages - 1;
                }
                final startIndex = _currentPage * _pageSize;
                final endIndex = (startIndex + _pageSize) > filtered.length
                    ? filtered.length
                    : (startIndex + _pageSize);
                final pageDocs = filtered.sublist(startIndex, endIndex);

                final showRequestDate = _selectedTab == 2;

                return Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingTextStyle: text.bodyLarge!.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          dataTextStyle: text.bodyMedium!.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          columns: [
                            const DataColumn(label: Text("Name")),
                            const DataColumn(label: Text("Role")),
                            const DataColumn(label: Text("Service No")),
                            const DataColumn(label: Text("Phone")),
                            const DataColumn(label: Text("Status")),
                            if (showRequestDate)
                              const DataColumn(label: Text("Request Date")),
                            const DataColumn(label: Text("Actions")),
                          ],
                          rows: pageDocs.map((d) {
                            final data =
                                d.data() as Map<String, dynamic>? ?? {};
                            final status = (data['status'] ?? '')
                                .toString()
                                .toLowerCase();

                            final cells = <DataCell>[
                              DataCell(Text(data['fullName'] ?? '-')),
                              DataCell(Text(data['role'] ?? '-')),
                              DataCell(Text(data['serviceNumber'] ?? '-')),
                              DataCell(Text(data['phone'] ?? '-')),
                              DataCell(
                                Text(
                                  status.isEmpty
                                      ? '-'
                                      : status[0].toUpperCase() +
                                            status.substring(1),
                                ),
                              ),
                            ];

                            if (showRequestDate) {
                              cells.add(
                                DataCell(
                                  Text(_formatCreatedAt(data['createdAt'])),
                                ),
                              );
                            }

                            cells.add(
                              DataCell(
                                Row(
                                  children: _actionButtons(context, d, status),
                                ),
                              ),
                            );

                            return DataRow(cells: cells);
                          }).toList(),
                          dataRowColor: WidgetStateProperty.resolveWith<Color?>(
                            (states) => states.contains(WidgetState.hovered)
                                ? Colors.white.withOpacity(0.05)
                                : null,
                          ),
                        ),
                      ),
                    ),

                    // Pagination controls
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "Page ${_currentPage + 1} of $totalPages",
                          style: text.bodyMedium,
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: _currentPage > 0
                              ? () => setState(() => _currentPage--)
                              : null,
                          icon: const Icon(Icons.chevron_left),
                        ),
                        IconButton(
                          onPressed: _currentPage < totalPages - 1
                              ? () => setState(() => _currentPage++)
                              : null,
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------- UI helpers ----------

  // Widget _buildTab(String label, int index) {
  //   final selected = _selectedTab == index;
  //   return GestureDetector(
  //     onTap: () {
  //       setState(() {
  //         _selectedTab = index;
  //         _currentPage = 0;
  //       });
  //     },
  //     child: Container(
  //       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  //       decoration: BoxDecoration(
  //         color: selected ? AppColors.primary : AppColors.surfaceLight,
  //         borderRadius: BorderRadius.circular(20),
  //         border: Border.all(
  //           color: selected
  //               ? AppColors.accent
  //               : AppColors.textSecondary.withOpacity(0.4),
  //         ),
  //       ),
  //       child: Text(
  //         label,
  //         style: TextStyle(
  //           color: selected ? AppColors.textPrimary : AppColors.textSecondary,
  //           fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
  //         ),
  //       ),
  //     ),
  //   );
  // }

  Widget _buildTab(String label, int index) {
    final selected = _selectedTab == index;
    final icons = [
      Icons.people,
      Icons.verified,
      Icons.pending_actions,
      Icons.block,
    ];
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = index;
          _currentPage = 0;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? AppColors.accent : Colors.grey.withOpacity(0.4),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.4),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Icon(
              icons[index],
              size: 18,
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _tabTitle() {
    switch (_selectedTab) {
      case 0:
        return "All registered users";
      case 1:
        return "Approved users";
      case 2:
        return "Users awaiting approval";
      case 3:
        return "Suspended users";
      default:
        return "";
    }
  }

  String _formatCreatedAt(dynamic value) {
    if (value == null) return "-";
    try {
      if (value is Timestamp) {
        return value.toDate().toString().substring(0, 10);
      }
      return DateTime.parse(value.toString()).toString().substring(0, 10);
    } catch (_) {
      return "-";
    }
  }

  // ---------- Actions ----------

  // ---------- Actions ----------

  List<Widget> _actionButtons(
    BuildContext context,
    QueryDocumentSnapshot doc,
    String status,
  ) {
    final List<Widget> widgets = [];
    final data = doc.data() as Map<String, dynamic>;

    final String fullName = data["fullName"];
    final String uid = doc.id;
    final token = data["fcmToken"];

    // View button – always
    widgets.add(
      TextButton(
        onPressed: () => _showUserModal(context, data),
        child: const Text("View"),
      ),
    );

    // Add spacing helper
    void addGap() => widgets.add(const SizedBox(width: 8));

    // Pending → Approve / Reject
    if (_selectedTab == 2 || status == 'pending') {
      addGap();
      widgets.add(
        TextButton(
          onPressed: () => _updateStatus(
            uid,
            'approved',
            context,
            token,
            'User approved',
            logAction: "approve_user",
            fullName: fullName,
          ),
          child: const Text("Approve"),
        ),
      );

      addGap();
      widgets.add(
        TextButton(
          onPressed: () => _updateStatus(
            uid,
            'rejected',
            context,
            token,
            'User rejected',
            logAction: "reject_user",
            fullName: fullName,
          ),
          child: const Text("Reject"),
        ),
      );
    }
    // Approved → Suspend
    else if (_selectedTab == 1 || status == 'approved') {
      addGap();
      widgets.add(
        TextButton(
          onPressed: () => _updateStatus(
            uid,
            'suspended',
            context,
            token,
            'User suspended',
            logAction: "suspend_user",
            fullName: fullName,
          ),
          child: const Text("Suspend"),
        ),
      );
    }
    // Suspended → Reinstate
    else if (_selectedTab == 3 || status == 'suspended') {
      addGap();
      widgets.add(
        TextButton(
          onPressed: () => _updateStatus(
            uid,
            'approved',
            context,
            token,
            'User reinstated',
            logAction: "reinstate_user",
            fullName: fullName,
          ),
          child: const Text("Reinstate"),
        ),
      );
    }

    return widgets;
  }

  // ---------- Update Status + LogService ----------
  Future<void> _updateStatus(
    String uid,
    String newStatus,
    BuildContext context,
    String token,
    String msg, {
    required String logAction,
    required String fullName,
  }) async {
    NotificationService notificationService = NotificationService();

    // 1. Update status
    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'status': newStatus,
    });

    // 2. Log the admin action
    await LogService.logAdminAction(
      action: logAction,
      targetUid: uid,
      targetName: fullName,
    );

    // send notification to the User
    // final token =
    SendNotificationServices.sendUserChangeStatusNotification(
      token: token,
      title: 'User Status',
      body: msg,
      data: null,
    );

    // 3. Show snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  // List<Widget> _actionButtons(
  //     BuildContext context,
  //     QueryDocumentSnapshot doc,
  //     String status,
  //     ) {
  //   final List<Widget> widgets = [];
  //   final data = doc.data() as Map<String, dynamic>;
  //
  //   // View button – always
  //   widgets.add(
  //     TextButton(
  //       onPressed: () => _showUserModal(context, data),
  //       child: const Text("View"),
  //     ),
  //   );
  //
  //   // Add spacing between buttons
  //   void addGap() => widgets.add(const SizedBox(width: 8));
  //
  //   // Determine actions by tab & status
  //   if (_selectedTab == 2 || status == 'pending') {
  //     // Pending: Approve / Reject
  //     addGap();
  //     widgets.add(
  //       TextButton(
  //         onPressed: () =>
  //             _updateStatus(doc.id, 'approved', context, 'User approved'),
  //         child: const Text("Approve"),
  //       ),
  //     );
  //     addGap();
  //     widgets.add(
  //       TextButton(
  //         onPressed: () =>
  //             _updateStatus(doc.id, 'rejected', context, 'User rejected'),
  //         child: const Text("Reject"),
  //       ),
  //     );
  //   } else if (_selectedTab == 1 || status == 'approved') {
  //     // Approved: Suspend
  //     addGap();
  //     widgets.add(
  //       TextButton(
  //         onPressed: () =>
  //             _updateStatus(doc.id, 'suspended', context, 'User suspended'),
  //         child: const Text("Suspend"),
  //       ),
  //     );
  //   } else if (_selectedTab == 3 || status == 'suspended') {
  //     // Suspended: Reinstate
  //     addGap();
  //     widgets.add(
  //       TextButton(
  //         onPressed: () =>
  //             _updateStatus(doc.id, 'approved', context, 'User reinstated'),
  //         child: const Text("Reinstate"),
  //       ),
  //     );
  //   }
  //
  //   return widgets;
  // }
  //
  // Future<void> _updateStatus(
  //     String uid, String newStatus, BuildContext context, String msg) async {
  //   await FirebaseFirestore.instance
  //       .collection('users')
  //       .doc(uid)
  //       .update({'status': newStatus});
  //
  //   if (mounted) {
  //     ScaffoldMessenger.of(context)
  //         .showSnackBar(SnackBar(content: Text(msg)));
  //   }
  // }

  // ---------- Modal ----------

  void _showUserModal(BuildContext context, Map<String, dynamic> data) {
    final text = Theme.of(context).textTheme;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: AppColors.surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 780,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("User Details", style: text.headlineSmall),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      // Selfie
                      Expanded(
                        child: Column(
                          children: [
                            const Text("Selfie"),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: data['selfieUrl'] != null
                                  ? Image.network(
                                      data['selfieUrl'],
                                      height: 180,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 180,
                                      color: AppColors.surface,
                                      child: const Center(
                                        child: Text("No selfie"),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 22),

                      // ID Proof
                      Expanded(
                        child: Column(
                          children: [
                            const Text("ID Proof"),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                final url = data['documentUrl'];
                                if (url == null) return;
                                final uri = Uri.parse(url);
                                if (await canLaunchUrl(uri)) {
                                  await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  );
                                }
                              },
                              child: Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.accent),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.picture_as_pdf,
                                    size: 60,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  _infoRow("Full Name", data['fullName']),
                  _infoRow("Role", data['role']),
                  _infoRow("Service Number", data['serviceNumber']),
                  _infoRow("Unit", data['unit']),
                  _infoRow("Rank", data['rank']),
                  _infoRow("Phone", data['phone']),
                  _infoRow("Relationship", data['relationship']),
                  _infoRow(
                    "Reference Service No",
                    data['referenceServiceNumber'],
                  ),
                  _infoRow("Status", data['status']),
                  _infoRow("Created At", _formatCreatedAt(data['createdAt'])),

                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Close"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 180, child: Text("$label:")),
          Expanded(
            child: Text(
              value?.toString().isEmpty ?? true ? "-" : value.toString(),
            ),
          ),
        ],
      ),
    );
  }
}
